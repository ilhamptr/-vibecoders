from pydantic import BaseModel,model_validator
from typing import Annotated,List
from datetime import date, datetime, time
import re
from fastapi import UploadFile
from enum import Enum
from user.schema import Comodity

class UserFundResponse(BaseModel):
    user_id:str
    invested_fund:float
    wallet_balance:float

class FarmerFundResponse(BaseModel):
    user_id:str
    amount_to_withdraw:float
    wallet_balance:float

# class RoiPercentage(str, Enum):
#     MINIMAL = "1-10%"
#     LOW = "10-20%"
#     MODERATE = "20-40%"
#     BALANCED = "40-60%"
#     GROWTH = "60-80%"
#     AGRESSIVE = "80-100%"

class Status(str,Enum):
    DRAFT = "Draft"
    VERIF = "Menunggu Verifikasi"
    REV = "Perlu Perbaikan"
    ACTIVE = "Sedang Berjalan"
    FUND = "Dana Sudah Ditransfer"
    DONE = "Selesai"

class UserInvestmentStatus(str,Enum):
    ACTIVE = "Sedang Berjalan"
    DONE = "Selesai"

class InvesmentReq(BaseModel):
    description:str
    commodity:Comodity
    plant_start:date
    plant_end:date
    harvest_estimation: float
    estimated_selling_price:float
    target_amount:float
    status: Status = Status.ACTIVE

class InvestmentResponse(BaseModel):
    id:str
    commodity:Comodity
    description:str
    plant_start:date
    plant_end:date
    harvest_estimation: float
    estimated_selling_price:float
    target_amount:float
    created_at:datetime
    status:str

class FundInvestmentResponse(BaseModel):

    id:str
    commodity:Comodity
    status:str
    number_of_investors: int
    end_date:date
    target_amount:float
    collected_amount:float
    roi: float|None =None
    area_name: str | None = None
    images: List[str] = [] # area image urls ordered by sort_position, empty if the area has none
    # investments: List[InvestmentResponse]

class InvestmentDetailsResponse(FundInvestmentResponse):
    description: str
    creator_name: str | None = None # full_name from shared_profile of the area owner
    latitude: float | None = None # from area.location (PostGIS point)
    longitude: float | None = None

class ListFundInvestmentResponse(BaseModel):
    investments: List[FundInvestmentResponse]

class FundDetailsResponse(BaseModel):
    investment_id:str
    seedling:float
    fertilizer:float
    labour:float
    others: float | None = None
    description: str | None = None
    total: float


class FundDetailsReq(BaseModel):
    seedling:float
    fertilizer:float
    labour:float
    others: float | None = None
    description: str | None = None

    @model_validator(mode="after")
    def validate_others(self):
        if self.others is not None and self.others > 0:
            if not self.description:
                raise ValueError("Please specify the other categories")

        elif self.description:
            raise ValueError(
                "Description can only be specified when others is greater than 0"
            )
        return self

class InvestReq(BaseModel):
    amount:float

class InvestResponse(BaseModel):
    id: str
    amount:float
    investment_id: str
    created_at:datetime

class FundDetailMonth(BaseModel):
    month: str
    amount: float

class FundDetailYear(BaseModel):
    year: int
    amount: float

class ShowBasedOn(str,Enum):
    ANNUALLY = "Annually"
    MONTHLY = "Monthly"

class InvestedFundResponse(BaseModel):
    investor_id:str
    total_invested: float
    fund_details: list[FundDetailMonth] | list[FundDetailYear]
