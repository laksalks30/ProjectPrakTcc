# ============ FILE: medication-service/app/models/prescription.py ============
from sqlalchemy import Column, Integer, String, Date, Text, Enum, TIMESTAMP, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.services.db import Base


class Prescription(Base):
    __tablename__ = "prescriptions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    patient_id = Column(Integer, ForeignKey("patients.id", ondelete="CASCADE"), nullable=False)
    medication_id = Column(Integer, ForeignKey("medications.id", ondelete="CASCADE"), nullable=False)
    dosage = Column(String(100), nullable=False)
    frequency = Column(String(100), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=True)
    doctor_name = Column(String(100), nullable=True)
    notes = Column(Text, nullable=True)
    status = Column(Enum("active", "completed", "stopped"), nullable=False, default="active")
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())

    patient = relationship("Patient", back_populates="prescriptions")
    medication = relationship("Medication", back_populates="prescriptions")
    reminders = relationship("Reminder", back_populates="prescription", cascade="all, delete-orphan")
    medication_logs = relationship("MedicationLog", back_populates="prescription", cascade="all, delete-orphan")
