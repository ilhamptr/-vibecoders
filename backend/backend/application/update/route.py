from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, UploadFile

from dependencies.supabase import get_authenticated_supabase, get_current_user
from update.schema import InvestmentUpdateResponse
from update.service import create_investment_update


router = APIRouter(
    prefix="/update",
    tags=["update"],
    responses={404: {"description": "Not found"}},
)


@router.post("/{investment_id}/images", status_code=201, response_model=InvestmentUpdateResponse)
async def upload_investment_update_images(
    investment_id: str,
    images: Annotated[list[UploadFile], File(...)],
    title: Annotated[str | None, Form()] = None,
    description: Annotated[str | None, Form()] = None,
    current_user=Depends(get_current_user),
    supabase=Depends(get_authenticated_supabase),
) -> InvestmentUpdateResponse:
    """Create an investment progress update with one or more private images."""

    # Keep the dependency explicit so this endpoint cannot be called without a
    # validated user token, even though the authenticated client also carries
    # the token for Supabase RLS.
    _ = current_user
    return await create_investment_update(
        investment_id=investment_id,
        images=images,
        user_id=str(current_user.id),
        title=title,
        description=description,
        supabase=supabase,
    )
