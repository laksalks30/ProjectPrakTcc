from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from app.services.db import get_db
from app.models.reminder import Reminder
from app.models.patient import Patient
from app.models.prescription import Prescription
from app.schemas.reminder import ReminderCreate, ReminderUpdate, ReminderResponse
from app.routers.auth_middleware import get_current_user

router = APIRouter(prefix="/reminders", tags=["Reminders"])


def success_response(data=None, message="Success", meta=None):
    return {"success": True, "message": message, "data": data, "meta": meta}


def reminder_to_dict(r: Reminder) -> dict:
    d = ReminderResponse.model_validate(r).model_dump()
    if r.patient:
        d["patient_name"] = r.patient.name
    if r.prescription and r.prescription.medication:
        d["medication_name"] = r.prescription.medication.name
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


def _get_owned_reminder(reminder_id: int, current_user: dict, db: Session) -> Reminder:
    caregiver_id = current_user.get("id")
    role = current_user.get("role", "user")

    reminder = db.query(Reminder).options(
        joinedload(Reminder.patient),
        joinedload(Reminder.prescription).joinedload(Prescription.medication)
    ).filter(Reminder.id == reminder_id).first()

    if not reminder:
        raise HTTPException(
            status_code=404,
            detail={"success": False, "message": "Reminder not found", "data": None, "meta": None}
        )

    if role != "admin" and reminder.patient.caregiver_id != caregiver_id:
        raise HTTPException(
            status_code=404,
            detail={"success": False, "message": "Reminder not found", "data": None, "meta": None}
        )
    return reminder


@router.post("", summary="Buat jadwal pengingat")
async def create_reminder(
    reminder_data: ReminderCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    # Validasi patient milik caregiver yang login
    _get_owned_patient(reminder_data.patient_id, current_user, db)

    # Validasi prescription milik patient tersebut
    prescription = db.query(Prescription).filter(
        Prescription.id == reminder_data.prescription_id,
        Prescription.patient_id == reminder_data.patient_id
    ).first()
    if not prescription:
        raise HTTPException(
            status_code=404,
            detail={"success": False, "message": "Prescription not found for this patient", "data": None, "meta": None}
        )

    try:
        reminder = Reminder(**reminder_data.model_dump())
        db.add(reminder)
        db.commit()
        db.refresh(reminder)

        reminder = db.query(Reminder).options(
            joinedload(Reminder.patient),
            joinedload(Reminder.prescription).joinedload(Prescription.medication)
        ).filter(Reminder.id == reminder.id).first()

        return success_response(
            data={"reminder": reminder_to_dict(reminder)},
            message="Reminder created successfully"
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})


@router.get("/patient/{patient_id}", summary="Jadwal reminder per lansia (hanya milik caregiver)")
async def get_reminders_by_patient(
    patient_id: int,
    is_active: bool = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    _get_owned_patient(patient_id, current_user, db)

    query = db.query(Reminder).options(
        joinedload(Reminder.patient),
        joinedload(Reminder.prescription).joinedload(Prescription.medication)
    ).filter(Reminder.patient_id == patient_id)

    if is_active is not None:
        query = query.filter(Reminder.is_active == is_active)

    total = query.count()
    reminders = query.offset((page - 1) * limit).limit(limit).all()

    return success_response(
        data={"reminders": [reminder_to_dict(r) for r in reminders]},
        meta={"total": total, "page": page, "limit": limit, "totalPages": -(-total // limit)}
    )


@router.put("/{reminder_id}", summary="Update jadwal reminder")
async def update_reminder(
    reminder_id: int,
    reminder_data: ReminderUpdate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    reminder = _get_owned_reminder(reminder_id, current_user, db)

    try:
        update_data = reminder_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(reminder, key, value)

        db.commit()
        db.refresh(reminder)

        reminder = db.query(Reminder).options(
            joinedload(Reminder.patient),
            joinedload(Reminder.prescription).joinedload(Prescription.medication)
        ).filter(Reminder.id == reminder_id).first()

        return success_response(
            data={"reminder": reminder_to_dict(reminder)},
            message="Reminder updated successfully"
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})


@router.delete("/{reminder_id}", summary="Hapus reminder")
async def delete_reminder(
    reminder_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    reminder = _get_owned_reminder(reminder_id, current_user, db)

    try:
        db.delete(reminder)
        db.commit()
        return success_response(data={"id": reminder_id}, message="Reminder deleted successfully")
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})
