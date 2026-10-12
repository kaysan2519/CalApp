# Cal Project - Agent Operating Guidelines & Rules

## 1. Project Mission & Identity
- **Project:** Cal - Modern Fitness, Nutrition, Gym, and Community App (Flutter + Node.js/PostgreSQL).
- **Execution Mode:** AUTONOMOUS (Fase 1 → Fase 9 without stopping unless credentials/destructive blocker occurs).
- **Languages:** UI default Bahasa Indonesia (via ARB localization); Code, identifiers, comments, and git commit messages in English; Assistant communication with user in casual Indonesian.

## 2. Definition of Done (DOD) per Feature
A feature is **TERVERIFIKASI** only when:
1. End-to-end flow verified: UI → state → API → validation & auth → DB → UI. Persists across app restarts.
2. Calculations mathematically correct and verified with realistic real-world test inputs.
3. States handled: loading, empty, error, success; missing credentials or network drops produce helpful user-facing errors.
4. Automated tests written and passed; results logged in `docs/PROGRESS.md`.
5. No fake dummy data or hardcoded mock replacing production code in finished features.
*Other statuses:* `BELUM`, `SEBAGIAN`, and `PERLU-UJI-LIVE` (documented in `docs/MANUAL_TEST.md`).

## 3. Architecture & Safety Rules
- **Numbers calculated in code, not LLM:** LLMs only extract, summarize, and advise. Strict JSON schema validation for all AI outputs.
- **Provider Abstraction:** All external services (AI, mailer, storage, push notifications, Health APIs) sit behind interfaces with clean development fallbacks.
- **Security:** Password hash with argon2/bcrypt; short-lived JWT + rotating refresh tokens; strict server-side authorization for all private resources; no health or secret data in logs.
- **Nutrition Boundaries:** Floor limits (min 1200 kcal female, 1500 kcal male); conservative weight change rates (max 0.5–1 kg/week); Mifflin-St Jeor formula documented in `docs/NUTRITION_RULES.md`.
- **Database:** PostgreSQL with SQL migrations; UTC timestamps with user timezone stored; no mock repository for integration tests.

## 4. UI/UX Standards
- Design system inspired by UI/UX Pro Max intelligence (`docs/DESIGN.md`).
- Minimum touch target: 48dp on Android, 44pt on iOS; minimum 8dp spacing between interactive elements.
- Bottom navigation limited to 4 core tabs.
- Clean semantic tokens: Emerald Green primary, energetic Orange for carbs/workouts, Indigo for protein, Amber for fat. Dark mode default with light mode support.

## 5. Progress Tracking & Git
- Keep `docs/PROGRESS.md`, `docs/DECISIONS.md`, and `docs/MANUAL_TEST.md` updated at every phase.
- Feature branch: `feat/cal-build`. Small, meaningful commits.
