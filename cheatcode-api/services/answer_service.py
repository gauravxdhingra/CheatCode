from __future__ import annotations
import re
from db.supabase import get_supabase
from models.problem import AnswerResult


def _normalize(answer: str) -> str:
    """
    Normalize a code answer for comparison.
    - Strip leading/trailing whitespace
    - Collapse all internal whitespace to single space
    - Normalize spaces around operators: +, -, *, /, =, <, >, !, [, ], (, )
    - Lowercase
    """
    s = answer.strip()
    # Collapse all whitespace sequences to single space
    s = re.sub(r'\s+', ' ', s)
    # Remove spaces around operators and brackets
    s = re.sub(r'\s*([\+\-\*\/\=\<\>\!\[\]\(\)\,])\s*', r'\1', s)
    # Lowercase
    s = s.lower()
    return s


def validate_answer(user_answer: str, correct_answer: str) -> tuple[bool, str, str]:
    """
    Returns (is_correct, normalized_user, normalized_correct)
    """
    norm_user = _normalize(user_answer)
    norm_correct = _normalize(correct_answer)
    return norm_user == norm_correct, norm_user, norm_correct


async def get_correct_answer(problem_id: str) -> str | None:
    db = get_supabase()
    resp = (
        db.table("problems")
        .select("code_lines")
        .eq("id", problem_id)
        .single()
        .execute()
    )
    code_lines = resp.data.get("code_lines", [])
    for line in code_lines:
        if isinstance(line, dict) and line.get("is_blank"):
            return line.get("blank_answer")
    return None


async def get_solved_today(user_id: str) -> list[dict]:
    db = get_supabase()
    from datetime import date
    today = date.today().isoformat()

    resp = (
        db.table("user_problem_state")
        .select("problem_id, solved_at, problems(title, company_badge, pattern, difficulty)")
        .eq("user_id", user_id)
        .eq("status", "solved")
        .gte("solved_at", today)
        .execute()
    )
    return resp.data


async def mark_unsolved(user_id: str, problem_id: str) -> None:
    db = get_supabase()
    db.table("user_problem_state").update(
        {"status": "unseen", "solved_at": None}
    ).eq("user_id", user_id).eq("problem_id", problem_id).execute()

    # Also decrement pattern progress
    problem_resp = (
        db.table("problems")
        .select("pattern_id")
        .eq("id", problem_id)
        .single()
        .execute()
    )
    pattern_id = problem_resp.data.get("pattern_id")
    if not pattern_id:
        return

    progress_resp = (
        db.table("user_pattern_progress")
        .select("*")
        .eq("user_id", user_id)
        .eq("pattern_id", pattern_id)
        .execute()
    )
    if progress_resp.data:
        row = progress_resp.data[0]
        new_solved = max(0, row["times_solved"] - 1)
        db.table("user_pattern_progress").update(
            {
                "times_solved": new_solved,
                "owned": new_solved >= 5,
            }
        ).eq("user_id", user_id).eq("pattern_id", pattern_id).execute()
