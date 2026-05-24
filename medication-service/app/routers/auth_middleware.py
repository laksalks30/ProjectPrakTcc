# ============ FILE: medication-service/app/routers/auth_middleware.py ============
import os
import jwt
from fastapi import HTTPException, Header
from typing import Optional
from dotenv import load_dotenv

load_dotenv()

JWT_SECRET = os.getenv("JWT_SECRET", "default_secret_change_me")


async def get_current_user(authorization: Optional[str] = Header(None)) -> dict:
    """Verify JWT token from Authorization header."""
    if not authorization:
        raise HTTPException(
            status_code=401,
            detail={"success": False, "message": "Access denied. No token provided.", "data": None, "meta": None}
        )
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail={"success": False, "message": "Invalid token format. Use: Bearer <token>", "data": None, "meta": None}
        )
    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=401,
            detail={"success": False, "message": "Token has expired. Please login again.", "data": None, "meta": None}
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=401,
            detail={"success": False, "message": "Invalid token.", "data": None, "meta": None}
        )
