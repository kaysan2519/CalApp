# Cal - API Contract & Endpoints Specification (docs/API_CONTRACT.md)

Base URL: `/api/v1`  
All responses follow the unified envelope standard.

---

## 1. Unified Response Envelope

### Success Response:
```json
{
  "success": true,
  "data": { ... },
  "message": "Operasi berhasil"
}
```

### Error Response:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Deskripsi kesalahan ramah pengguna",
    "details": [
      { "field": "age", "message": "Usia minimal 18 tahun" }
    ]
  }
}
```

Standard Error Codes:
- `UNAUTHORIZED` (401)
- `FORBIDDEN` (403)
- `NOT_FOUND` (404)
- `VALIDATION_ERROR` (422)
- `RATE_LIMITED` (429)
- `INTERNAL_SERVER_ERROR` (500)

---

## 2. Core Endpoint Summary

### Auth & Account (`/auth`)
- `POST /auth/register` — Register user (email, password, name, age 18–120, heightCm, weightKg; demographic data has no client defaults).
- `POST /auth/login` — Authenticate user, returns short-lived accessToken (15m) + refreshToken (7d).
- `POST /auth/refresh` — Rotate refresh token, returns new pair.
- `POST /auth/logout` — Revoke refresh token.
- `DELETE /auth/account` — Hard delete account and cascading personal data (GDPR/UU PDP).
- `GET /auth/export` — Export user data as comprehensive JSON archive.

### Profile & Nutrition Target (`/profile`)
- `GET /profile` — Fetch current user profile.
- `PUT /profile` — Update demographics, onboarding preferences, and `onboardingCompleted`; recalculate Mifflin-St Jeor targets unless manually overridden. Optional fields include `targetWeightKg`, `trainingExperience`, `trainingDaysPerWeek`, `trainingSchedule`, `availableEquipment`, `foodPreferences`, `allergies`, `dietaryRestrictions`, and `activityLimitations`.
- `GET /profile/targets` — Get current nutrition targets (calories, protein, carbs, fat, water).
- `PUT /profile/targets` — Override targets manually.

### Nutrition & Food Logging (`/nutrition`)
- `GET /nutrition/foods/search?q=&barcode=` — Search verified food items with typo tolerance.
- `POST /nutrition/foods/custom` — Create custom user food item.
- `GET /nutrition/daily?date=YYYY-MM-DD` — Get daily nutrition summary, meal slots, and macro totals.
- `POST /nutrition/log` — Add food entry to a meal (idempotent, snapshots food nutrition).
- `PUT /nutrition/log/:itemId` — Update quantity/unit and recalculate entry calories.
- `DELETE /nutrition/log/:itemId` — Remove food entry and recalculate totals.
- `POST /nutrition/water` — Log water intake increment.
- `GET /nutrition/summary/weekly?startDate=YYYY-MM-DD` — 7-day average and consistency report.

### AI Nutrition & Vision (`/ai`)
- `POST /ai/food-vision` — Upload food image, returns parsed candidates + portions with confidence.
- `POST /ai/food-text` — Natural language text parser (e.g. "nasi 2 centong dan ayam bakar 150g").
- `POST /ai/coach/chat` — Context-aware AI coach query with server-side authorized tool execution.
- `POST /ai/workout-generator` — Generate customized workout routine based on equipment and split.
- `POST /ai/profile-recommendations` — Generate profile- and activity-context recommendations; calorie and macro targets are calculated by backend code and included with the AI response.

### Recipes & Meal Planner (`/recipes`)
- `GET /recipes` — Search Indonesian healthy recipes by tag, prep time, or calorie range.
- `GET /recipes/:id` — Recipe details with ingredient scaling.
- `POST /recipes/:id/log-to-meal` — Convert recipe serving directly into meal log.
- `GET /planner/daily?date=YYYY-MM-DD` — Structured daily meal + workout plan.

### Gym & Workouts (`/workouts`)
- `GET /workouts/exercises` — 80+ exercise library with muscle targets and equipment.
- `GET /workouts/routines` — User routines and multi-day split templates.
- `POST /workouts/routines` — Create or edit workout routine.
- `POST /workouts/sessions/start` — Start new live session.
- `POST /workouts/sessions/:id/sets` — Record set (reps, weight, RPE); auto-detects Personal Record.
- `POST /workouts/sessions/:id/complete` — Finish workout, calculate volume, award workout XP.
- `GET /workouts/history` — Workout session history and PR log.

### Gamification & Community (`/gamification`, `/community`)
- `GET /gamification/profile` — Current XP, level progress, current rank, rank thresholds, daily cap and XP history.
- `GET /gamification/leaderboard?period=weekly|global` — XP leaderboard, current user's position and rank gap when available.
- `POST /gamification/award-xp` — Request a fixed server-verified reward using `{ "eventCode": "meal_logged|workout_completed|community_post", "activityId": "<record id>" }`. Client XP amounts are ignored; the referenced activity must exist and belong to the authenticated user.
- `GET /gamification/achievements` — Unlocked and locked achievements.
- `GET /community/feed` — Group or public activity feed.
- `POST /community/posts` — Share workout milestone or achievement.
- `POST /community/posts/:id/react` — React to post (supportive emoji).
- `POST /community/reports` — Report inappropriate content or user.
