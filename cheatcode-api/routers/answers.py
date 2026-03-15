from __future__ import annotations
from fastapi import APIRouter, HTTPException
from models.problem import AnswerValidation, AnswerResult
from services.answer_service import (
    validate_answer,
    get_correct_answer,
    get_solved_today,
    mark_unsolved,
)
from services.progress_service import update_progress, update_streak
from models.problem import ProblemStatus

router = APIRouter(prefix="/answers", tags=["answers"])


@router.post("/{user_id}/validate", response_model=AnswerResult)
async def validate_user_answer(user_id: str, body: AnswerValidation):
    try:
        correct_answer = await get_correct_answer(body.problem_id)
        if not correct_answer:
            raise HTTPException(status_code=404, detail="Problem or answer not found")

        is_correct, norm_user, norm_correct = validate_answer(
            body.user_answer, correct_answer
        )

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
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/solved-today")
async def fetch_solved_today(user_id: str):
    try:
        return await get_solved_today(user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/unsolved/{problem_id}")
async def unsolve_problem(user_id: str, problem_id: str):
    try:
        await mark_unsolved(user_id, problem_id)
        return {"ok": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
