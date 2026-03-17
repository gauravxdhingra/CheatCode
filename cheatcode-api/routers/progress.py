from __future__ import annotations
import logging
from fastapi import APIRouter, HTTPException
from models.problem import ProgressUpdate, StreakResponse
from services.progress_service import (
    update_progress,
    update_streak,
    get_pattern_progress,
)
from db.supabase import get_supabase

logger = logging.getLogger("cheatcode.progress")
router = APIRouter(prefix="/progress", tags=["progress"])


@router.post("/{user_id}")
async def mark_progress(user_id: str, body: ProgressUpdate):
    try:
        await update_progress(
            user_id=user_id,
            problem_id=body.problem_id,
            status=body.status,
            time_to_solve=body.time_to_solve,
            hints_used=body.hints_used,
        )
        return {"ok": True}
    except Exception as e:
        logger.error(f"Progress error user={user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/streak", response_model=StreakResponse)
async def fetch_streak(user_id: str):
    try:
        return await update_streak(user_id)
    except Exception as e:
        logger.error(f"Streak error user={user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/patterns")
async def fetch_pattern_progress(user_id: str):
    try:
        return await get_pattern_progress(user_id)
    except Exception as e:
        logger.error(f"Pattern progress error user={user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/solved-ids")
async def get_solved_ids(user_id: str):
    logger.info(f"Fetching solved IDs for user={user_id}")
    try:
        db = get_supabase()
        resp = (
            db.table("user_problem_state")
            .select("problem_id")
            .eq("user_id", user_id)
            .eq("status", "solved")
            .execute()
        )
        ids = [r["problem_id"] for r in resp.data]
        logger.info(f"Found {len(ids)} solved problems for user={user_id}")
        return ids
    except Exception as e:
        logger.error(f"Solved IDs error user={user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))