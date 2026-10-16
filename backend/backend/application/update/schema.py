from datetime import datetime

from pydantic import BaseModel


class InvestmentUpdateResponse(BaseModel):
    """Investment update row returned after its images are persisted."""

    id: str
    created_at: datetime
    investment_id: str
    image_url: list[str]
    image_path: list[str]
    title: str | None = None
    description: str | None = None
