from __future__ import annotations
import logging
from fastapi import APIRouter, HTTPException
from models.problem import AnswerValidation, AnswerResult, ProblemStatus
from services.answer_service import (
    validate_answer,
    get_correct_answer,
    get_solved_today,
    mark_unsolved,
)
from services.progress_service import update_progress

logger = logging.getLogger("cheatcode.answers")
router = APIRouter(prefix="/answers", tags=["answers"])


@router.post("/{user_id}/validate", response_model=AnswerResult)
async def validate_user_answer(user_id: str, body: AnswerValidation):
    logger.info(f"Validating answer user={user_id} problem={body.problem_id} answer='{body.user_answer[:40]}'")
    try:
        correct_answer, title = await get_correct_answer(body.problem_id)
        if not correct_answer:
            logger.warning(f"Problem not found id={body.problem_id}")
            raise HTTPException(status_code=404, detail="Problem or answer not found")

        is_correct, norm_user, norm_correct = await validate_answer(
            body.user_answer, correct_answer, title
        )

        logger.info(f"Answer {'✓ correct' if is_correct else '✗ wrong'} user={user_id} problem={body.problem_id}")

        if is_correct:
            await update_progress(
                user_id=user_id,
                problem_id=body.problem_id,
                status=ProblemStatus.solved,
                time_to_solve=None,
                hints_used=0,
            )

        return AnswerResult(
            correct=is_correct,
            normalized_user=norm_user,
            normalized_correct=norm_correct,
            message="Correct!" if is_correct else f"Expected: {correct_answer}",
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Validation error user={user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/solved-today")
async def fetch_solved_today(user_id: str):
    logger.info(f"Fetching solved today user={user_id}")
    try:
        data = await get_solved_today(user_id)
        logger.info(f"Solved today: {len(data)} problems for user={user_id}")
        return data
    except Exception as e:
        logger.error(f"Solved today error user={user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/unsolved/{problem_id}")
async def unsolve_problem(user_id: str, problem_id: str):
    logger.info(f"Marking unsolved user={user_id} problem={problem_id}")
    try:
        await mark_unsolved(user_id, problem_id)
        return {"ok": True}
    except Exception as e:
        logger.error(f"Unsolved error user={user_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
