# ============ FILE: medication-service/app/routers/medications.py ============
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from sqlalchemy.orm import Session
from typing import Optional
from app.services.db import get_db
from app.models.medication import Medication
from app.schemas.medication import MedicationCreate, MedicationUpdate, MedicationResponse
from app.services.gcs_service import upload_file_to_gcs, delete_file_from_gcs
from app.routers.auth_middleware import get_current_user

router = APIRouter(prefix="/medications", tags=["Medications"])


def success_response(data=None, message="Success", meta=None):
    return {"success": True, "message": message, "data": data, "meta": meta}


@router.post("", summary="Tambah data obat")
async def create_medication(
    medication_data: MedicationCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    try:
        medication = Medication(**medication_data.model_dump())
        db.add(medication)
        db.commit()
        db.refresh(medication)
        return success_response(
            data={"medication": MedicationResponse.model_validate(medication).model_dump()},
            message="Medication created successfully"
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})


@router.get("", summary="List semua obat")
async def get_medications(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    search: Optional[str] = Query(None),
    category: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    try:
        query = db.query(Medication)
        if search:
            query = query.filter(
                (Medication.name.ilike(f"%{search}%")) |
                (Medication.generic_name.ilike(f"%{search}%"))
            )
        if category:
            query = query.filter(Medication.category.ilike(f"%{category}%"))
        total = query.count()
        medications = query.offset((page - 1) * limit).limit(limit).all()
        return success_response(
            data={"medications": [MedicationResponse.model_validate(m).model_dump() for m in medications]},
            meta={"total": total, "page": page, "limit": limit, "totalPages": -(-total // limit)}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})


@router.put("/{medication_id}", summary="Update data obat + upload foto")
async def update_medication(
    medication_id: int,
    name: Optional[str] = None,
    generic_name: Optional[str] = None,
    category: Optional[str] = None,
    description: Optional[str] = None,
    unit: Optional[str] = None,
    photo: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    medication = db.query(Medication).filter(Medication.id == medication_id).first()
    if not medication:
        raise HTTPException(status_code=404, detail={"success": False, "message": "Medication not found", "data": None, "meta": None})
    try:
        if name is not None:
            medication.name = name
        if generic_name is not None:
            medication.generic_name = generic_name
        if category is not None:
            medication.category = category
        if description is not None:
            medication.description = description
        if unit is not None:
            medication.unit = unit

        if photo:
            if medication.photo_url:
                await delete_file_from_gcs(medication.photo_url)
            content = await photo.read()
            photo_url = await upload_file_to_gcs(content, photo.filename, photo.content_type, "medications")
            medication.photo_url = photo_url

        db.commit()
        db.refresh(medication)
        return success_response(
            data={"medication": MedicationResponse.model_validate(medication).model_dump()},
            message="Medication updated successfully"
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})


@router.delete("/{medication_id}", summary="Hapus data obat")
async def delete_medication(
    medication_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    medication = db.query(Medication).filter(Medication.id == medication_id).first()
    if not medication:
        raise HTTPException(status_code=404, detail={"success": False, "message": "Medication not found", "data": None, "meta": None})
    try:
        if medication.photo_url:
            await delete_file_from_gcs(medication.photo_url)
        db.delete(medication)
        db.commit()
        return success_response(data={"id": medication_id}, message="Medication deleted successfully")
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})
