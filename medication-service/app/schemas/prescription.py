# ============ FILE: medication-service/app/schemas/prescription.py ============
from pydantic import BaseModel, Field
from typing import Optional
from datetime import date, datetime
from enum import Enum


class PrescriptionStatusEnum(str, Enum):
    active = "active"
    completed = "completed"
    stopped = "stopped"


class PrescriptionCreate(BaseModel):
    patient_id: int
    medication_id: int
    dosage: str = Field(..., min_length=1, max_length=100)
    frequency: str = Field(..., min_length=1, max_length=100)
    start_date: date
    end_date: Optional[date] = None
    doctor_name: Optional[str] = Field(None, max_length=100)
    notes: Optional[str] = None
    status: PrescriptionStatusEnum = PrescriptionStatusEnum.active


class PrescriptionUpdate(BaseModel):
    dosage: Optional[str] = Field(None, min_length=1, max_length=100)
    frequency: Optional[str] = Field(None, min_length=1, max_length=100)
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    doctor_name: Optional[str] = Field(None, max_length=100)
    notes: Optional[str] = None
    status: Optional[PrescriptionStatusEnum] = None


class PrescriptionResponse(BaseModel):
    id: int
    patient_id: int
    medication_id: int
    dosage: str
    frequency: str
    start_date: date
    end_date: Optional[date] = None
    doctor_name: Optional[str] = None
    notes: Optional[str] = None
    status: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    patient_name: Optional[str] = None
    medication_name: Optional[str] = None

    class Config:
        from_attributes = True
