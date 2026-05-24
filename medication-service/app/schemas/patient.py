# ============ FILE: medication-service/app/schemas/patient.py ============
from pydantic import BaseModel, Field
from typing import Optional
from datetime import date, datetime
from enum import Enum


class GenderEnum(str, Enum):
    male = "male"
    female = "female"


class BloodTypeEnum(str, Enum):
    A = "A"
    B = "B"
    AB = "AB"
    O = "O"


class PatientCreate(BaseModel):
    user_id: Optional[int] = None
    name: str = Field(..., min_length=2, max_length=100)
    birth_date: date
    gender: GenderEnum
    address: Optional[str] = None
    blood_type: Optional[BloodTypeEnum] = None
    medical_notes: Optional[str] = None
    caregiver_id: Optional[int] = None


class PatientUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    birth_date: Optional[date] = None
    gender: Optional[GenderEnum] = None
    address: Optional[str] = None
    blood_type: Optional[BloodTypeEnum] = None
    medical_notes: Optional[str] = None
    caregiver_id: Optional[int] = None


class PatientResponse(BaseModel):
    id: int
    user_id: Optional[int] = None
    name: str
    birth_date: date
    gender: str
    address: Optional[str] = None
    blood_type: Optional[str] = None
    photo_url: Optional[str] = None
    medical_notes: Optional[str] = None
    caregiver_id: Optional[int] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
