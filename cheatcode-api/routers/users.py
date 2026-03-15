from __future__ import annotations
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from db.supabase import get_supabase
from models.problem import UserRole

router = APIRouter(prefix="/users", tags=["users"])


class CreateUserRequest(BaseModel):
    email: str
    role: UserRole = UserRole.student
    name: Optional[str] = None
    interview_date: Optional[str] = None


@router.post("/")
async def create_user(body: CreateUserRequest):
    try:
        db = get_supabase()

        # Upsert — if email exists return existing user
        resp = db.table("users").upsert(
            {
                "email": body.email,
                "role": body.role.value,
                "name": body.name,
                "interview_date": body.interview_date,
            },
            on_conflict="email",
        ).execute()

        return resp.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/by-email/{email}")
async def get_user_by_email(email: str):
    try:
        db = get_supabase()
        resp = (
            db.table("users")
            .select("*")
            .eq("email", email)
            .single()
            .execute()
        )
        return resp.data
    except Exception as e:
        raise HTTPException(status_code=404, detail="User not found")


@router.get("/{user_id}")
async def get_user(user_id: str):
    try:
        db = get_supabase()
        resp = (
            db.table("users")
            .select("*")
            .eq("id", user_id)
            .single()
            .execute()
        )
        return resp.data
    except Exception as e:
        raise HTTPException(status_code=404, detail="User not found")
