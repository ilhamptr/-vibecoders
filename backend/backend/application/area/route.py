from fastapi import APIRouter
from area.schema import (
    LandReq, LandDocResponse, LandDocReq, LandResponse,
    LandUpdateReq, LandDetailResponse, LandListItem,
)
from area.service import (
    area_creation, create_area_document,
    get_area_list, get_area_detail, update_area, delete_area,
)
from dependencies.supabase import get_supabase, get_authenticated_supabase, get_current_user
from fastapi import Depends, UploadFile, Form, File, Body
from typing import Annotated


router = APIRouter(
    prefix="/area",
    tags=["area"],
    responses={404: {"description": "Not found"}},
)


# ── Existing endpoints ───────────────────────────────────────────────────────

@router.post("/create-land", status_code=201)
async def create_area(
    name: Annotated[str, Form(...)],
    images: Annotated[list[UploadFile], File(...)],
    description: Annotated[str, Form(...)],
    width: Annotated[float, Form(...)],
    address: Annotated[str, Form(...)],
    latitude: Annotated[float, Form(...)],
    longitude: Annotated[float, Form(...)],
    current_user=Depends(get_current_user),
    supabase=Depends(get_authenticated_supabase),
) -> LandResponse:
    """
    Daftarkan lahan baru milik petani yang sedang login.

    Request format: multipart/form-data (karena ada upload gambar)

    Args:
        name       : Nama lahan (contoh: "Sawah Pak Budi").
        images     : Satu atau lebih foto lahan (jpg/png/webp).
        description: Deskripsi kondisi lahan, jenis tanah, dll.
        width      : Luas lahan dalam meter persegi.
        address    : Alamat lengkap lahan.
        latitude   : Koordinat lintang (-90 sampai 90).
        longitude  : Koordinat bujur (-180 sampai 180).

    Returns:
        201 + LandResponse: data lahan yang baru dibuat.
    """
    user_id = str(current_user.id)
    land_data = LandReq(
        name=name,
        description=description,
        width=width,
        address=address,
        latitude=latitude,
        longitude=longitude,
        images=images
    )
    return await area_creation(land_data=land_data, farmer_id=user_id, supabase=supabase)


@router.post("/upload-area-document/{area_id}", status_code=201)
async def area_document(
    area_id: str,
    document: Annotated[UploadFile, File(...)],
    current_user=Depends(get_current_user),
    supabase=Depends(get_authenticated_supabase),
) -> LandDocResponse:
    """
    Upload sertifikat atau dokumen legal lahan (PDF only).

    Per lahan hanya disimpan 1 dokumen — kalau upload ulang,
    dokumen lama akan diganti (upsert).

    Args:
        area_id : UUID lahan tujuan (dari path URL).
        document: File PDF sertifikat tanah.

    Returns:
        201 + LandDocResponse: id, file_url, area_id, created_at.
    """
    return await create_area_document(area_id=area_id, file=document, supabase=supabase)


# ── New endpoints ────────────────────────────────────────────────────────────

@router.get("", status_code=200)
async def list_areas(
    current_user=Depends(get_current_user),
    supabase=Depends(get_authenticated_supabase),
) -> list[LandListItem]:
    """
    Ambil semua lahan aktif milik petani yang sedang login.

    Hanya mengembalikan lahan yang belum di-soft-delete.
    Koordinat latitude/longitude sudah dikonversi dari format PostGIS.

    Auth: Bearer token wajib ada di header.

    Returns:
        200 + list[LandListItem]: list lahan. Kosong ([]) jika belum ada lahan.
    """
    farmer_id = str(current_user.id)
    return await get_area_list(farmer_id=farmer_id, supabase=supabase)


@router.get("/{area_id}", status_code=200)
async def retrieve_area(
    area_id: str,
    current_user=Depends(get_current_user),
    supabase=Depends(get_authenticated_supabase),
) -> LandDetailResponse:
    """
    Ambil detail lengkap satu lahan termasuk semua foto-nya.

    Bisa diakses oleh petani maupun investor (semua user yang login).
    Foto diurutkan berdasarkan sort_position (0 = cover/utama).

    Args:
        area_id: UUID lahan yang mau dilihat (dari path URL).

    Returns:
        200 + LandDetailResponse: detail lahan + list images.
        404 jika lahan tidak ada atau sudah dihapus.
    """
    return await get_area_detail(area_id=area_id, supabase=supabase)


@router.patch("/{area_id}", status_code=200)
async def patch_area(
    area_id: str,
    update_data: LandUpdateReq,
    current_user=Depends(get_current_user),
    supabase=Depends(get_authenticated_supabase),
) -> LandDetailResponse:
    """
    Update sebagian info lahan. Hanya pemilik lahan yang boleh mengubah.

    Request body (JSON) — semua field opsional, kirim yang mau diubah saja:
        {
            "name": "Nama baru",          # opsional
            "description": "Deskripsi",   # opsional
            "address": "Alamat baru",      # opsional
            "width": 600.0                 # opsional, dalam meter persegi
        }

    Args:
        area_id    : UUID lahan yang mau diupdate (dari path URL).
        update_data: Body JSON berisi field yang mau diubah.

    Returns:
        200 + LandDetailResponse: data terbaru lahan setelah update.
        400 jika tidak ada field yang dikirim.
        403 jika bukan pemilik lahan.
        404 jika lahan tidak ditemukan.
    """
    farmer_id = str(current_user.id)
    return await update_area(
        area_id=area_id,
        update_data=update_data,
        farmer_id=farmer_id,
        supabase=supabase,
    )


@router.delete("/{area_id}", status_code=200)
async def remove_area(
    area_id: str,
    current_user=Depends(get_current_user),
    supabase=Depends(get_authenticated_supabase),
) -> dict:
    """
    Soft-delete lahan. Data tidak benar-benar dihapus — histori investasi tetap aman.

    Lahan yang dihapus tidak akan muncul lagi di GET /area.
    Hanya pemilik lahan yang bisa menghapus.

    Args:
        area_id: UUID lahan yang mau dihapus (dari path URL).

    Returns:
        200 + { "message": "Area deleted successfully" }
        403 jika bukan pemilik lahan.
        404 jika lahan tidak ditemukan atau sudah dihapus sebelumnya.
    """
    farmer_id = str(current_user.id)
    return await delete_area(area_id=area_id, farmer_id=farmer_id, supabase=supabase)
