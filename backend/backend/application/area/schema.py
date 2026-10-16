from pydantic import BaseModel, field_validator, Field
from typing import Annotated, Optional
from datetime import date, datetime, time
import re
from fastapi import UploadFile
from enum import Enum


class LandReq(BaseModel):
    name: str
    description: str
    width: float
    address: str
    latitude: Annotated[float, Field(ge=-90, le=90)]
    longitude: Annotated[float, Field(ge=-180, le=180)]
    images: list[UploadFile]


class LandResponse(BaseModel):
    id: str
    name: str
    address: str
    latitude: Annotated[float, Field(ge=-90, le=90)]
    longitude: Annotated[float, Field(ge=-180, le=180)]
    description: str
    width: float
    created_at: datetime


class LandDocReq(BaseModel):
    id: str
    file_url: str
    area_id: str
    created_at: datetime


class LandDocResponse(BaseModel):
    id: str
    file_url: str
    area_id: str
    created_at: datetime


# ── New schemas ──────────────────────────────────────────────────────────────

class LandUpdateReq(BaseModel):
    """Partial update — only send fields you want to change."""
    name: Optional[str] = None
    description: Optional[str] = None
    width: Optional[float] = Field(None, gt=0)
    address: Optional[str] = None


class LandImageResponse(BaseModel):
    id: str
    image_url: str
    sort_position: int


class LandDetailResponse(BaseModel):
    id: str
    name: str
    address: str
    latitude: Annotated[float, Field(ge=-90, le=90)]
    longitude: Annotated[float, Field(ge=-180, le=180)]
    description: str
    width: float
    created_at: datetime
    farmer_id: str
    images: list[LandImageResponse] = []


class LandListItem(BaseModel):
    id: str
    name: str
    address: str
    latitude: Annotated[float, Field(ge=-90, le=90)]
    longitude: Annotated[float, Field(ge=-180, le=180)]
    width: float
    created_at: datetime
    farmer_id: str
