from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from typing import Optional
from datetime import date
from app.services.db import get_db
from app.models.log import MedicationLog
from app.models.patient import Patient
from app.models.prescription import Prescription
from app.schemas.log import LogCreate, LogResponse
from app.routers.auth_middleware import get_current_user

router = APIRouter(prefix="/logs", tags=["Medication Logs"])


def success_response(data=None, message="Success", meta=None):
    return {"success": True, "message": message, "data": data, "meta": meta}


def log_to_dict(log: MedicationLog) -> dict:
    d = LogResponse.model_validate(log).model_dump()
    if log.patient:
        d["patient_name"] = log.patient.name
    if log.prescription and log.prescription.medication:
        d["medication_name"] = log.prescription.medication.name
    return d


def _get_owned_patient(patient_id: int, current_user: dict, db: Session) -> Patient:
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


@router.post("", summary="Catat status minum obat")
async def create_log(
    log_data: LogCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    # Validasi patient milik caregiver yang login
    _get_owned_patient(log_data.patient_id, current_user, db)

    # Validasi prescription ada dan milik patient tersebut
    prescription = db.query(Prescription).filter(
        Prescription.id == log_data.prescription_id,
        Prescription.patient_id == log_data.patient_id
    ).first()
    if not prescription:
        raise HTTPException(
            status_code=404,
            detail={"success": False, "message": "Prescription not found", "data": None, "meta": None}
        )

    try:
        log_dict = log_data.model_dump()
        if not log_dict.get("logged_by"):
            log_dict["logged_by"] = current_user.get("id")

        log = MedicationLog(**log_dict)
        db.add(log)
        db.commit()
        db.refresh(log)

        log = db.query(MedicationLog).options(
            joinedload(MedicationLog.patient),
            joinedload(MedicationLog.prescription).joinedload(Prescription.medication)
        ).filter(MedicationLog.id == log.id).first()

        return success_response(
            data={"log": log_to_dict(log)},
            message="Medication log recorded successfully"
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})


@router.get("/patient/{patient_id}", summary="Riwayat log per lansia (hanya milik caregiver)")
async def get_logs_by_patient(
    patient_id: int,
    status: Optional[str] = Query(None),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    # Validasi patient milik caregiver yang login
    _get_owned_patient(patient_id, current_user, db)

    query = db.query(MedicationLog).options(
        joinedload(MedicationLog.patient),
        joinedload(MedicationLog.prescription).joinedload(Prescription.medication)
    ).filter(MedicationLog.patient_id == patient_id)

    if status:
        query = query.filter(MedicationLog.status == status)
    if date_from:
        query = query.filter(MedicationLog.scheduled_at >= date_from)
    if date_to:
        from datetime import datetime, time
        end_dt = datetime.combine(date_to, time(23, 59, 59))
        query = query.filter(MedicationLog.scheduled_at <= end_dt)

    query = query.order_by(MedicationLog.scheduled_at.desc())
    total = query.count()
    logs = query.offset((page - 1) * limit).limit(limit).all()

    return success_response(
        data={"logs": [log_to_dict(log) for log in logs]},
        meta={"total": total, "page": page, "limit": limit, "totalPages": -(-total // limit)}
    )
