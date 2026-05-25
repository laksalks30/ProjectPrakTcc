# ============ FILE: medication-service/app/main.py ============
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import os
from dotenv import load_dotenv

load_dotenv()

from app.services.db import engine, Base
from app.models import Patient, Medication, Prescription, Reminder, MedicationLog
from app.routers import patients, medications, prescriptions, reminders, logs, dashboard

# Create all tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Medication API Service",
    description="Microservice API for Pengingat Minum Obat Lansia",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

from fastapi.staticfiles import StaticFiles
os.makedirs("static/uploads", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

# CORS Middleware
cors_origins = os.getenv("CORS_ORIGIN", "http://localhost:5173").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=".*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "message": f"Internal server error: {str(exc)}",
            "data": None,
            "meta": None
        }
    )


# Include routers
app.include_router(patients.router, prefix="/api")
app.include_router(medications.router, prefix="/api")
app.include_router(prescriptions.router, prefix="/api")
app.include_router(reminders.router, prefix="/api")
app.include_router(logs.router, prefix="/api")
app.include_router(dashboard.router, prefix="/api")


@app.get("/health")
async def health_check():
    return {
        "success": True,
        "message": "Medication Service is running",
        "data": {"service": "medication-service", "timestamp": __import__('datetime').datetime.utcnow().isoformat()},
        "meta": None
    }


@app.get("/")
async def root():
    return {
        "success": True,
        "message": "Welcome to Medication API Service",
        "data": {"docs": "/docs", "health": "/health"},
        "meta": None
    }
