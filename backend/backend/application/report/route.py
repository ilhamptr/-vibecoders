from typing import Annotated

from dependencies.supabase import get_authenticated_supabase, get_current_user
from fastapi import APIRouter, Depends, File, Form, UploadFile

from report.schema import ReportResponse
from report.service import upload_report


router = APIRouter(
    prefix="/report",
    tags=["report"],
    responses={404: {"description": "Not found"}},
)


@router.post("/upload", status_code=201, response_model=ReportResponse)
async def upload_investment_report(
    investment_id: Annotated[str, Form(...)],
    file: Annotated[UploadFile, File(...)],
    title: Annotated[str | None, Form()] = None,
    current_user=Depends(get_current_user),
    supabase=Depends(get_authenticated_supabase),
) -> ReportResponse:
    # current_user is intentionally resolved even though the access check is
    # enforced by the authenticated Supabase client's RLS context.
    return await upload_report(
        investment_id=investment_id,
        title=title,
        file=file,
        user_id=str(current_user.id),
        supabase=supabase,
    )
