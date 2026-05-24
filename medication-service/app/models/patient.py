# ============ FILE: medication-service/app/models/patient.py ============
from sqlalchemy import Column, Integer, String, Date, Text, Enum, TIMESTAMP
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.services.db import Base


class Patient(Base):
    __tablename__ = "patients"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, nullable=True)
    name = Column(String(100), nullable=False)
    birth_date = Column(Date, nullable=False)
    gender = Column(Enum("male", "female"), nullable=False)
    address = Column(Text, nullable=True)
    blood_type = Column(Enum("A", "B", "AB", "O"), nullable=True)
    photo_url = Column(String(500), nullable=True)
    medical_notes = Column(Text, nullable=True)
    caregiver_id = Column(Integer, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())

    prescriptions = relationship("Prescription", back_populates="patient", cascade="all, delete-orphan")
    reminders = relationship("Reminder", back_populates="patient", cascade="all, delete-orphan")
    medication_logs = relationship("MedicationLog", back_populates="patient", cascade="all, delete-orphan")
