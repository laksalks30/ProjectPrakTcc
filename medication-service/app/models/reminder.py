# ============ FILE: medication-service/app/models/reminder.py ============
from sqlalchemy import Column, Integer, String, Time, Boolean, TIMESTAMP, ForeignKey, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.services.db import Base


class Reminder(Base):
    __tablename__ = "reminders"

    id = Column(Integer, primary_key=True, autoincrement=True)
    prescription_id = Column(Integer, ForeignKey("prescriptions.id", ondelete="CASCADE"), nullable=False)
    patient_id = Column(Integer, ForeignKey("patients.id", ondelete="CASCADE"), nullable=False)
    scheduled_time = Column(Time, nullable=False)
    days_of_week = Column(JSON, nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)
    notes = Column(String(255), nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())

    prescription = relationship("Prescription", back_populates="reminders")
    patient = relationship("Patient", back_populates="reminders")
    medication_logs = relationship("MedicationLog", back_populates="reminder")
