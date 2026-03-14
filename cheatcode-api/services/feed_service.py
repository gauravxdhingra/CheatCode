from __future__ import annotations
from datetime import date, datetime
from db.supabase import get_supabase
from models.problem import Problem, UserRole


DIFFICULTY_BY_ROLE = {
    UserRole.student: [1, 2],
    UserRole.professional: [2, 3],
    UserRole.competitive: [3],
}

OWNED_THRESHOLD = 5  # solves needed to "own" a pattern
FEED_SIZE = 20


async def get_feed(user_id: str, limit: int = FEED_SIZE) -> list[Problem]:
    db = get_supabase()

    # 1. Fetch user profile
    user_resp = db.table("users").select("*").eq("id", user_id).single().execute()
    user = user_resp.data

    role = UserRole(user["role"])
    interview_date = user.get("interview_date")
    days_to_interview = _days_until(interview_date)

    # 2. Fetch user's weak patterns (encountered but not owned)
    progress_resp = (
        db.table("user_pattern_progress")
        .select("pattern_id, times_solved, times_encountered")
        .eq("user_id", user_id)
        .lt("times_solved", OWNED_THRESHOLD)
        .execute()
    )
    weak_pattern_ids = [r["pattern_id"] for r in progress_resp.data]

    # 3. Fetch problems already seen by user
    seen_resp = (
        db.table("user_problem_state")
        .select("problem_id")
        .eq("user_id", user_id)
        .in_("status", ["solved", "skipped"])
        .execute()
    )
    seen_ids = [r["problem_id"] for r in seen_resp.data]

    # 4. Determine difficulty range
    # If interview is imminent (< 7 days), bump difficulty up
    difficulties = DIFFICULTY_BY_ROLE[role]
    if days_to_interview is not None and days_to_interview < 7:
        difficulties = [max(difficulties), 3]  # push harder

    # 5. Fetch candidate problems
    query = (
        db.table("problems")
        .select("*")
        .eq("active", True)
        .in_("difficulty", difficulties)
    )

    if seen_ids:
        query = query.not_.in_("id", seen_ids)

    problems_resp = query.limit(limit * 2).execute()  # fetch extra to sort
    problems = problems_resp.data

    # 6. Sort: weak patterns first, then unseen patterns, then everything else
    def sort_key(p):
        pattern_id = p.get("pattern_id")
        is_weak = pattern_id in weak_pattern_ids
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
        delta = (target - date.today()).days
        return max(delta, 0)
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
        code_lines=row["code_lines"],
        hints=row["hints"],
        explanation=row["explanation"],
        brute_force=row["brute_force"],
        optimised=row["optimised"],
        brute_complexity=row["brute_complexity"],
        optimised_complexity=row["optimised_complexity"],
        related_patterns=row.get("related_patterns", []),
    )
