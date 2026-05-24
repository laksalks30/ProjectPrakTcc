# ============ FILE: medication-service/app/schemas/log.py ============
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum


class LogStatusEnum(str, Enum):
    taken = "taken"
    missed = "missed"
    skipped = "skipped"
    late = "late"


class LogCreate(BaseModel):
    reminder_id: Optional[int] = None
    patient_id: int
    prescription_id: int
    scheduled_at: datetime
    taken_at: Optional[datetime] = None
    status: LogStatusEnum = LogStatusEnum.taken
    notes: Optional[str] = None
    logged_by: Optional[int] = None


class LogResponse(BaseModel):
    id: int
    reminder_id: Optional[int] = None
    patient_id: int
    prescription_id: int
    scheduled_at: datetime
    taken_at: Optional[datetime] = None
    status: str
    notes: Optional[str] = None
    logged_by: Optional[int] = None
    created_at: Optional[datetime] = None
    patient_name: Optional[str] = None
    medication_name: Optional[str] = None

    class Config:
        from_attributes = True
