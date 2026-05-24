from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from typing import Optional
from app.services.db import get_db
from app.models.prescription import Prescription
from app.models.patient import Patient
from app.models.medication import Medication
from app.schemas.prescription import PrescriptionCreate, PrescriptionUpdate, PrescriptionResponse
from app.routers.auth_middleware import get_current_user

router = APIRouter(prefix="/prescriptions", tags=["Prescriptions"])


def success_response(data=None, message="Success", meta=None):
    return {"success": True, "message": message, "data": data, "meta": meta}


def prescription_to_dict(p: Prescription) -> dict:
    d = PrescriptionResponse.model_validate(p).model_dump()
    if p.patient:
        d["patient_name"] = p.patient.name
    if p.medication:
        d["medication_name"] = p.medication.name
    return d


def _get_owned_patient(patient_id: int, current_user: dict, db: Session) -> Patient:
    """Pastikan patient milik caregiver yang sedang login."""
    caregiver_id = current_user.get("id")
    role = current_user.get("role", "user")

    query = db.query(Patient).filter(Patient.id == patient_id)
    if role != "admin":
        query = query.filter(Patient.caregiver_id == caregiver_id)

    patient = query.first()
    if not patient:
        raise HTTPException(
            status_code=404,
            detail={"success": False, "message": "Patient not found", "data": None, "meta": None}
        )
    return patient


def _get_owned_prescription(prescription_id: int, current_user: dict, db: Session) -> Prescription:
    """Pastikan prescription milik pasien yang dimiliki caregiver yang login."""
    caregiver_id = current_user.get("id")
    role = current_user.get("role", "user")

    prescription = db.query(Prescription).options(
        joinedload(Prescription.patient),
        joinedload(Prescription.medication)
    ).filter(Prescription.id == prescription_id).first()

    if not prescription:
        raise HTTPException(
            status_code=404,
            detail={"success": False, "message": "Prescription not found", "data": None, "meta": None}
        )

    # Cek kepemilikan lewat patient.caregiver_id
    if role != "admin" and prescription.patient.caregiver_id != caregiver_id:
        raise HTTPException(
            status_code=404,
            detail={"success": False, "message": "Prescription not found", "data": None, "meta": None}
        )
    return prescription


@router.post("", summary="Tambah resep untuk lansia")
async def create_prescription(
    prescription_data: PrescriptionCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    # Validasi patient milik caregiver yang login
    _get_owned_patient(prescription_data.patient_id, current_user, db)

    # Validasi medication ada
    medication = db.query(Medication).filter(Medication.id == prescription_data.medication_id).first()
    if not medication:
        raise HTTPException(status_code=404, detail={"success": False, "message": "Medication not found", "data": None, "meta": None})

    try:
        prescription = Prescription(**prescription_data.model_dump())
        db.add(prescription)
        db.commit()
        db.refresh(prescription)

        prescription = db.query(Prescription).options(
            joinedload(Prescription.patient),
            joinedload(Prescription.medication)
        ).filter(Prescription.id == prescription.id).first()

        return success_response(
            data={"prescription": prescription_to_dict(prescription)},
            message="Prescription created successfully"
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})


@router.get("/patient/{patient_id}", summary="Resep per lansia (hanya milik caregiver)")
async def get_prescriptions_by_patient(
    patient_id: int,
    status: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    # Validasi patient milik caregiver yang login
    _get_owned_patient(patient_id, current_user, db)

    query = db.query(Prescription).options(
        joinedload(Prescription.patient),
        joinedload(Prescription.medication)
    ).filter(Prescription.patient_id == patient_id)

    if status:
        query = query.filter(Prescription.status == status)

    total = query.count()
    prescriptions = query.offset((page - 1) * limit).limit(limit).all()

    return success_response(
        data={"prescriptions": [prescription_to_dict(p) for p in prescriptions]},
        meta={"total": total, "page": page, "limit": limit, "totalPages": -(-total // limit)}
    )


@router.put("/{prescription_id}", summary="Update resep")
async def update_prescription(
    prescription_id: int,
    prescription_data: PrescriptionUpdate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    prescription = _get_owned_prescription(prescription_id, current_user, db)

    try:
        update_data = prescription_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(prescription, key, value)

        db.commit()
        db.refresh(prescription)

        prescription = db.query(Prescription).options(
            joinedload(Prescription.patient),
            joinedload(Prescription.medication)
        ).filter(Prescription.id == prescription_id).first()

        return success_response(
            data={"prescription": prescription_to_dict(prescription)},
            message="Prescription updated successfully"
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})


@router.delete("/{prescription_id}", summary="Hapus resep")
async def delete_prescription(
    prescription_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    prescription = _get_owned_prescription(prescription_id, current_user, db)

    try:
        db.delete(prescription)
        db.commit()
        return success_response(data={"id": prescription_id}, message="Prescription deleted successfully")
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})
