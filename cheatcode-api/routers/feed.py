from __future__ import annotations
import logging
from fastapi import APIRouter, HTTPException
from datetime import datetime, timedelta
from models.problem import FeedResponse
from services.feed_service import get_feed, get_vault

logger = logging.getLogger("cheatcode.feed")
router = APIRouter(prefix="/feed", tags=["feed"])


@router.get("/{user_id}", response_model=FeedResponse)
async def fetch_feed(user_id: str, limit: int = 20):
    logger.info(f"Fetching feed for user={user_id} limit={limit}")
    try:
        problems = await get_feed(user_id, limit)
        logger.info(f"Feed returned {len(problems)} problems for user={user_id}")
        return FeedResponse(
            problems=problems,
            cached_until=datetime.utcnow() + timedelta(hours=24),
        )
    except Exception as e:
        logger.error(f"Feed error for user={user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/vault")
async def fetch_vault(user_id: str):
    logger.info(f"Fetching vault for user={user_id}")
    try:
        problems = await get_vault(user_id)
        logger.info(f"Vault returned {len(problems)} problems for user={user_id}")
        return problems
    except Exception as e:
        logger.error(f"Vault error for user={user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
