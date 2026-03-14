# cheatcode()

> Unfair advantage. Daily.

A TikTok-style coding interview prep app. 10 minutes a day. 30 days. Your next offer.

## MVP Features

- **Onboarding** — role selection (beginner / professional / competitive)
- **Swipeable feed** — problem cards with company, difficulty, pattern tags
- **Fill-the-critical-line mechanic** — not fill-in-blanks busywork, but the one line where the insight lives
- **Hint system** — 3 progressive hints, pull-to-reveal
- **Result screen** — correct answer, pattern explanation, where else you'll see it, pattern ownership progress
- **Vault** — one hard problem locked until you're ready
- **Streak tracking** — persisted via SharedPreferences
- **Pattern ownership** — tracks how many times you've solved each pattern (5 = owned)

## Setup

```bash
cd cheatcode
flutter pub get
flutter run
```

## Project Structure

```
lib/
  main.dart                    # Entry point
  theme.dart                   # Colors, typography
  models/
    problem.dart               # Problem model
  data/
    problems.dart              # Problem bank (seed data)
  providers/
    app_provider.dart          # State management (Provider)
  screens/
    onboarding/
      onboarding_screen.dart
    feed/
      feed_screen.dart
    result/
      result_screen.dart
    vault/
      vault_screen.dart
  widgets/
    problem_card.dart          # Core problem UI component
```

## Next Steps (Post-MVP)

- [ ] Interactive dry run (step-through code execution visualizer)
- [ ] Brute force → optimised evolution view
- [ ] AI tutor integration (explain wrong answers conversationally)
- [ ] Push notifications (daily challenge + vault drop)
- [ ] Backend + problem CMS (to scale beyond seed data)
- [ ] User accounts + leaderboard
- [ ] Interview timeline / goal setting
- [ ] Neetcode 150 problem set integration
- [ ] Answer fuzzy matching (handle spacing/formatting variations)

## Brand

- Name: **cheatcode()**
- Tagline: *"We probably shouldn't be telling you this."*
- Positioning: Confidence machine. Not a quiz app.
- Color: #00FF88 on #080808
