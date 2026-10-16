from datetime import datetime

from pydantic import BaseModel


class ReportResponse(BaseModel):
    id: str
    investment_id: str
    created_at: datetime
    title: str
    file_url: str
    file_path: str
