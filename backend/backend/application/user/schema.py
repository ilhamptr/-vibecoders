from pydantic import BaseModel,field_validator
from datetime import date, datetime
from typing import Optional
import re
from enum import Enum

EMAIL_REGEX = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

class UserGender(str, Enum):
    Laki = "Laki-Laki"
    Perempuan = "Perempuan"

class SharedProfileResponse(BaseModel):
    id:str
    full_name: str
    date_of_birth: date # Accepts "YYYY-MM-DD"
    sex: UserGender
    nik: str

class UserFullNameResponse(BaseModel):
    full_name: str

class UserRole(str, Enum):
    FARMER = "farmer"
    INVESTOR = "investor"
    BOTH = "both"

class UserMeResponse(BaseModel):
    id: str
    full_name: str
    role: Optional[UserRole] # None if the user has no farmer/investor profile yet
    is_verified: bool

class SharedProfileReq(BaseModel):
    full_name: str
    date_of_birth: date # Accepts "YYYY-MM-DD"
    sex: UserGender
    nik: str

    @field_validator("nik")
    @classmethod
    def nik_valid_length(cls, v: str) -> str:
        if len(v) != 16:
            raise ValueError("NIK Invalid, NIK harus 16 digit")
        return v

    
class UserLoginReq(BaseModel):
    email: str
    password: str

    @field_validator("email")
    @classmethod
    def valid_email(cls, email: str) -> str:
        if not re.fullmatch(EMAIL_REGEX, email):
            raise ValueError("Invalid email")

        return email

class UserCredResponse(BaseModel):
    id:str
    email:str
    created_at:datetime
    access_token: str
    refresh_token: str
    expires_in: int




class UserRegistrationReq(BaseModel):
    email: str
    phone: str
    password: str

    @field_validator("password")
    @classmethod
    def password_not_empty(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("password cannot be empty")
        if len(v) < 8:
            raise ValueError("password must be at least 8 characters")
        return v

    @field_validator("phone")
    @classmethod
    def valid_phone(cls, number: str) -> str:
        number = number.strip()

        if not number.startswith("+62"):
            raise ValueError("Invalid country code")

        if not number[1:].isdigit():
            raise ValueError("Phone number must contain only digits")

        if not 10 <= len(number) <= 15:
            raise ValueError("Phone number must be between 10 and 15 characters")

        return number

    @field_validator("email")
    @classmethod
    def valid_email(cls, email: str) -> str:
        if not re.fullmatch(EMAIL_REGEX, email):
            raise ValueError("Invalid email")

        return email



class UserDocumentType(str, Enum):
    ID = "identity card"
    SELFIE = "identification selfie"
   

class UserDocumentResponse(BaseModel):
    id:str
    created_at:datetime
    image_url:str
    document_type:UserDocumentType


class FormData(BaseModel):
    document_type: UserDocumentType



class FarmerExperience(str, Enum):
    BEGINER = "Baru mulai ( < 1 tahun )"
    INTERMEDIATE = "1 - 3 tahun"
    EXPERIECED =  "3 - 10 tahun"
    EXPERT = "Lebih dari 10 tahun"
   

class Comodity(str,Enum):
    PADI = "Padi"
    SAYUR = "Sayuran"
    REMPAH = "Rempah"
    BUAH = "Buah"
    PALAWIJA = "Palawija"
    KEBUN = "Perkebunan"

class FarmerProfileReq(BaseModel):
    experience:FarmerExperience
    commodity: Comodity


class FarmerProfileResponse(BaseModel):
    id:str
    experience: str
    commodity: str

class IncomeLevel(str,Enum):
    LOW= "< 5,000,000"
    MEDIUM = "5,000,000 - 10,000,000"
    MEDIUM_HIGH="10,000,000 - 25,000,000"
    HIGH="> 25,000,000"

class Occupation(str,Enum):
    KARYAWAN= "Karyawan Swasta"
    GOV= "PNS / BUMN"
    ENTRE = "Wiraswasta"
    PROF="Professional"
    ETC ="Lainnya"

class InvestorProfileReq(BaseModel):
    occupation:Occupation
    income:IncomeLevel


class InvestorProfileResponse(BaseModel):
    id:str
    occupation:str
    income:str

