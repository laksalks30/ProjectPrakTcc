from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date, datetime, timedelta
from app.services.db import get_db
from app.models.patient import Patient
from app.models.prescription import Prescription
from app.models.reminder import Reminder
from app.models.log import MedicationLog
from app.routers.auth_middleware import get_current_user

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


def success_response(data=None, message="Success", meta=None):
    return {"success": True, "message": message, "data": data, "meta": meta}


@router.get("/stats", summary="Statistik dashboard (hanya data milik caregiver)")
async def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    try:
        caregiver_id = current_user.get("id")
        role = current_user.get("role", "user")
        today = date.today()
        thirty_days_ago = today - timedelta(days=30)
        today_start = datetime.combine(today, datetime.min.time())
        today_end = datetime.combine(today, datetime.max.time())

        # Query patients — filter by caregiver kecuali admin
        patient_query = db.query(Patient)
        if role != "admin":
            patient_query = patient_query.filter(Patient.caregiver_id == caregiver_id)

        # Ambil daftar patient_id milik caregiver ini
        patient_ids = [p.id for p in patient_query.all()]

        # Total patients
        total_patients = len(patient_ids)

        # Active prescriptions (hanya milik patient caregiver ini)
        active_prescriptions = db.query(func.count(Prescription.id)).filter(
            Prescription.patient_id.in_(patient_ids),
            Prescription.status == "active"
        ).scalar()

        # Active reminders
        active_reminders = db.query(func.count(Reminder.id)).filter(
            Reminder.patient_id.in_(patient_ids),
            Reminder.is_active == True
        ).scalar()

        # Total & taken logs in last 30 days
        total_logs_30d = db.query(func.count(MedicationLog.id)).filter(
            MedicationLog.patient_id.in_(patient_ids),
            MedicationLog.scheduled_at >= thirty_days_ago
        ).scalar()

        taken_logs_30d = db.query(func.count(MedicationLog.id)).filter(
            MedicationLog.patient_id.in_(patient_ids),
            MedicationLog.scheduled_at >= thirty_days_ago,
            MedicationLog.status.in_(["taken", "late"])
        ).scalar()

        compliance_rate = 0.0
        if total_logs_30d > 0:
            compliance_rate = round((taken_logs_30d / total_logs_30d) * 100, 2)

        # Today's reminders
        today_weekday = today.strftime("%A").lower()
        today_reminders_query = db.query(Reminder).filter(
            Reminder.patient_id.in_(patient_ids),
            Reminder.is_active == True,
            Reminder.days_of_week.like(f"%{today_weekday}%")
        ).all()

        today_reminders = []
        for reminder in today_reminders_query:
            reminder_dict = {
                "id": reminder.id,
                "patient_id": reminder.patient_id,
                "prescription_id": reminder.prescription_id,
                "scheduled_time": str(reminder.scheduled_time),
                "notes": reminder.notes,
            }
            if reminder.patient:
                reminder_dict["patient_name"] = reminder.patient.name
            if reminder.prescription and reminder.prescription.medication:
                reminder_dict["medication_name"] = reminder.prescription.medication.name
                reminder_dict["dosage"] = reminder.prescription.dosage

            log = db.query(MedicationLog).filter(
                MedicationLog.reminder_id == reminder.id,
                MedicationLog.scheduled_at >= today_start,
                MedicationLog.scheduled_at <= today_end
            ).first()
            reminder_dict["logged_today"] = log is not None
            reminder_dict["today_status"] = log.status if log else None
            today_reminders.append(reminder_dict)

        # Status breakdown last 30 days
        status_breakdown = db.query(
            MedicationLog.status,
            func.count(MedicationLog.id).label("count")
        ).filter(
            MedicationLog.patient_id.in_(patient_ids),
            MedicationLog.scheduled_at >= thirty_days_ago
        ).group_by(MedicationLog.status).all()

        status_dict = {row.status: row.count for row in status_breakdown}

        # Weekly compliance trend (last 7 days)
        weekly_trend = []
        for i in range(6, -1, -1):
            day = today - timedelta(days=i)
            day_start = datetime.combine(day, datetime.min.time())
            day_end = datetime.combine(day, datetime.max.time())

            day_total = db.query(func.count(MedicationLog.id)).filter(
                MedicationLog.patient_id.in_(patient_ids),
                MedicationLog.scheduled_at >= day_start,
                MedicationLog.scheduled_at <= day_end
            ).scalar()

            day_taken = db.query(func.count(MedicationLog.id)).filter(
                MedicationLog.patient_id.in_(patient_ids),
                MedicationLog.scheduled_at >= day_start,
                MedicationLog.scheduled_at <= day_end,
                MedicationLog.status.in_(["taken", "late"])
            ).scalar()

            weekly_trend.append({
                "date": day.isoformat(),
                "day": day.strftime("%a"),
                "total": day_total,
                "taken": day_taken,
                "rate": round((day_taken / day_total * 100), 2) if day_total > 0 else 0
            })

        # Per-patient compliance (hanya milik caregiver ini)
        patient_compliance = []
        patients = patient_query.limit(10).all()
        for patient in patients:
            p_total = db.query(func.count(MedicationLog.id)).filter(
                MedicationLog.patient_id == patient.id,
                MedicationLog.scheduled_at >= thirty_days_ago
            ).scalar()
            p_taken = db.query(func.count(MedicationLog.id)).filter(
                MedicationLog.patient_id == patient.id,
                MedicationLog.scheduled_at >= thirty_days_ago,
                MedicationLog.status.in_(["taken", "late"])
            ).scalar()
            rate = round((p_taken / p_total * 100), 2) if p_total > 0 else 0
            patient_compliance.append({
                "patient_id": patient.id,
                "patient_name": patient.name,
                "total_logs": p_total,
                "taken_logs": p_taken,
                "compliance_rate": rate
            })

        patient_compliance.sort(key=lambda x: x["compliance_rate"])

        return success_response(
            data={
                "overview": {
                    "total_patients": total_patients,
                    "active_prescriptions": active_prescriptions,
                    "active_reminders": active_reminders,
                    "compliance_rate_30d": compliance_rate,
                    "total_logs_30d": total_logs_30d,
                    "taken_logs_30d": taken_logs_30d,
                },
                "status_breakdown": status_dict,
                "today_reminders": today_reminders,
                "weekly_trend": weekly_trend,
                "patient_compliance": patient_compliance
            },
            message="Dashboard stats retrieved successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail={"success": False, "message": str(e), "data": None, "meta": None})
