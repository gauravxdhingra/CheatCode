# cheatcode()

> *Technical interviews are a pattern recognition game disguised as an intelligence test. We reverse engineered the patterns.*

A mobile-first coding challenge app that gets busy engineers interview-ready in 10 minutes a day. Bite-sized problems, real patterns, no fluff.

---

## What it is

cheatcode() is the TikTok of Leetcode — short, focused coding challenges served in a daily feed. Instead of grinding full problems for hours, users solve one critical line of code at a time, building pattern recognition through repetition.

**Core loop:**
1. Open app → see a problem with one blank line
2. Fill in the critical insight
3. Get instant feedback + pattern explanation + brute force vs optimised comparison
4. Next problem

**Who it's for:** Software engineers preparing for interviews who have 10 minutes a day, not 2 hours.

---

## Architecture

```
┌─────────────────┐     HTTPS      ┌─────────────────┐     SQL      ┌──────────────┐
│   Flutter App   │ ────────────▶  │  FastAPI Backend │ ──────────▶ │  Supabase    │
│   (Android/iOS) │                │  (Railway)       │             │  (PostgreSQL)│
└─────────────────┘                └─────────────────┘             └──────────────┘
```

### Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart) |
| Backend | Python FastAPI |
| Database | Supabase (PostgreSQL) |
| Hosting | Railway (backend) |
| Auth | Google Sign-In |
| CI/CD | Railway auto-deploy on push |

---

## Project Structure

```
/
├── cheatcode-ui/          # Flutter mobile app
│   └── lib/
│       ├── main.dart
│       ├── models/
│       │   └── problem.dart
│       ├── providers/
│       │   └── app_provider.dart
│       ├── screens/
│       │   ├── feed_screen.dart       # Main screen — problem attempt
│       │   ├── onboarding_screen.dart
│       │   ├── vault_screen.dart      # Saved EOD problems
│       │   ├── progress_screen.dart   # Pattern ownership
│       │   ├── history_screen.dart    # All solved problems
│       │   └── solved_today_screen.dart
│       ├── services/
│       │   ├── api_service.dart       # Backend API calls
│       │   └── auth_service.dart      # Google Sign-In + session
│       ├── theme/
│       │   └── app_theme.dart
│       └── widgets/
│           ├── dry_run_visualizer.dart
│           └── problem_card.dart
│
└── cheatcode-api/         # FastAPI backend
    ├── main.py             # App entry point + middleware
    ├── config.py           # Environment settings
    ├── Dockerfile
    ├── requirements.txt
    ├── .github/
    │   └── workflows/
    │       └── deploy.yml  # CI/CD pipeline
    ├── db/
    │   └── supabase.py     # Supabase client singleton
    ├── models/
    │   └── problem.py      # Pydantic schemas
    ├── routers/
    │   ├── users.py        # POST /users/, GET /users/{id}
    │   ├── feed.py         # GET /feed/{user_id}
    │   ├── progress.py     # POST /progress/{user_id}
    │   └── answers.py      # POST /answers/{user_id}/validate
    ├── services/
    │   ├── feed_service.py      # Feed algorithm
    │   ├── progress_service.py  # Streak + pattern tracking
    │   └── answer_service.py    # Validation + AI fallback
    └── tests/
        └── test_services.py
```

---

## Database Schema

```sql
users               — id, email, name, role, streak, solved_today, interview_date
problems            — id, title, company, pattern, difficulty, code_lines (jsonb),
                      hints (jsonb), wrong_options (jsonb), problem_statement,
                      brute_force, optimised, explanation
patterns            — id, name, description
user_problem_state  — user_id, problem_id, status, hints_used, time_to_solve, solved_at
user_pattern_progress — user_id, pattern_id, times_solved, times_encountered, owned
```

**Problem statuses:** `unseen` → `attempted` → `solved` / `skipped` / `vaulted`

---

## API Reference

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/users/` | Create or upsert user |
| `GET` | `/users/{id}` | Get user profile |
| `GET` | `/feed/{user_id}` | Get personalised problem feed |
| `POST` | `/progress/{user_id}` | Update problem status |
| `GET` | `/progress/{user_id}/streak` | Get streak + solved today |
| `POST` | `/answers/{user_id}/validate` | Validate answer (with AI fallback) |
| `GET` | `/answers/{user_id}/solved-today` | Get today's solved problems |
| `POST` | `/answers/{user_id}/unsolved/{problem_id}` | Mark problem as unsolved |
| `GET` | `/health` | Health check |

Auto-generated docs available at `/docs` (Swagger) and `/redoc`.

---

## Feed Algorithm

```
1. Fetch user role + interview date
2. Fetch user's weak patterns (solved < 5 times)
3. Fetch problems already solved/skipped by user
4. Filter by difficulty based on role:
   - student      → [1, 2]
   - professional → [1, 2, 3]
   - competitive  → [2, 3]
5. If interview < 7 days away → bump difficulty to [2, 3]
6. Sort: weak patterns first → difficulty match
7. Fallback: if filter returns empty → serve all active unseen problems
```

---

## Answer Validation

Answers go through two layers:

1. **Local normalization** — strips whitespace, normalizes operators, lowercases. `nums[i-k]` and `nums[i - k]` both match.
2. **AI fallback** — if normalization fails, asks Claude Haiku whether the answer is logically equivalent. Handles creative but correct solutions.

---

## Local Development

### Backend

```bash
cd cheatcode-api
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # fill in Supabase credentials
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

API docs: [http://localhost:8000/docs](http://localhost:8000/docs)

### Flutter

```bash
cd cheatcode-ui
flutter pub get
flutter run
```

**Important:** Update `baseUrl` in `lib/services/api_service.dart`:
- Local testing: `http://YOUR_MAC_IP:8000` (find with `ipconfig getifaddr en0`)
- Production: your Railway URL

For Android physical device, also ensure `AndroidManifest.xml` has:
```xml
android:usesCleartextTraffic="true"
```

---

## Database Setup

1. Create a project at [supabase.com](https://supabase.com)
2. Run schema SQL files in order in SQL Editor:
   - `query_seed_30_fixed.sql` — patterns + 30 problems
   - `query_problem_statements.sql` — problem descriptions
3. Copy Project URL and service_role key to `.env`

---

## Deployment

### Backend (Railway)

1. Connect GitHub repo at [railway.app](https://railway.app)
2. Set root directory to `cheatcode-api`
3. Add environment variables:
   ```
   SUPABASE_URL=...
   SUPABASE_SERVICE_KEY=...
   APP_ENV=production
   ```
4. Railway auto-deploys on every push to `main`

### Flutter

```bash
# Android release build
flutter build apk --release

# Upload to Google Play Console
```

---

## Content

30 problems across 5 patterns, mapped to Neetcode 150:

| Pattern | Problems | Companies |
|---|---|---|
| Sliding Window | 6 | Amazon, Google, Meta, Microsoft |
| Two Pointer | 6 | Amazon, Google, Meta, Facebook |
| Binary Search | 6 | Google, Amazon, Meta |
| Hash Map | 6 | Google, Meta, Amazon |
| Dynamic Programming | 6 | Amazon, Google |

Each problem has:
- Problem statement
- Code with one critical blank
- 3 progressive hints
- 4 multiple choice options (1 correct + 3 plausible wrong answers from DB)
- Pattern explanation
- Brute force vs optimised comparison with complexity
- Interactive dry run visualizer

---

## Roadmap

- [ ] Push notifications — daily challenge reminder
- [ ] Friend leaderboard — weekly solved count
- [ ] Company-specific problem sets
- [ ] Interview timeline mode — auto-schedule by date
- [ ] Community problem submissions
- [ ] Paywall — Pro tier (unlimited hints, vault, company sets)
- [ ] Web version

---

## Environment Variables

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_SERVICE_KEY` | Supabase service role key (never expose client-side) |
| `APP_ENV` | `development` or `production` |

---

## Running Tests

```bash
cd cheatcode-api
pytest tests/ -v
```

Tests cover streak logic, feed algorithm edge cases, and answer normalization.

---

## Why "cheatcode"

Interviews test pattern recognition, not raw intelligence. Every technical interview draws from a pool of ~20 fundamental patterns. Once you internalize those patterns, you recognize them regardless of how the problem is disguised.

That's not cheating. That's preparation. But it feels illegal.

---

*Built by an engineer who got tired of being afraid of interviews.*
