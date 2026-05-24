# ============ FILE: medication-service/app/models/log.py ============
from sqlalchemy import Column, Integer, String, DateTime, Text, Enum, TIMESTAMP, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.services.db import Base


class MedicationLog(Base):
    __tablename__ = "medication_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    reminder_id = Column(Integer, ForeignKey("reminders.id", ondelete="SET NULL"), nullable=True)
    patient_id = Column(Integer, ForeignKey("patients.id", ondelete="CASCADE"), nullable=False)
    prescription_id = Column(Integer, ForeignKey("prescriptions.id", ondelete="CASCADE"), nullable=False)
    scheduled_at = Column(DateTime, nullable=False)
    taken_at = Column(DateTime, nullable=True)
    status = Column(Enum("taken", "missed", "skipped", "late"), nullable=False, default="taken")
    notes = Column(Text, nullable=True)
    logged_by = Column(Integer, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    reminder = relationship("Reminder", back_populates="medication_logs")
    patient = relationship("Patient", back_populates="medication_logs")
    prescription = relationship("Prescription", back_populates="medication_logs")
