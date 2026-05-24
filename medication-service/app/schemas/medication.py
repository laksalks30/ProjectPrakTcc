# ============ FILE: medication-service/app/schemas/medication.py ============
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class MedicationCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=150)
    generic_name: Optional[str] = Field(None, max_length=150)
    category: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None
    unit: str = Field(default="tablet", max_length=50)


class MedicationUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=150)
    generic_name: Optional[str] = Field(None, max_length=150)
    category: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None
    unit: Optional[str] = Field(None, max_length=50)


class MedicationResponse(BaseModel):
    id: int
    name: str
    generic_name: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    photo_url: Optional[str] = None
    unit: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
