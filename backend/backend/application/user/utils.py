from fastapi import UploadFile, HTTPException
import filetype


async def validate_file_size(
    file: UploadFile,
    max_size: int = 5 * 1024 * 1024,
) -> None:

    accepted_extensions = {"png", "jpg", "jpeg"}
    accepted_content_types = {
        "image/png",
        "image/jpeg",
        "image/jpg",
    }

    # Detect actual file type
    try:
        file_info = filetype.guess(file.file)
    except Exception:
        file_info = None

    if file_info is None:
        raise HTTPException(
            status_code=415,
            detail="Unable to determine file type",
        )

    detected_extension = file_info.extension.lower()

    # Validate MIME type
    if file.content_type not in accepted_content_types:
        raise HTTPException(
            status_code=415,
            detail="Unsupported file type",
        )

    # Validate actual file content
    if detected_extension not in accepted_extensions:
        raise HTTPException(
            status_code=415,
            detail="Unsupported file type",
        )

    # Reset file pointer after filetype.guess()
    file.file.seek(0)

    # Get file size
    if file.size is not None:
        file_size = file.size
    else:
        file.file.seek(0, 2)
        file_size = file.file.tell()
        file.file.seek(0)

    # Validate size
    if file_size > max_size:
        raise HTTPException(
            status_code=413,
            detail=(
                f"File too large. Max size is "
                f"{max_size / (1024 * 1024):.0f} MB, "
                f"got {file_size / (1024 * 1024):.2f} MB"
            ),
        )
