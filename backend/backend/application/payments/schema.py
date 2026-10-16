from pydantic import BaseModel,model_validator,field_validator
from typing import Annotated
from datetime import date, datetime, time
import re
from fastapi import UploadFile
from enum import Enum
from user.schema import Comodity


class TopUpRequest(BaseModel):
    amount:float


    @field_validator("amount")
    @classmethod
    def amount_val(cls, v: float) -> float:
        if v < 10000:
            raise ValueError("Minimal isi saldo Rp. 10.000")
        else:
            return v
        
class TopUpRes(BaseModel):
    reference_id:str
    payment_link_url:str
    status:str


class ProfitReq(BaseModel):
    amount:float


class ProfitResponse(BaseModel):
    message:str

    
class TransferFundRes(BaseModel):
    message:str

