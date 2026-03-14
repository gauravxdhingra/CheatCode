from fastapi import APIRouter, HTTPException
from datetime import datetime, timedelta
from models.problem import FeedResponse
from services.feed_service import get_feed, get_vault

router = APIRouter(prefix="/feed", tags=["feed"])


@router.get("/{user_id}", response_model=FeedResponse)
async def fetch_feed(user_id: str, limit: int = 20):
    try:
        problems = await get_feed(user_id, limit)
        return FeedResponse(
            problems=problems,
            cached_until=datetime.utcnow() + timedelta(hours=24),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/vault", response_model=list)
async def fetch_vault(user_id: str):
    try:
        return await get_vault(user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
