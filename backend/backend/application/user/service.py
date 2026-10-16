import logging

from fastapi import HTTPException, UploadFile
from supabase import Client

from user.schema import UserRegistrationReq,SharedProfileResponse,SharedProfileReq,UserDocumentResponse,\
    FarmerProfileResponse,FarmerProfileReq,InvestorProfileReq,InvestorProfileResponse,UserLoginReq,UserCredResponse,UserFullNameResponse,UserMeResponse,UserRole
from user.utils import validate_file_size

logger = logging.getLogger(__name__)


def _to_http_exception(e: Exception, action: str) -> HTTPException:
    """Convert any exception into an HTTPException.

    - HTTPException is returned as-is.
    - Errors from Supabase (auth / postgrest) that carry an HTTP status and code
      keep that status and code.
    - Anything else becomes a generic 500 and is logged, so the cause is not lost.
    """
    if isinstance(e, HTTPException):
        return e

    logger.exception("Failed to %s", action)

    status = getattr(e, "status", None)
    code = getattr(e, "code", None)
    if isinstance(status, int) and 400 <= status <= 599 and code:
        return HTTPException(status_code=status, detail=code)

    return HTTPException(status_code=500, detail="something went wrong")


async def register_user(user_data:UserRegistrationReq,supabase:Client)->UserCredResponse:
    try:
        response = supabase.auth.sign_up(
            {
                "email": user_data.email,
                "password":user_data.password,
                "options": {"data": {"phone": user_data.phone}},
            }
        )
        user= response.user
        session= response.session
        if user is None or session is None:
            raise HTTPException(status_code=500, detail="Failed to create session")

        try:
            supabase.postgrest.auth(session.access_token)
            supabase.table("phone").insert({
                "id": str(user.id),
                "phone_number": user_data.phone,
            }).execute()
        except Exception:
            # Avoid leaving a user in auth.users without a phone record
            logger.exception("Failed to insert phone for user %s", user.id)
            try:
                supabase.auth.admin.delete_user(str(user.id))
            except Exception:
                logger.exception("Failed to roll back user %s", user.id)
            raise

        cred_res = UserCredResponse(
            id=user.id,
            email=user.email,
            created_at=user.created_at,
            access_token=session.access_token,
            refresh_token=session.refresh_token,
            expires_in=session.expires_in,
        )
        return cred_res

    except Exception as e:
        raise _to_http_exception(e, "register user")


async def login_user(user_data:UserLoginReq,supabase:Client)->UserCredResponse:
    try:
        response = supabase.auth.sign_in_with_password(
                {
                    "email": user_data.email,
                    "password":user_data.password,
                }
            )
        user= response.user
        session= response.session
        if user is None or session is None:
            raise HTTPException(status_code=500, detail="Failed to create session")

        cred_res = UserCredResponse(
                        id=user.id,
                        email=user.email,
                        created_at=user.created_at,
                        access_token=session.access_token,
                        refresh_token=session.refresh_token,
                        expires_in=session.expires_in,
                    )
        return cred_res
    except Exception as e:
        raise _to_http_exception(e, "login user")

async def create_shared_profile(user_id:str,user_profile:SharedProfileReq,supabase:Client)->SharedProfileResponse:
    try:
        profile_res = supabase.table("shared_profile").insert({
                            "id": user_id,
                            "full_name": user_profile.full_name,
                            "date_of_birth": user_profile.date_of_birth.isoformat(),
                            "sex": user_profile.sex,
                            "NIK":user_profile.nik
                            }).execute()
        profile_res = profile_res.data[0]
        response = SharedProfileResponse(
            id= profile_res["id"],
            full_name=profile_res["full_name"],
            date_of_birth= profile_res["date_of_birth"],
            sex= profile_res["sex"],
            nik=profile_res["NIK"],
        )

        return response
    except Exception as e:
        raise _to_http_exception(e, "create shared profile")


async def get_full_name(user_id:str,supabase:Client)->UserFullNameResponse:
    try:
        res = supabase.table("shared_profile").select("full_name").eq("id", user_id).limit(1).execute()
        if not res.data:
            raise HTTPException(status_code=404, detail="Profile not found")

        return UserFullNameResponse(full_name=res.data[0]["full_name"])
    except Exception as e:
        raise _to_http_exception(e, "get full name")


async def get_me(user_id:str,supabase:Client)->UserMeResponse:
    try:
        profile_res = supabase.table("shared_profile").select("full_name").eq("id", user_id).limit(1).execute()
        if not profile_res.data:
            raise HTTPException(status_code=404, detail="Profile not found")

        farmer_res = supabase.table("farmer_profile").select("id").eq("id", user_id).limit(1).execute()
        investor_res = supabase.table("investor_profile").select("id").eq("id", user_id).limit(1).execute()

        is_farmer = bool(farmer_res.data)
        is_investor = bool(investor_res.data)
        if is_farmer and is_investor:
            role = UserRole.BOTH
        elif is_farmer:
            role = UserRole.FARMER
        elif is_investor:
            role = UserRole.INVESTOR
        else:
            role = None

        # A user is considered verified once a shared_profile exists (checked above)
        return UserMeResponse(
            id=user_id,
            full_name=profile_res.data[0]["full_name"],
            role=role,
            is_verified=True,
        )
    except Exception as e:
        raise _to_http_exception(e, "get current user")


async def create_user_document(user_id:str,file:UploadFile,image_type:str,supabase:Client)->UserDocumentResponse:
    await validate_file_size(file=file)
    if not file.filename:
        raise HTTPException(status_code=400, detail="Filename is required")

    contents = await file.read()
    ext = file.filename.split(".")[-1]
    filename = f"{image_type}/{str(user_id)}.{ext}"

    try:
        supabase.storage.from_("user_document").upload(
            filename,
            contents,
            {'content-type': 'image/jpeg',"cache-control": "3600", "upsert": "true"},
        )
        public_url = supabase.storage.from_("user_document").get_public_url(filename)
    except Exception as e:
        raise _to_http_exception(e, "upload user document")

    try:
        response = supabase.table("user_document").upsert(
            {"image_url": public_url,"document_type":image_type,"profile_id":user_id}
        ).select("document_type,created_at").execute()
        if not response.data:
            raise ValueError("no data returned")

        created_at = response.data[0]["created_at"]
        document_type = response.data[0]["document_type"]
    except Exception as e:
        try:
            supabase.storage.from_("user_document").remove([filename])
        except Exception:
            logger.exception("Failed to clean up uploaded file %s", filename)
        logger.exception("Failed to save user document record")
        raise HTTPException(status_code=500, detail=f"update failed: {e}")

    return UserDocumentResponse(
        id=user_id,
        created_at=created_at,
        image_url=public_url,
        document_type=document_type
    )

async def create_farmer_profile(user_id:str,
                                farmer_profile:FarmerProfileReq,
                                supabase:Client)->FarmerProfileResponse:
    try:
        farmer_res = supabase.table("farmer_profile").insert({
                                   "id": user_id,
                                   "experience":farmer_profile.experience.value,
                                   "commodity":farmer_profile.commodity.value
                                   }).execute()
        farmer_res = farmer_res.data[0]
        response = FarmerProfileResponse(
            id=farmer_res["id"],
            experience=farmer_res["experience"],
            commodity=farmer_res["commodity"]
        )
        return response

    except Exception as e:
        raise _to_http_exception(e, "create farmer profile")


async def create_investor_profile(user_id:str,
                                  investor_profile: InvestorProfileReq,
                                  supabase:Client)->InvestorProfileResponse:
    try:
        investor_res = supabase.table("investor_profile").insert({
                                   "id": user_id,
                                   "income":investor_profile.income.value,
                                   "job":investor_profile.occupation.value
                                   }).execute()
        investor_res = investor_res.data[0]
        response = InvestorProfileResponse(
            id=investor_res["id"],
            occupation=investor_res["job"],
            income=investor_res["income"],
        )
        return response

    except Exception as e:
        raise _to_http_exception(e, "create investor profile")
