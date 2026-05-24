# ============ FILE: medication-service/app/schemas/reminder.py ============
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import time, datetime


class ReminderCreate(BaseModel):
    prescription_id: int
    patient_id: int
    scheduled_time: time
    days_of_week: Optional[List[str]] = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    is_active: bool = True
    notes: Optional[str] = Field(None, max_length=255)


class ReminderUpdate(BaseModel):
    scheduled_time: Optional[time] = None
    days_of_week: Optional[List[str]] = None
    is_active: Optional[bool] = None
    notes: Optional[str] = Field(None, max_length=255)


class ReminderResponse(BaseModel):
    id: int
    prescription_id: int
    patient_id: int
    scheduled_time: time
    days_of_week: Optional[List[str]] = None
    is_active: bool
    notes: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    patient_name: Optional[str] = None
    medication_name: Optional[str] = None

    class Config:
        from_attributes = True
