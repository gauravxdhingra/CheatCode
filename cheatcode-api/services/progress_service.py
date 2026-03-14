from __future__ import annotations
from datetime import date, timedelta
from db.supabase import get_supabase
from models.problem import ProblemStatus, StreakResponse

OWNED_THRESHOLD = 5


async def update_progress(
    user_id: str,
    problem_id: str,
    status: ProblemStatus,
    time_to_solve: int | None,
    hints_used: int,
) -> None:
    db = get_supabase()

    # Upsert user_problem_state
    db.table("user_problem_state").upsert(
        {
            "user_id": user_id,
            "problem_id": problem_id,
            "status": status.value,
            "hints_used": hints_used,
            "time_to_solve": time_to_solve,
            "solved_at": date.today().isoformat() if status == ProblemStatus.solved else None,
        },
        on_conflict="user_id,problem_id",
    ).execute()

    # If solved, update pattern progress
    if status == ProblemStatus.solved:
        await _update_pattern_progress(user_id, problem_id)
        await update_streak(user_id)


async def _update_pattern_progress(user_id: str, problem_id: str) -> None:
    db = get_supabase()

    # Get problem's pattern_id
    problem_resp = (
        db.table("problems")
        .select("pattern_id")
        .eq("id", problem_id)
        .single()
        .execute()
    )
    pattern_id = problem_resp.data["pattern_id"]

    # Fetch existing progress
    existing_resp = (
        db.table("user_pattern_progress")
        .select("*")
        .eq("user_id", user_id)
        .eq("pattern_id", pattern_id)
        .execute()
    )
    existing = existing_resp.data

    if existing:
        row = existing[0]
        new_solved = row["times_solved"] + 1
        db.table("user_pattern_progress").update(
            {
                "times_solved": new_solved,
                "times_encountered": row["times_encountered"] + 1,
                "owned": new_solved >= OWNED_THRESHOLD,
                "last_seen_at": date.today().isoformat(),
            }
        ).eq("user_id", user_id).eq("pattern_id", pattern_id).execute()
    else:
        db.table("user_pattern_progress").insert(
            {
                "user_id": user_id,
                "pattern_id": pattern_id,
                "times_solved": 1,
                "times_encountered": 1,
                "owned": False,
                "last_seen_at": date.today().isoformat(),
            }
        ).execute()


async def update_streak(user_id: str) -> StreakResponse:
    db = get_supabase()

    user_resp = (
        db.table("users")
        .select("streak, last_active_date, solved_today")
        .eq("id", user_id)
        .single()
        .execute()
    )
    user = user_resp.data
    today = date.today()
    last_active = user.get("last_active_date")

    current_streak = user.get("streak", 0)
    solved_today = user.get("solved_today", 0)
    message = None

    if last_active:
        last_date = date.fromisoformat(last_active)
        if last_date == today:
            # Already active today — just increment solved count
            solved_today += 1
        elif last_date == today - timedelta(days=1):
            # Consecutive day — extend streak
            current_streak += 1
            solved_today = 1
            message = f"🔥 {current_streak} day streak!"
        else:
            # Streak broken
            current_streak = 1
            solved_today = 1
            message = "Streak reset. Start fresh."
    else:
        # First time
        current_streak = 1
        solved_today = 1
        message = "First solve. Let's go."

    db.table("users").update(
        {
            "streak": current_streak,
            "last_active_date": today.isoformat(),
            "solved_today": solved_today,
        }
    ).eq("id", user_id).execute()

    return StreakResponse(
        streak=current_streak,
        solved_today=solved_today,
        message=message,
    )


async def get_pattern_progress(user_id: str) -> list[dict]:
    db = get_supabase()

    resp = (
        db.table("user_pattern_progress")
        .select("*, patterns(name, description)")
        .eq("user_id", user_id)
        .order("times_solved", desc=True)
        .execute()
    )
    return resp.data
