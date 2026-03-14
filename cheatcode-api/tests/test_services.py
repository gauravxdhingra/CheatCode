import pytest
from unittest.mock import patch, MagicMock
from datetime import date, timedelta
from services.progress_service import update_streak
from models.problem import StreakResponse


# ── Streak tests ──────────────────────────────────────────────────────────────

def _mock_user(last_active: str | None, streak: int, solved_today: int = 0):
    return {
        "streak": streak,
        "last_active_date": last_active,
        "solved_today": solved_today,
    }


@pytest.mark.asyncio
async def test_streak_first_solve():
    """First time a user solves anything — streak starts at 1."""
    today = date.today().isoformat()

    with patch("services.progress_service.get_supabase") as mock_db:
        db = MagicMock()
        mock_db.return_value = db

        db.table.return_value.select.return_value.eq.return_value \
            .single.return_value.execute.return_value.data = \
            _mock_user(last_active=None, streak=0)

        db.table.return_value.update.return_value.eq.return_value.execute \
            .return_value = MagicMock()

        result = await update_streak("user-123")

    assert result.streak == 1
    assert result.solved_today == 1
    assert result.message == "First solve. Let's go."


@pytest.mark.asyncio
async def test_streak_consecutive_day():
    """Solving the day after last active extends the streak."""
    yesterday = (date.today() - timedelta(days=1)).isoformat()

    with patch("services.progress_service.get_supabase") as mock_db:
        db = MagicMock()
        mock_db.return_value = db

        db.table.return_value.select.return_value.eq.return_value \
            .single.return_value.execute.return_value.data = \
            _mock_user(last_active=yesterday, streak=5)

        db.table.return_value.update.return_value.eq.return_value.execute \
            .return_value = MagicMock()

        result = await update_streak("user-123")

    assert result.streak == 6
    assert result.solved_today == 1
    assert "6 day streak" in result.message


@pytest.mark.asyncio
async def test_streak_same_day():
    """Solving twice on the same day only increments solved_today."""
    today = date.today().isoformat()

    with patch("services.progress_service.get_supabase") as mock_db:
        db = MagicMock()
        mock_db.return_value = db

        db.table.return_value.select.return_value.eq.return_value \
            .single.return_value.execute.return_value.data = \
            _mock_user(last_active=today, streak=3, solved_today=2)

        db.table.return_value.update.return_value.eq.return_value.execute \
            .return_value = MagicMock()

        result = await update_streak("user-123")

    assert result.streak == 3       # unchanged
    assert result.solved_today == 3  # incremented


@pytest.mark.asyncio
async def test_streak_broken():
    """Missing a day resets streak to 1."""
    two_days_ago = (date.today() - timedelta(days=2)).isoformat()

    with patch("services.progress_service.get_supabase") as mock_db:
        db = MagicMock()
        mock_db.return_value = db

        db.table.return_value.select.return_value.eq.return_value \
            .single.return_value.execute.return_value.data = \
            _mock_user(last_active=two_days_ago, streak=10)

        db.table.return_value.update.return_value.eq.return_value.execute \
            .return_value = MagicMock()

        result = await update_streak("user-123")

    assert result.streak == 1
    assert result.message == "Streak reset. Start fresh."


# ── Feed algorithm tests ──────────────────────────────────────────────────────

from services.feed_service import _days_until


def test_days_until_future():
    future = (date.today() + timedelta(days=5)).isoformat()
    assert _days_until(future) == 5


def test_days_until_past():
    past = (date.today() - timedelta(days=3)).isoformat()
    assert _days_until(past) == 0


def test_days_until_none():
    assert _days_until(None) is None


def test_days_until_invalid():
    assert _days_until("not-a-date") is None
