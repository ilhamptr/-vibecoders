from supabase import Client
import uuid
from area.schema import (
    LandReq, LandResponse, LandDocReq, LandDocResponse,
    LandUpdateReq, LandDetailResponse, LandListItem, LandImageResponse,
)
from user.utils import validate_file_size
from fastapi import HTTPException, UploadFile
from postgrest.exceptions import APIError
from datetime import datetime, timezone

import asyncio


# ── Existing helpers ─────────────────────────────────────────────────────────

async def area_image_upload(area_id: str, file: UploadFile, sort_position: int, supabase: Client) -> dict:
    """
    Upload satu gambar lahan ke Supabase Storage bucket 'area_images'.

    Dipanggil secara paralel dari area_creation() untuk tiap gambar yang dikirim.
    Path file di storage: {area_id}/{uuid}.{ext}

    Args:
        area_id      : UUID lahan yang sedang dibuat (belum disimpan di DB saat ini).
        file         : File gambar dari multipart form (jpg, png, dll).
        sort_position: Urutan tampil gambar (0 = pertama / cover).
        supabase     : Supabase client yang sudah ter-auth dengan JWT user.

    Returns:
        dict berisi { image_url: str, sort_position: int }
        yang akan dikirim ke RPC create_area_with_images sebagai bagian dari p_images.

    Raises:
        HTTPException 500 jika upload ke storage gagal.
    """
    contents = await file.read()
    ext = file.filename.split(".")[-1]
    image_id = str(uuid.uuid4())
    filename = f"{area_id}/{image_id}.{ext}"
    try:
        await asyncio.to_thread(
            supabase.storage.from_("area_images").upload,
            filename,
            contents,
            {
                "content-type": file.content_type,
                "cache-control": "3600",
                "upsert": "false",
            },
        )
        public_url = supabase.storage.from_("area_images").get_public_url(filename)
        return {"image_url": public_url, "sort_position": sort_position}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


async def area_creation(land_data: LandReq, farmer_id: str, supabase: Client) -> LandResponse:
    """
    Buat lahan baru beserta semua foto-nya dalam satu operasi atomik.

    Alur kerja:
        1. Validasi ukuran semua file gambar secara paralel.
        2. Upload semua gambar ke storage secara paralel (asyncio.gather).
        3. Panggil RPC 'create_area_with_images' yang menyimpan lahan +
           gambar ke DB dalam satu transaksi PostgreSQL.

    Dipanggil dari: POST /area/create-land

    Args:
        land_data: LandReq berisi name, description, width, address,
                   latitude, longitude, dan list gambar (UploadFile).
        supabase : Supabase client yang sudah ter-auth dengan JWT petani.

    Returns:
        LandResponse berisi data lahan yang baru dibuat.

    Raises:
        HTTPException 400 jika RPC gagal (APIError).
        HTTPException 500 jika ada error lain.
    """
    await asyncio.gather(
        *(validate_file_size(file=file) for file in land_data.images)
    )

    images_objs = land_data.images
    area_id = str(uuid.uuid4())

    result = await asyncio.gather(
        *[area_image_upload(area_id=area_id, file=file, sort_position=count, supabase=supabase)
          for count, file in enumerate(images_objs)]
    )

    try:
        res = supabase.rpc(
            "create_area_with_images",
            {
                "p_area_id": area_id,
                "p_area_name": land_data.name,
                "p_area_description": land_data.description,
                "p_area_width": land_data.width,
                "p_area_address": land_data.address,
                "p_area_latitude": land_data.latitude,
                "p_area_longitude": land_data.longitude,
                "p_images": result,
            }
        ).execute()
        data = res.data or []
    except APIError as e:
        raise HTTPException(status_code=e.status, detail=str(e.code))
    except Exception as e:
        raise HTTPException(status_code=500, detail="something went wrong")

    data = LandResponse(
        id=data["id"],
        name=data["name"],
        address=data["address"],
        latitude=data["latitude"],
        longitude=data["longitude"],
        description=data["description"],
        width=data["area_width"],
        created_at=data["created_at"]
    )
    return data


async def upload_area_document(area_id: str, file: UploadFile, supabase: Client) -> str:
    """
    Upload dokumen PDF lahan (sertifikat tanah) ke Supabase Storage bucket 'area_documents'.

    Hanya menerima file PDF. File disimpan dengan nama {area_id}.pdf
    sehingga per lahan hanya ada 1 dokumen (upsert).

    Dipanggil dari: create_area_document()

    Args:
        area_id : UUID lahan yang dokumennya mau diupload.
        file    : File PDF dari multipart form.
        supabase: Supabase client yang sudah ter-auth dengan JWT petani.

    Returns:
        public_url (str) dari dokumen yang sudah diupload.

    Raises:
        HTTPException 415 jika file bukan PDF.
        HTTPException 500 jika upload ke storage gagal.
    """
    accepted_content_types = {"application/pdf"}

    if file.content_type not in accepted_content_types:
        raise HTTPException(status_code=415, detail="Unsupported file type")

    contents = await file.read()
    ext = file.filename.split(".")[-1]
    filename = f"{area_id}.{ext}"
    try:
        await asyncio.to_thread(
            supabase.storage.from_("area_documents").upload,
            filename,
            contents,
            {
                "content-type": file.content_type,
                "cache-control": "3600",
                "upsert": "true",
            },
        )
        public_url = supabase.storage.from_("area_documents").get_public_url(filename)
        return public_url
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


async def create_area_document(area_id: str, file: UploadFile, supabase: Client) -> LandDocResponse:
    """
    Upload PDF sertifikat lahan ke storage lalu simpan URL-nya ke tabel area_documents.

    Menggunakan UPSERT sehingga kalau dokumen sebelumnya sudah ada,
    file lama di storage diganti dan record DB diperbarui.

    Dipanggil dari: POST /area/upload-area-document/{area_id}

    Args:
        area_id : UUID lahan tujuan dokumen.
        file    : File PDF dari multipart form.
        supabase: Supabase client yang sudah ter-auth dengan JWT petani.

    Returns:
        LandDocResponse berisi id, file_url, area_id, created_at.

    Raises:
        HTTPException 415 jika file bukan PDF.
        HTTPException 500 jika simpan ke DB gagal (storage akan dicoba di-rollback).
    """
    ext = file.filename.split(".")[-1]
    file_url = await upload_area_document(area_id=area_id, file=file, supabase=supabase)
    try:
        response = supabase.table("area_documents").upsert(
            {"file_url": file_url, "area_id": area_id}
        ).select("id,file_url,created_at").execute()
        id = response.data[0]["id"]
        url = response.data[0]["file_url"]
        created_at = response.data[0]["created_at"]
    except Exception as e:
        try:
            supabase.storage.from_("area_documents").remove([f"{area_id}.{ext}"])
        except Exception:
            pass
        raise HTTPException(status_code=500, detail=f"update failed: {e}")

    return LandDocResponse(
        id=id,
        file_url=url,
        area_id=area_id,
        created_at=created_at
    )


# ── New service functions ────────────────────────────────────────────────────

async def get_area_list(farmer_id: str, supabase: Client) -> list[LandListItem]:
    """
    Ambil semua lahan aktif milik seorang petani.

    Memanggil RPC 'get_areas_by_farmer' yang mengambil data dari tabel area
    sekaligus mengkonversi koordinat PostGIS ke latitude/longitude desimal.
    Lahan yang sudah di-soft-delete (deleted_at IS NOT NULL) tidak ikut ditampilkan.

    Dipanggil dari: GET /area

    Args:
        farmer_id: UUID petani (diambil dari auth.uid() / current_user.id).
        supabase : Supabase client yang sudah ter-auth dengan JWT petani.

    Returns:
        List of LandListItem. List kosong ([]) jika petani belum punya lahan.

    Raises:
        HTTPException 400 jika RPC error.
        HTTPException 500 jika error tidak terduga.
    """
    try:
        response = supabase.rpc("get_areas_by_farmer", {"p_farmer_id": farmer_id}).execute()
        data = response.data or []
        return [
            LandListItem(
                id=str(item["id"]),
                name=item["name"],
                address=item["address"],
                latitude=float(item.get("latitude") or 0.0),
                longitude=float(item.get("longitude") or 0.0),
                width=float(item["area_width"]),
                created_at=item["created_at"],
                farmer_id=str(item["farmer_id"]),
            )
            for item in data
        ]
    except APIError as e:
        raise HTTPException(status_code=e.status, detail=str(e.code))
    except Exception as e:
        raise HTTPException(status_code=500, detail="something went wrong")


async def get_area_detail(area_id: str, supabase: Client) -> LandDetailResponse:
    """
    Ambil detail lengkap satu lahan beserta semua foto-nya.

    Memanggil RPC 'get_area_detail' yang join tabel area + area_images
    dalam satu query, dengan foto diurutkan berdasarkan sort_position.
    Lahan yang sudah di-soft-delete akan return 404.

    Dipanggil dari: GET /area/{area_id}
    Juga dipanggil internal oleh update_area() untuk return data terbaru.

    Args:
        area_id : UUID lahan yang mau dilihat.
        supabase: Supabase client yang sudah ter-auth dengan JWT user.

    Returns:
        LandDetailResponse berisi semua field lahan + list foto (images).

    Raises:
        HTTPException 404 jika lahan tidak ditemukan atau sudah dihapus.
        HTTPException 400 jika RPC error.
        HTTPException 500 jika error tidak terduga.
    """
    try:
        response = supabase.rpc("get_area_detail", {"p_area_id": area_id}).execute()
        data = response.data
        if not data:
            raise HTTPException(status_code=404, detail="Area not found")
        images = [
            LandImageResponse(
                id=str(img["id"]),
                image_url=img["image_url"],
                sort_position=img["sort_position"],
            )
            for img in (data.get("images") or [])
        ]
        return LandDetailResponse(
            id=str(data["id"]),
            name=data["name"],
            address=data["address"],
            latitude=float(data.get("latitude") or 0.0),
            longitude=float(data.get("longitude") or 0.0),
            description=data.get("description", ""),
            width=float(data["area_width"]),
            created_at=data["created_at"],
            farmer_id=str(data["farmer_id"]),
            images=images,
        )
    except HTTPException:
        raise
    except APIError as e:
        raise HTTPException(status_code=e.status, detail=str(e.code))
    except Exception as e:
        raise HTTPException(status_code=500, detail="something went wrong")


async def update_area(
    area_id: str,
    update_data: LandUpdateReq,
    farmer_id: str,
    supabase: Client,
) -> LandDetailResponse:
    """
    Update sebagian field lahan. Hanya pemilik lahan yang boleh mengubah.

    Alur:
        1. Cek apakah lahan ada dan belum dihapus.
        2. Cek apakah farmer_id yang request = farmer_id pemilik lahan.
        3. Bangun dict update hanya dari field yang dikirim (tidak None).
        4. Jalankan UPDATE ke tabel area.
        5. Return data terbaru via get_area_detail().

    Field yang bisa diupdate: name, description, address, width.
    Field yang TIDAK bisa diupdate: id, farmer_id, created_at, deleted_at, location.

    Dipanggil dari: PATCH /area/{area_id}

    Args:
        area_id    : UUID lahan yang mau diupdate.
        update_data: LandUpdateReq — semua field opsional, kirim yang mau diubah saja.
        farmer_id  : UUID petani yang sedang login (diambil dari current_user.id).
        supabase   : Supabase client yang sudah ter-auth dengan JWT petani.

    Returns:
        LandDetailResponse dengan data terbaru setelah update.

    Raises:
        HTTPException 400 jika tidak ada field yang dikirim.
        HTTPException 403 jika bukan pemilik lahan.
        HTTPException 404 jika lahan tidak ditemukan atau sudah dihapus.
        HTTPException 500 jika error tidak terduga.
    """
    try:
        # Verify ownership
        existing = (
            supabase.table("area")
            .select("farmer_id")
            .eq("id", area_id)
            .is_("deleted_at", "null")
            .execute()
        )
        if not existing.data:
            raise HTTPException(status_code=404, detail="Area not found")
        if str(existing.data[0]["farmer_id"]) != farmer_id:
            raise HTTPException(status_code=403, detail="Not authorized to edit this area")

        # Build update payload (only non-None fields; width maps to area_width)
        update_dict = {}
        if update_data.name is not None:
            update_dict["name"] = update_data.name
        if update_data.description is not None:
            update_dict["description"] = update_data.description
        if update_data.address is not None:
            update_dict["address"] = update_data.address
        if update_data.width is not None:
            update_dict["area_width"] = update_data.width

        if not update_dict:
            raise HTTPException(status_code=400, detail="No fields provided for update")

        supabase.table("area").update(update_dict).eq("id", area_id).execute()
        return await get_area_detail(area_id=area_id, supabase=supabase)
    except HTTPException:
        raise
    except APIError as e:
        raise HTTPException(status_code=e.status, detail=str(e.code))
    except Exception as e:
        raise HTTPException(status_code=500, detail="something went wrong")


async def delete_area(area_id: str, farmer_id: str, supabase: Client) -> dict:
    """
    Soft-delete lahan — data tidak benar-benar dihapus dari DB.

    Cara kerja soft delete:
        UPDATE area SET deleted_at = NOW() WHERE id = area_id
    Lahan yang sudah di-delete tidak akan muncul di GET /area,
    tapi data histori investasi tetap tersimpan dan bisa direferensikan.

    Alur:
        1. Cek apakah lahan ada dan belum dihapus sebelumnya.
        2. Cek apakah farmer_id yang request = pemilik lahan.
        3. Set deleted_at = waktu sekarang (UTC).

    Dipanggil dari: DELETE /area/{area_id}

    Args:
        area_id  : UUID lahan yang mau dihapus.
        farmer_id: UUID petani yang sedang login (diambil dari current_user.id).
        supabase : Supabase client yang sudah ter-auth dengan JWT petani.

    Returns:
        dict { "message": "Area deleted successfully" }

    Raises:
        HTTPException 403 jika bukan pemilik lahan.
        HTTPException 404 jika lahan tidak ditemukan atau sudah dihapus sebelumnya.
        HTTPException 500 jika error tidak terduga.
    """
    try:
        # Verify ownership and not already deleted
        existing = (
            supabase.table("area")
            .select("farmer_id")
            .eq("id", area_id)
            .is_("deleted_at", "null")
            .execute()
        )
        if not existing.data:
            raise HTTPException(status_code=404, detail="Area not found")
        if str(existing.data[0]["farmer_id"]) != farmer_id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this area")

        now_str = datetime.now(timezone.utc).isoformat()
        supabase.table("area").update({"deleted_at": now_str}).eq("id", area_id).execute()
        return {"message": "Area deleted successfully"}
    except HTTPException:
        raise
    except APIError as e:
        raise HTTPException(status_code=e.status, detail=str(e.code))
    except Exception as e:
        raise HTTPException(status_code=500, detail="something went wrong")