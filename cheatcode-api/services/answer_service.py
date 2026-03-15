from __future__ import annotations
import re
import httpx
from db.supabase import get_supabase
from models.problem import AnswerResult


# ── Normalization ─────────────────────────────────────────────────────────────

def _normalize(answer: str) -> str:
    s = answer.strip()
    s = re.sub(r'\s+', ' ', s)
    s = re.sub(r'\s*([\+\-\*\/\=\<\>\!\[\]\(\)\,\;\{\}])\s*', r'\1', s)
    s = s.lower()
    return s


def validate_answer_local(user_answer: str, correct_answer: str) -> tuple[bool, str, str]:
    norm_user = _normalize(user_answer)
    norm_correct = _normalize(correct_answer)
    return norm_user == norm_correct, norm_user, norm_correct


# ── AI validation fallback ────────────────────────────────────────────────────

async def validate_with_ai(
    user_answer: str,
    correct_answer: str,
    problem_title: str,
) -> bool:
    """
    Ask Claude if the user's answer is logically equivalent to the correct answer.
    Used only when local normalization returns False.
    """
    prompt = f"""You are a code answer validator for a coding challenge app.

Problem: {problem_title}
Correct answer: {correct_answer}
User's answer: {user_answer}

Are these two code expressions logically equivalent for this problem context?
Reply with ONLY "yes" or "no". No explanation."""

    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            resp = await client.post(
                "https://api.anthropic.com/v1/messages",
                headers={
                    "x-api-key": "",  # handled by proxy in Claude artifacts
                    "anthropic-version": "2023-06-01",
                    "content-type": "application/json",
                },
                json={
                    "model": "claude-haiku-4-5-20251001",
                    "max_tokens": 10,
                    "messages": [{"role": "user", "content": prompt}],
                },
            )
            if resp.status_code == 200:
                text = resp.json()["content"][0]["text"].strip().lower()
                return text.startswith("yes")
    except Exception:
        pass
    return False


# ── Main validation ───────────────────────────────────────────────────────────

async def validate_answer(
    user_answer: str,
    correct_answer: str,
    problem_title: str = "",
) -> tuple[bool, str, str]:
    is_correct, norm_user, norm_correct = validate_answer_local(
        user_answer, correct_answer
    )

    # If local normalization fails, try AI
    if not is_correct and user_answer.strip():
        ai_result = await validate_with_ai(user_answer, correct_answer, problem_title)
        if ai_result:
            is_correct = True

    return is_correct, norm_user, norm_correct


async def get_correct_answer(problem_id: str) -> tuple[str | None, str]:
    """Returns (blank_answer, problem_title)"""
    db = get_supabase()
    resp = (
        db.table("problems")
        .select("code_lines, title")
        .eq("id", problem_id)
        .single()
        .execute()
    )
    title = resp.data.get("title", "")
    code_lines = resp.data.get("code_lines", [])
    for line in code_lines:
        if isinstance(line, dict) and line.get("is_blank"):
            return line.get("blank_answer"), title
    return None, title


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
            {"times_solved": new_solved, "owned": new_solved >= 5}
        ).eq("user_id", user_id).eq("pattern_id", pattern_id).execute()
