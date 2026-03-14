from __future__ import annotations
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from db.supabase import get_supabase
from models.problem import UserRole

router = APIRouter(prefix="/users", tags=["users"])


class CreateUserRequest(BaseModel):
    email: str
    role: UserRole = UserRole.student
    interview_date: str | None = None


@router.post("/")
async def create_user(body: CreateUserRequest):
    try:
        db = get_supabase()
        resp = db.table("users").insert({
            "email": body.email,
            "role": body.role.value,
            "interview_date": body.interview_date,
        }).execute()
        return resp.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}")
async def get_user(user_id: str):
    try:
        db = get_supabase()
        resp = db.table("users").select("*").eq("id", user_id).single().execute()
        return resp.data
    except Exception as e:
        raise HTTPException(status_code=404, detail="User not found")
