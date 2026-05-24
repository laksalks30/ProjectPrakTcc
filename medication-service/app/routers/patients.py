from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from sqlalchemy.orm import Session
from typing import Optional
from app.services.db import get_db
from app.models.patient import Patient
from app.schemas.patient import PatientCreate, PatientUpdate, PatientResponse
from app.services.gcs_service import upload_file_to_gcs, delete_file_from_gcs
from app.routers.auth_middleware import get_current_user

router = APIRouter(prefix="/patients", tags=["Patients"])


def success_response(data=None, message="Success", meta=None):
    return {"success": True, "message": message, "data": data, "meta": meta}


def _get_owned_patient(patient_id: int, current_user: dict, db: Session) -> Patient:
    """
    Ambil pasien berdasarkan id DAN caregiver_id = user yang login.
    Kalau tidak ditemukan / bukan miliknya → 404 (bukan 403, agar tidak bocor info).
    """
    caregiver_id = current_user.get("id")
    role = current_user.get("role", "user")

    query = db.query(Patient).filter(Patient.id == patient_id)
    # Admin bisa akses semua pasien, user biasa hanya miliknya
    if role != "admin":
        query = query.filter(Patient.caregiver_id == caregiver_id)

    patient = query.first()
    if not patient:
        raise HTTPException(
            status_code=404,
            detail={"success": False, "message": "Patient not found", "data": None, "meta": None}
        )
    return patient


@router.post("", summary="Tambah data lansia")
async def create_patient(
    patient_data: PatientCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    try:
        data = patient_data.model_dump()
        # Otomatis set caregiver_id dari user yang login
        data["caregiver_id"] = current_user.get("id")

        patient = Patient(**data)
        db.add(patient)
        db.commit()
        db.refresh(patient)
        return success_response(
            data={"patient": PatientResponse.model_validate(patient).model_dump()},
            message="Patient created successfully"
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})


@router.get("", summary="List lansia milik caregiver yang login")
async def get_patients(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    search: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    try:
        caregiver_id = current_user.get("id")
        role = current_user.get("role", "user")

        # Admin lihat semua, user biasa hanya miliknya
        query = db.query(Patient)
        if role != "admin":
            query = query.filter(Patient.caregiver_id == caregiver_id)

        if search:
            query = query.filter(Patient.name.ilike(f"%{search}%"))

        total = query.count()
        patients = query.offset((page - 1) * limit).limit(limit).all()
        return success_response(
            data={"patients": [PatientResponse.model_validate(p).model_dump() for p in patients]},
            meta={"total": total, "page": page, "limit": limit, "totalPages": -(-total // limit)}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})


@router.get("/{patient_id}", summary="Detail lansia (hanya milik caregiver)")
async def get_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    patient = _get_owned_patient(patient_id, current_user, db)
    return success_response(data={"patient": PatientResponse.model_validate(patient).model_dump()})


@router.put("/{patient_id}", summary="Update data lansia + upload foto")
async def update_patient(
    patient_id: int,
    name: Optional[str] = None,
    birth_date: Optional[str] = None,
    gender: Optional[str] = None,
    address: Optional[str] = None,
    blood_type: Optional[str] = None,
    medical_notes: Optional[str] = None,
    photo: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    patient = _get_owned_patient(patient_id, current_user, db)
    try:
        if name is not None:
            patient.name = name
        if birth_date is not None:
            from datetime import date
            patient.birth_date = date.fromisoformat(birth_date)
        if gender is not None:
            patient.gender = gender
        if address is not None:
            patient.address = address
        if blood_type is not None:
            patient.blood_type = blood_type
        if medical_notes is not None:
            patient.medical_notes = medical_notes
        # caregiver_id TIDAK boleh diubah dari request body (keamanan)

        if photo:
            if patient.photo_url:
                await delete_file_from_gcs(patient.photo_url)
            content = await photo.read()
            photo_url = await upload_file_to_gcs(content, photo.filename, photo.content_type, "patients")
            patient.photo_url = photo_url

        db.commit()
        db.refresh(patient)
        return success_response(
            data={"patient": PatientResponse.model_validate(patient).model_dump()},
            message="Patient updated successfully"
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})


@router.delete("/{patient_id}", summary="Hapus data lansia (hanya milik caregiver)")
async def delete_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    patient = _get_owned_patient(patient_id, current_user, db)
    try:
        if patient.photo_url:
            await delete_file_from_gcs(patient.photo_url)
        db.delete(patient)
        db.commit()
        return success_response(data={"id": patient_id}, message="Patient deleted successfully")
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})


@router.post("/{patient_id}/photo", summary="Upload foto pasien")
async def upload_patient_photo(
    patient_id: int,
    photo: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    patient = _get_owned_patient(patient_id, current_user, db)
    try:
        if patient.photo_url:
            await delete_file_from_gcs(patient.photo_url)
        content = await photo.read()
        photo_url = await upload_file_to_gcs(content, photo.filename, photo.content_type, "patients")
        patient.photo_url = photo_url
        db.commit()
        db.refresh(patient)
        return success_response(
            data={"patient": PatientResponse.model_validate(patient).model_dump()},
            message="Photo uploaded successfully"
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail={"success": False, "message": f"Error uploading photo: {str(e)}", "data": None, "meta": None}
        )
