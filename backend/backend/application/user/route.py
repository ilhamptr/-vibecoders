from fastapi import APIRouter
from user.schema import UserRegistrationReq,SharedProfileReq,SharedProfileResponse,UserDocumentType,\
    UserDocumentResponse,FarmerProfileReq,FarmerProfileResponse,InvestorProfileReq,InvestorProfileResponse,UserCredResponse,UserLoginReq,UserFullNameResponse,UserMeResponse
from user.service import register_user,create_shared_profile,create_user_document,create_farmer_profile,create_investor_profile,login_user,get_full_name,get_me
from dependencies.supabase import get_supabase,get_authenticated_supabase,get_current_user
from fastapi import Depends,UploadFile,Form,File,Body
from typing import Annotated


router = APIRouter(
    prefix="/user",
    tags=["user"],
    # dependencies=[Depends(get_current_user),Depends(get_supabase)],
    responses={404: {"description": "Not found"}},
)

@router.post("/register",status_code=201)
async def register(user_data:Annotated[UserRegistrationReq,Body(...)],supabase=Depends(get_supabase))->UserCredResponse:
    user = await register_user(user_data=user_data,supabase=supabase)
    return user

@router.post("/login",status_code=200)
async def login(user_data:Annotated[UserLoginReq,Body(...)],supabase=Depends(get_supabase))->UserCredResponse:
    user = await login_user(user_data=user_data,supabase=supabase)
    return user

@router.post("/profile-creation", status_code=201)
async def create_profile(user_profile:Annotated[SharedProfileReq,Body(...)],current_user=Depends(get_current_user),supabase=Depends(get_authenticated_supabase))->SharedProfileResponse:
    user_id= str(current_user.id)
    response = await create_shared_profile(user_id=user_id,user_profile=user_profile,supabase=supabase)
    return response

@router.get("/me")
async def read_me(current_user=Depends(get_current_user),supabase=Depends(get_authenticated_supabase))->UserMeResponse:
    user_id= str(current_user.id)
    response = await get_me(user_id=user_id,supabase=supabase)
    return response

@router.get("/full-name")
async def read_full_name(current_user=Depends(get_current_user),supabase=Depends(get_authenticated_supabase))->UserFullNameResponse:
    user_id= str(current_user.id)
    response = await get_full_name(user_id=user_id,supabase=supabase)
    return response

@router.post("/upload-user-document", status_code=201)
async def upload_document(document_type: Annotated[UserDocumentType, Form(...)],file:UploadFile=File(...),current_user=Depends(get_current_user),supabase=Depends(get_authenticated_supabase))->UserDocumentResponse:
    user_id= str(current_user.id)
    response = await create_user_document(user_id=user_id,file=file,image_type=document_type.value,supabase=supabase)
    return response

@router.post("/farmer-profile", status_code=201)
async def create_farmer(farmer_profile:Annotated[FarmerProfileReq,Body(...)],current_user=Depends(get_current_user),supabase=Depends(get_authenticated_supabase))->FarmerProfileResponse:
    user_id= str(current_user.id)
    response = await create_farmer_profile(user_id=user_id,farmer_profile=farmer_profile,supabase=supabase)
    return response


@router.post("/investor-profile",status_code=201)
async def create_investor(investor_profile:Annotated[InvestorProfileReq,Body(...)],current_user=Depends(get_current_user),supabase=Depends(get_authenticated_supabase))->InvestorProfileResponse:
    user_id = str(current_user.id)
    response = await create_investor_profile(user_id=user_id,investor_profile=investor_profile,supabase=supabase)
    return response
