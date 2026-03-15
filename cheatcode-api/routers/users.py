from __future__ import annotations
import logging
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from db.supabase import get_supabase
from models.problem import UserRole

logger = logging.getLogger("cheatcode.users")
router = APIRouter(prefix="/users", tags=["users"])


class CreateUserRequest(BaseModel):
    email: str
    role: UserRole = UserRole.student
    name: Optional[str] = None
    interview_date: Optional[str] = None


@router.post("/")
async def create_user(body: CreateUserRequest):
    logger.info(f"Creating/upserting user email={body.email} role={body.role}")
    try:
        db = get_supabase()
        resp = db.table("users").upsert(
            {
                "email": body.email,
                "role": body.role.value,
                "name": body.name,
                "interview_date": body.interview_date,
            },
            on_conflict="email",
        ).execute()
        user = resp.data[0]
        logger.info(f"User upserted id={user['id']} email={body.email}")
        return user
    except Exception as e:
        logger.error(f"Create user error email={body.email}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/by-email/{email}")
async def get_user_by_email(email: str):
    logger.info(f"Looking up user by email={email}")
    try:
        db = get_supabase()
        resp = db.table("users").select("*").eq("email", email).single().execute()
        return resp.data
    except Exception as e:
        logger.warning(f"User not found email={email}: {e}")
        raise HTTPException(status_code=404, detail="User not found")


@router.get("/{user_id}")
async def get_user(user_id: str):
    logger.info(f"Looking up user id={user_id}")
    try:
        db = get_supabase()
        resp = db.table("users").select("*").eq("id", user_id).single().execute()
        return resp.data
    except Exception as e:
        logger.warning(f"User not found id={user_id}: {e}")
        raise HTTPException(status_code=404, detail="User not found")
