import asyncio
import os
import re
from typing import Any
from urllib.parse import quote
from uuid import UUID, uuid4

import filetype
from fastapi import HTTPException, UploadFile
from postgrest.exceptions import APIError
from supabase import Client

from update.schema import InvestmentUpdateResponse


BUCKET_NAME = "investment_updates"
MAX_IMAGES = 10
MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024
MAX_TOTAL_IMAGE_SIZE_BYTES = 25 * 1024 * 1024
SIGNED_URL_EXPIRY_SECONDS = 60 * 60

_ALLOWED_MIME_TYPES = {
    "image/jpeg": "jpg",
    "image/jpg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
}
_ALLOWED_DETECTED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
_SAFE_INVESTMENT_ID = re.compile(r"^[A-Za-z0-9_-]{1,128}$")


async def _validate_and_read_image(file: UploadFile) -> tuple[bytes, str]:
    """Validate the multipart metadata and the file signature before upload."""

    content_type = (file.content_type or "").lower()
    if content_type not in _ALLOWED_MIME_TYPES:
        raise HTTPException(status_code=415, detail="Unsupported image file type")

    file.file.seek(0)
    detected_type = filetype.guess(file.file)
    file.file.seek(0)

    detected_mime = detected_type.mime if detected_type else None
    if detected_mime not in _ALLOWED_DETECTED_MIME_TYPES:
        raise HTTPException(status_code=415, detail="Unsupported image file type")

    # image/jpg is a common multipart alias for the JPEG media type.
    if detected_mime != "image/jpeg" and _ALLOWED_MIME_TYPES[content_type] != detected_type.extension:
        raise HTTPException(status_code=415, detail="Image content does not match its media type")
    if detected_mime == "image/jpeg" and _ALLOWED_MIME_TYPES[content_type] != "jpg":
        raise HTTPException(status_code=415, detail="Image content does not match its media type")

    file_size = file.size
    if file_size is None:
        file.file.seek(0, 2)
        file_size = file.file.tell()
        file.file.seek(0)

    if not file_size:
        raise HTTPException(status_code=400, detail="Image file cannot be empty")
    if file_size > MAX_IMAGE_SIZE_BYTES:
        raise HTTPException(status_code=413, detail="Each image must be 5 MB or smaller")

    contents = await file.read(MAX_IMAGE_SIZE_BYTES + 1)
    if len(contents) > MAX_IMAGE_SIZE_BYTES:
        raise HTTPException(status_code=413, detail="Each image must be 5 MB or smaller")
    if not contents:
        raise HTTPException(status_code=400, detail="Image file cannot be empty")

    return contents, detected_type.extension


async def _remove_uploaded_objects(supabase: Client, paths: list[str]) -> None:
    """Best-effort rollback for objects created before a later operation failed."""

    if not paths:
        return

    try:
        await asyncio.to_thread(
            supabase.storage.from_(BUCKET_NAME).remove,
            paths,
        )
    except Exception:
        # Preserve the original upload/DB error. Orphan cleanup is best effort
        # because a second storage failure must not hide the root cause.
        pass


def _signed_url(result: Any) -> str:
    if isinstance(result, str):
        return result
    if isinstance(result, dict):
        url = result.get("signedURL") or result.get("signedUrl")
        if isinstance(url, str) and url:
            return url
    raise RuntimeError("Supabase did not return a signed image URL")


def _row_to_response(row: dict[str, Any]) -> InvestmentUpdateResponse:
    return InvestmentUpdateResponse(
        id=str(row["id"]),
        created_at=row["created_at"],
        investment_id=str(row["investment_id"]),
        image_url=[str(url) for url in (row.get("image_url") or [])],
        image_path=[str(path) for path in (row.get("image_path") or [])],
        title=row.get("title"),
        description=row.get("description"),
    )


def _normalise_investment_id(investment_id: str) -> str:
    normalised = investment_id.strip()
    if not _SAFE_INVESTMENT_ID.fullmatch(normalised):
        raise HTTPException(status_code=422, detail="Invalid investment_id")
    try:
        return str(UUID(normalised))
    except ValueError as error:
        raise HTTPException(status_code=422, detail="Invalid investment_id") from error


async def _ensure_investment_is_writable(
    investment_id: str,
    user_id: str,
    supabase: Client,
) -> None:
    try:
        response = await asyncio.to_thread(
            lambda: supabase.table("investment")
            .select("id,land_id")
            .eq("id", investment_id)
            .execute()
        )
        if not response.data:
            raise HTTPException(status_code=404, detail="Investment not found")
        land_id = response.data[0].get("land_id")
        owner_response = await asyncio.to_thread(
            lambda: supabase.table("area")
            .select("id")
            .eq("id", land_id)
            .eq("farmer_id", user_id)
            .is_("deleted_at", "null")
            .execute()
        )
    except HTTPException:
        raise
    except APIError as exc:
        raise HTTPException(status_code=exc.status, detail=str(exc.code)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Unable to verify investment ownership") from exc
    if not owner_response.data:
        raise HTTPException(status_code=403, detail="You do not own this investment")


def _private_object_url(file_path: str) -> str:
    base_url = os.getenv("SUPABASE_URL")
    if not base_url:
        raise RuntimeError("SUPABASE_URL is not configured")
    return (
        f"{base_url.rstrip('/')}/storage/v1/object/authenticated/"
        f"{BUCKET_NAME}/{quote(file_path, safe='/')}"
    )


def _validate_text_field(value: str | None, field_name: str, max_length: int) -> str | None:
    if value is None:
        return None
    if len(value) > max_length:
        raise HTTPException(
            status_code=422,
            detail=f"{field_name} must be {max_length} characters or fewer",
        )
    return value


async def create_investment_update(
    investment_id: str,
    images: list[UploadFile],
    supabase: Client,
    user_id: str,
    title: str | None = None,
    description: str | None = None,
) -> InvestmentUpdateResponse:
    """Upload progress images and create one row in ``public.update``.

    Storage paths are generated server-side and never use the client filename.
    The authenticated Supabase client is expected to enforce the database and
    storage RLS policies for the caller.
    """

    investment_id = _normalise_investment_id(investment_id)
    if not images:
        raise HTTPException(status_code=400, detail="At least one image is required")
    if len(images) > MAX_IMAGES:
        raise HTTPException(status_code=400, detail=f"A maximum of {MAX_IMAGES} images is allowed")

    title = _validate_text_field(title, "title", 200)
    description = _validate_text_field(description, "description", 5000)
    await _ensure_investment_is_writable(investment_id, user_id, supabase)

    validated_images: list[tuple[bytes, str]] = []
    total_size = 0
    for image in images:
        contents, extension = await _validate_and_read_image(image)
        total_size += len(contents)
        if total_size > MAX_TOTAL_IMAGE_SIZE_BYTES:
            raise HTTPException(status_code=413, detail="The combined image size must be 25 MB or smaller")
        validated_images.append((contents, extension))

    storage = supabase.storage.from_(BUCKET_NAME)
    image_paths: list[str] = []
    signed_image_urls: list[str] = []

    try:
        for contents, extension in validated_images:
            storage_path = f"{investment_id}/{uuid4().hex}.{extension}"
            await asyncio.to_thread(
                storage.upload,
                storage_path,
                contents,
                {
                    "content-type": "image/jpeg" if extension == "jpg" else f"image/{extension}",
                    "cache-control": "3600",
                    "upsert": "false",
                },
            )
            image_paths.append(storage_path)

            signed_result = await asyncio.to_thread(
                storage.create_signed_url,
                storage_path,
                SIGNED_URL_EXPIRY_SECONDS,
            )
            signed_image_urls.append(_signed_url(signed_result))
    except Exception as exc:
        await _remove_uploaded_objects(supabase, image_paths)
        if isinstance(exc, HTTPException):
            raise
        raise HTTPException(status_code=502, detail="Unable to store investment update images") from exc

    payload: dict[str, Any] = {
        "investment_id": investment_id,
        "image_url": [_private_object_url(path) for path in image_paths],
        "image_path": image_paths,
    }
    if title is not None:
        payload["title"] = title
    if description is not None:
        payload["description"] = description

    try:
        response = await asyncio.to_thread(
            lambda: supabase.table("update")
            .insert(payload)
            .select("id,created_at,investment_id,image_url,image_path,title,description")
            .execute()
        )
        data = response.data
        row = data[0] if isinstance(data, list) and data else data
        if not isinstance(row, dict):
            raise RuntimeError("Supabase returned no investment update row")
        return _row_to_response({**row, "image_url": signed_image_urls})
    except APIError as exc:
        await _remove_uploaded_objects(supabase, image_paths)
        status = getattr(exc, "status", 500)
        if not isinstance(status, int) or status < 400 or status > 599:
            status = 500
        raise HTTPException(status_code=status, detail="Unable to create investment update") from exc
    except HTTPException:
        await _remove_uploaded_objects(supabase, image_paths)
        raise
    except Exception as exc:
        await _remove_uploaded_objects(supabase, image_paths)
        raise HTTPException(status_code=500, detail="Unable to create investment update") from exc
