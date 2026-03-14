from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum


class UserRole(str, Enum):
    student = "student"
    professional = "professional"
    competitive = "competitive"


class ProblemStatus(str, Enum):
    unseen = "unseen"
    skipped = "skipped"
    attempted = "attempted"
    solved = "solved"
    vaulted = "vaulted"


class CodeLine(BaseModel):
    text: str
    is_blank: bool = False
    blank_answer: Optional[str] = None


class Problem(BaseModel):
    id: str
    title: str
    company: str
    company_badge: str
    pattern: str
    difficulty: int
    code_lines: list[CodeLine]
    hints: list[str]
    explanation: str
    brute_force: str
    optimised: str
    brute_complexity: str
    optimised_complexity: str
    related_patterns: list[str]


class FeedResponse(BaseModel):
    problems: list[Problem]
    cached_until: datetime


class ProgressUpdate(BaseModel):
    problem_id: str
    status: ProblemStatus
    time_to_solve: Optional[int] = None  # seconds
    hints_used: int = 0


class StreakResponse(BaseModel):
    streak: int
    solved_today: int
    message: Optional[str] = None


class UserProfile(BaseModel):
    id: str
    role: UserRole
    streak: int
    interview_date: Optional[str] = None
    created_at: str
