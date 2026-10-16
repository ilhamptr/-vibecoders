import asyncio
import os
import re
from pathlib import PurePosixPath
from typing import Any, Callable
from urllib.parse import quote
from uuid import UUID, uuid4

import filetype
from fastapi import HTTPException, UploadFile
from postgrest.exceptions import APIError
from supabase import Client

from report.schema import ReportResponse


REPORT_BUCKET = "investment_reports"
MAX_REPORT_SIZE_BYTES = 20 * 1024 * 1024

_DOCUMENT_MIME_TYPES = {
    "pdf": {"application/pdf", "application/octet-stream"},
    "doc": {"application/msword", "application/octet-stream"},
    "docx": {
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/octet-stream",
    },
    "xls": {"application/vnd.ms-excel", "application/octet-stream"},
    "xlsx": {
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "application/octet-stream",
    },
    "ppt": {"application/vnd.ms-powerpoint", "application/octet-stream"},
    "pptx": {
        "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        "application/octet-stream",
    },
    "txt": {"text/plain"},
    "csv": {"text/csv", "application/csv", "application/vnd.ms-excel"},
}
_OOXML_EXTENSIONS = {"docx", "xlsx", "pptx"}
_SAFE_INVESTMENT_ID = re.compile(r"^[A-Za-z0-9_-]{1,128}$")
SIGNED_URL_EXPIRY_SECONDS = 60 * 60


def _normalise_filename(filename: str | None) -> str:
    if not filename:
        raise HTTPException(status_code=422, detail="A file name is required")

    # UploadFile.filename is client supplied. Treat both slash styles as path
    # separators before taking the final component.
    filename = filename.replace("\\", "/").rsplit("/", 1)[-1]
    if filename in {"", ".", ".."}:
        raise HTTPException(status_code=422, detail="A valid file name is required")
    return filename


def _validate_document(filename: str, content_type: str | None, contents: bytes) -> str:
    suffix = PurePosixPath(filename).suffix.lower().lstrip(".")
    if suffix not in _DOCUMENT_MIME_TYPES:
        raise HTTPException(status_code=415, detail="Unsupported report document type")

    mime_type = (content_type or "").split(";", 1)[0].strip().lower()
    if mime_type not in _DOCUMENT_MIME_TYPES[suffix]:
        raise HTTPException(status_code=415, detail="File type does not match its extension")

    # Reject a known binary signature that contradicts the requested document
    # type while allowing text files and test clients whose payload has no
    # detectable signature.
    detected = filetype.guess(contents)
    if detected is not None:
        detected_extension = detected.extension.lower()
        valid_signature = detected_extension == suffix or (
            suffix in _OOXML_EXTENSIONS and detected_extension == "zip"
        )
        if not valid_signature:
            raise HTTPException(status_code=415, detail="File contents do not match its extension")

    return suffix


def _normalise_title(title: str | None, filename: str) -> str:
    normalised = (title or PurePosixPath(filename).stem).strip()
    if not normalised:
        raise HTTPException(status_code=422, detail="Report title cannot be empty")
    if len(normalised) > 255:
        raise HTTPException(status_code=422, detail="Report title is too long")
    return normalised


def _normalise_investment_id(investment_id: str) -> str:
    normalised = investment_id.strip()
    if not _SAFE_INVESTMENT_ID.fullmatch(normalised):
        raise HTTPException(status_code=422, detail="Invalid investment_id")
    try:
        return str(UUID(normalised))
    except ValueError as error:
        raise HTTPException(status_code=422, detail="Invalid investment_id") from error


async def _run_blocking(operation: Callable[..., Any], *args: Any) -> Any:
    return await asyncio.to_thread(operation, *args)


async def _remove_uploaded_file(storage: Any, file_path: str) -> None:
    try:
        await _run_blocking(storage.remove, [file_path])
    except Exception:
        # Cleanup is best effort. The original failure is more useful to the
        # caller, and the path is retained in logs/DB only on a successful
        # insert.
        pass


async def _ensure_investment_is_writable(
    investment_id: str,
    user_id: str,
    supabase: Client,
) -> None:
    try:
        response = await _run_blocking(
            lambda: supabase.table("investment")
            .select("id,land_id")
            .eq("id", investment_id)
            .execute()
        )
    except APIError as error:
        raise HTTPException(status_code=error.status, detail=str(error.code))
    except Exception:
        raise HTTPException(status_code=500, detail="Unable to verify investment")

    if not response.data:
        raise HTTPException(status_code=404, detail="Investment not found")

    land_id = response.data[0].get("land_id")
    try:
        owner_response = await _run_blocking(
            lambda: supabase.table("area")
            .select("id")
            .eq("id", land_id)
            .eq("farmer_id", user_id)
            .is_("deleted_at", "null")
            .execute()
        )
    except APIError as error:
        raise HTTPException(status_code=error.status, detail=str(error.code))
    except Exception:
        raise HTTPException(status_code=500, detail="Unable to verify investment ownership")

    if not owner_response.data:
        raise HTTPException(status_code=403, detail="You do not own this investment")


def _private_object_url(storage: Any, file_path: str) -> str:
    base_url = os.getenv("SUPABASE_URL")
    if base_url:
        encoded_path = quote(file_path, safe="/")
        return (
            f"{base_url.rstrip('/')}/storage/v1/object/authenticated/"
            f"{REPORT_BUCKET}/{encoded_path}"
        )

    # This fallback keeps the service unit-testable without environment
    # configuration. In the application, SUPABASE_URL is loaded by the
    # Supabase dependency before this route is imported.
    return storage.get_public_url(file_path)


def _signed_url(storage: Any, file_path: str) -> str:
    result = storage.create_signed_url(file_path, SIGNED_URL_EXPIRY_SECONDS)
    if isinstance(result, str):
        return result
    if isinstance(result, dict):
        url = result.get("signedURL") or result.get("signedUrl")
        if isinstance(url, str) and url:
            return url
    raise RuntimeError("Supabase did not return a signed report URL")


async def upload_report(
    investment_id: str,
    file: UploadFile,
    supabase: Client,
    user_id: str,
    title: str | None = None,
) -> ReportResponse:
    investment_id = _normalise_investment_id(investment_id)
    filename = _normalise_filename(file.filename)
    report_title = _normalise_title(title, filename)

    contents = await file.read(MAX_REPORT_SIZE_BYTES + 1)
    if not contents:
        raise HTTPException(status_code=422, detail="Report file cannot be empty")
    if len(contents) > MAX_REPORT_SIZE_BYTES:
        raise HTTPException(status_code=413, detail="Report file is too large")

    extension = _validate_document(filename, file.content_type, contents)
    await _ensure_investment_is_writable(investment_id, user_id, supabase)

    file_path = f"{investment_id}/{uuid4()}.{extension}"
    storage = supabase.storage.from_(REPORT_BUCKET)

    try:
        await _run_blocking(
            storage.upload,
            file_path,
            contents,
            {
                "content-type": (file.content_type or "").split(";", 1)[0].strip().lower(),
                "cache-control": "3600",
                "upsert": "false",
            },
        )
    except Exception:
        await _remove_uploaded_file(storage, file_path)
        raise HTTPException(status_code=502, detail="Report storage upload failed")

    try:
        # Persist a stable authenticated object URL. The response returns a
        # one-hour signed URL while file_path remains the durable reference.
        file_url = _private_object_url(storage, file_path)
        signed_url = await _run_blocking(_signed_url, storage, file_path)
        response = await _run_blocking(
            lambda: supabase.table("report")
            .insert(
                {
                    "investment_id": investment_id,
                    "title": report_title,
                    "file_url": file_url,
                    "file_path": file_path,
                }
            )
            .select("id,investment_id,created_at,title,file_url,file_path")
            .execute()
        )
        if not response.data:
            raise RuntimeError("Report insert returned no row")
        return ReportResponse.model_validate({**response.data[0], "file_url": signed_url})
    except HTTPException:
        await _remove_uploaded_file(storage, file_path)
        raise
    except APIError as error:
        await _remove_uploaded_file(storage, file_path)
        raise HTTPException(status_code=error.status, detail=str(error.code))
    except Exception:
        await _remove_uploaded_file(storage, file_path)
        raise HTTPException(status_code=500, detail="Unable to persist report metadata")
