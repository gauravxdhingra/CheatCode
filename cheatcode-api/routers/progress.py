from fastapi import APIRouter, HTTPException
from models.problem import ProgressUpdate, StreakResponse
from services.progress_service import (
    update_progress,
    update_streak,
    get_pattern_progress,
)

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
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/streak", response_model=StreakResponse)
async def fetch_streak(user_id: str):
    try:
        return await update_streak(user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/patterns")
async def fetch_pattern_progress(user_id: str):
    try:
        return await get_pattern_progress(user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
