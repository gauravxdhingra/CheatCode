from __future__ import annotations
from datetime import date, datetime
from db.supabase import get_supabase
from models.problem import Problem, UserRole


DIFFICULTY_BY_ROLE = {
    UserRole.student: [1, 2],
    UserRole.professional: [1, 2, 3],  # include all for small sets
    UserRole.competitive: [2, 3],
}

OWNED_THRESHOLD = 5
FEED_SIZE = 20


async def get_feed(user_id: str, limit: int = FEED_SIZE) -> list[Problem]:
    db = get_supabase()

    # 1. Fetch user profile
    user_resp = db.table("users").select("*").eq("id", user_id).single().execute()
    user = user_resp.data

    role = UserRole(user["role"])
    interview_date = user.get("interview_date")
    days_to_interview = _days_until(interview_date)

    # 2. Fetch user's weak patterns
    progress_resp = (
        db.table("user_pattern_progress")
        .select("pattern_id, times_solved, times_encountered")
        .eq("user_id", user_id)
        .lt("times_solved", OWNED_THRESHOLD)
        .execute()
    )
    weak_pattern_ids = [r["pattern_id"] for r in progress_resp.data]

    # 3. Fetch problems already seen
    seen_resp = (
        db.table("user_problem_state")
        .select("problem_id")
        .eq("user_id", user_id)
        .in_("status", ["solved", "skipped"])
        .execute()
    )
    seen_ids = [r["problem_id"] for r in seen_resp.data]

    # 4. Difficulty range
    difficulties = DIFFICULTY_BY_ROLE[role]
    if days_to_interview is not None and days_to_interview < 7:
        difficulties = [2, 3]

    # 5. Fetch problems with difficulty filter
    query = (
        db.table("problems")
        .select("*")
        .eq("active", True)
        .in_("difficulty", difficulties)
    )
    if seen_ids:
        query = query.not_.in_("id", seen_ids)

    problems = query.limit(limit * 2).execute().data

    # 6. Fallback — if difficulty filter returns nothing, serve all active
    # Prevents "all caught up" on fresh install with small problem set
    if not problems:
        fallback = db.table("problems").select("*").eq("active", True)
        if seen_ids:
            fallback = fallback.not_.in_("id", seen_ids)
        problems = fallback.limit(limit * 2).execute().data

    # 7. Sort: weak patterns first
    def sort_key(p):
        is_weak = p.get("pattern_id") in weak_pattern_ids
        return (0 if is_weak else 1, p["difficulty"])

    problems.sort(key=sort_key)
    problems = problems[:limit]

    return [_map_to_model(p) for p in problems]


async def get_vault(user_id: str) -> list[Problem]:
    db = get_supabase()
    vault_resp = (
        db.table("user_problem_state")
        .select("problem_id, problems(*)")
        .eq("user_id", user_id)
        .eq("status", "vaulted")
        .execute()
    )
    return [_map_to_model(r["problems"]) for r in vault_resp.data]


def _days_until(interview_date: str | None) -> int | None:
    if not interview_date:
        return None
    try:
        target = date.fromisoformat(interview_date)
        return max((target - date.today()).days, 0)
    except ValueError:
        return None


def _map_to_model(row: dict) -> Problem:
    return Problem(
        id=row["id"],
        title=row["title"],
        company=row["company"],
        company_badge=row["company_badge"],
        pattern=row["pattern"],
        difficulty=row["difficulty"],
        problem_statement=row.get("problem_statement", ""),
        code_lines=row["code_lines"],
        hints=row["hints"],
        explanation=row["explanation"],
        brute_force=row["brute_force"],
        optimised=row["optimised"],
        brute_complexity=row["brute_complexity"],
        optimised_complexity=row["optimised_complexity"],
        related_patterns=row.get("related_patterns", []),
        wrong_options=row.get("wrong_options", []),
    )
