# ============ FILE: medication-service/app/models/medication.py ============
from sqlalchemy import Column, Integer, String, Text, TIMESTAMP
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.services.db import Base


class Medication(Base):
    __tablename__ = "medications"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(150), nullable=False)
    generic_name = Column(String(150), nullable=True)
    category = Column(String(100), nullable=True)
    description = Column(Text, nullable=True)
    photo_url = Column(String(500), nullable=True)
    unit = Column(String(50), nullable=False, default="tablet")
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())

    prescriptions = relationship("Prescription", back_populates="medication", cascade="all, delete-orphan")
