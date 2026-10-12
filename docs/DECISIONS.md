# Cal Application - Architecture & Design Decisions (DECISIONS.md)

This log records default decisions, options evaluated, chosen paths, reasons, and the impact if changed, adhering to Section 5 of the specification.

---

## 1. App Identity & Target Platform
- **Context:** App naming and bundle identifier.
- **Options:** `com.example.cal` vs custom production domain.
- **Decision:** Use application name **Cal** and default applicationId / bundle identifier `com.example.cal`.
- **Reason:** Safe default per spec; easy to rename before app store submission.
- **Impact if changed:** Must update Android `build.gradle`, iOS Bundle ID, and migration scripts.

---

## 2. Platform Support & Verification Priority
- **Context:** Host environment is Windows 11 with Android SDK tools and desktop/web Flutter runtimes; no native macOS runner available.
- **Options:** Emulate iOS or verify Android / Web / headless test suites.
- **Decision:** Android and headless Dart/Flutter verification as primary; iOS build marked `PERLU-UJI-LIVE` until macOS host is available.
- **Reason:** Windows host cannot build IPA/Xcode project natively; Flutter test and Android emulator can fully verify Dart code and business logic.
- **Impact if changed:** None for business logic; iOS packaging requires macOS runner.

---

## 3. UI Language & Localization
- **Context:** Target market is Indonesia with potential international expansion.
- **Options:** Hardcoded Indonesian strings vs Flutter ARB (`intl`) localization.
- **Decision:** All user-facing strings managed via ARB localization files with Indonesian (`id`) as default locale and fallback to English (`en`).
- **Reason:** Fulfills Section 5 requirement; cleanly supports Indonesian food items, serving units (centong, potong, piring, sdm), and future English localization.
- **Impact if changed:** High refactoring effort if hardcoded later.

---

## 4. Age Gate & Demographic Safety
- **Context:** Health and diet app compliance.
- **Options:** 13+ vs 18+.
- **Decision:** Minimum age requirement is strictly 18 years old validated on registration and profile setup.
- **Reason:** Protect minors from improper caloric restriction; adhere strictly to safety rules in Section 5 & 8.
- **Impact if changed:** Legal compliance and safety policy violations.

---

## 5. Nutrition Calculation Formula
- **Context:** Standardized BMR and TDEE estimation method.
- **Options:** Harris-Benedict vs Mifflin–St Jeor vs Katch-McArdle.
- **Decision:** **Mifflin–St Jeor** formula with PAL (Physical Activity Level) multipliers and safe deficit/surplus boundaries (max ±500–750 kcal/day, floor 1200 kcal for women, 1500 kcal for men).
- **Reason:** Recognized by the American Dietetic Association as the most accurate non-clinical formula; documented in `docs/NUTRITION_RULES.md`.
- **Impact if changed:** Calculations adjust across user onboarding and dashboard.

---

## 6. AI Provider Interface & Fallback Strategy
- **Context:** No production AI API keys are configured in local environment variables.
- **Options:** Block until key provided vs build behind interface with Fake/Mock provider for dev/testing.
- **Decision:** Clean abstraction interface (`VisionProvider`, `TextProvider`) with full input/output JSON schema validation. Automated tests use structured mock responses; live calls require `GEMINI_API_KEY`, `OPENAI_API_KEY`, or `ANTHROPIC_API_KEY` in server `.env` and are tagged `PERLU-UJI-LIVE`.
- **Reason:** Decoupled architecture, zero hardcoded credentials, testable in CI/local offline.
- **Impact if changed:** Any provider can be plugged in without changing domain logic.

---

## 7. Backend Stack & Database Engine
- **Context:** Need robust, type-safe API with relational data integrity for workouts, food logs, leaderboards, and social feeds.
- **Options:** Node.js Express TypeScript + PostgreSQL vs Supabase vs Go.
- **Decision:** **Node.js (v22) + Express + TypeScript + PostgreSQL 18** with SQL migrations, Zod validation, JWT access & refresh token rotation, Docker Compose for containerized dev, and native local PostgreSQL fallback.
- **Reason:** Fully matches Section 5 specification; PostgreSQL 18 is already installed and running on port 5432 locally.
- **Impact if changed:** High backend architecture refactoring.

---

## 8. Mobile State Management & Offline Queue
- **Context:** Flutter state management, routing, secure credentials, and offline food/workout logging.
- **Options:** Bloc vs Riverpod; SharedPreferences vs FlutterSecureStorage; Sqflite vs Drift.
- **Decision:** **flutter_riverpod**, **go_router**, **dio**, **flutter_secure_storage**, and local offline mutation queue with idempotency keys (`idempotency_key` UUIDv4).
- **Reason:** Riverpod provides testable, compile-safe dependency injection; offline queue ensures logs and active gym sessions are never lost on network drops.
- **Impact if changed:** Fundamental Flutter architecture choice.

---

## 9. Design System & Theming
- **Context:** Modern, premium fitness app aesthetic based on UI/UX Pro Max intelligence.
- **Options:** Generic dark neon vs Flat/Material 3 hybrid with tailored emerald/orange/indigo tokens.
- **Decision:** Calm modern dark mode default with crisp light mode support; Emerald Green (`#10B981`) primary brand, Vibrant Orange (`#F97316`) for carbs & gym energy, Indigo (`#6366F1`) for protein, Amber (`#F59E0B`) for fat. Touch targets ≥ 48dp on Android and spacing ≥ 8dp.
- **Reason:** Prevents visual clutter; aligns with UI/UX Pro Max recommendations; promotes focus and health clarity.
- **Impact if changed:** Visual tokens and widget theming.

---

## 10. Indonesian Natural Language Food Parsing & Local Unit Normalization
- **Context:** Indonesian users log meals in colloquial language with local household units (e.g., "nasi 2 centong", "2 butir telur rebus", "tempe 3 potong").
- **Options:** Rely solely on LLM vs regex entity extractor with standard gram conversion table.
- **Decision:** Hybrid approach: AI provider extracts entities with flexible prefix and postfix grammar support (`<qty> <unit> <food>` or `<food> <qty> <unit>`); code maps local units to gram weights (centong = 100g, potong = 50g, butir = 55g, sdm = 15g) and calculates nutrition deterministically from verified catalog.
- **Reason:** Complies with Section 3 rule: "Numbers calculated in code, not LLM". Transparent, reproducible, and verifiable.
- **Impact if changed:** Guarantees caloric integrity regardless of LLM hallucination.

---

## 11. AI Vision Transparency & Medical Safety Guardrails
- **Context:** Camera-based food logging and contextual AI nutrition coaching.
- **Options:** Present AI calorie estimates as authoritative vs prominent estimate badge and mandatory user review.
- **Decision:** Every food identified via AI vision displays a prominent "Estimasi AI" badge with confidence score and interactive portion adjuster. AI Coach chat includes strict medical disclaimers ("Bukan pengganti konsultasi medis"), enforces calorie floor limits, and rejects extreme crash dieting requests.
- **Reason:** Ethical AI principles and user safety; prevents unhealthy dietary behaviors.
- **Impact if changed:** Mitigates liability and provides superior UX trust.

---

## 12. Proportional Recipe Scaling & Direct Meal Logging
- **Context:** Indonesian healthy recipes have fixed base servings (e.g. 2 servings), but users consume varying portion sizes (0.5x, 1.5x, 2x).
- **Options:** Client-only math vs unified backend API endpoint calculating proportional macros and scaled ingredient gram quantities.
- **Decision:** Scaled dynamically via `/recipes/:id?servings=N` and `/recipes/:id/log-to-meal`; macros and gram weights scaled precisely using ratio `servings / baseServings`; logging automatically writes snapshot record to `meal_items` and updates user's daily totals.
- **Reason:** Ensures data integrity, offline sync compatibility, and seamless UX between recipe discovery and daily food tracking.
- **Impact if changed:** Consistency across mobile and backend logs.

---

## 13. AI Meal Plan Generation with Safe Caloric Tolerance Bounds
- **Context:** Automated daily meal planner selecting from database recipes.
- **Options:** Random recipe picker vs intelligent macro allocation (25% breakfast, 40% lunch, 35% dinner) with portion multipliers.
- **Decision:** Intelligent constraint satisfaction: algorithm selects closest candidate recipes for each meal slot and computes portion multipliers (0.5 increments) to keep total planned calories strictly within ±15% of user's personal caloric target.
- **Reason:** Real-world recipes alone often fall short of full daily TDEE without appropriate portion sizing; guarantees balanced, attainable nutrition without extreme deficits.
- **Impact if changed:** Ensures plans adhere to safety floors (1200/1500 kcal).

---

## 14. Gym Tracking, Brzycki 1RM Formula & Automatic PR Detection
- **Context:** Gym session tracking requires calculating 1 Rep Max (1RM) and personal records (PRs) accurately across various repetition counts.
- **Options:** Epley formula vs Brzycki formula vs Lander formula.
- **Decision:** **Brzycki formula** `1RM = weight / (1.0278 - 0.0278 * reps)`, rounded to 1 decimal place. Whenever a logged set achieves higher weight or higher estimated 1RM than prior records for that specific exercise, the system flags `is_personal_record: true` and updates `personal_records` table immediately.
- **Reason:** Brzycki is the gold standard for reps between 1 and 12, preventing wild overestimations at moderate rep ranges; automatic PR triggers delightful feedback (confetti/badge) without manual tallying.
- **Impact if changed:** Affects PR notifications and strength progression analytics.

---

## 15. AI Workout Routine Generation & Database Persistence
- **Context:** User requests AI-driven workout plan tailored to target goal (hypertrophy, strength, endurance), training frequency (2-5 days/week), and available equipment.
- **Options:** Ephemeral chat advice vs structured routine creation stored directly in user's routine catalog.
- **Decision:** AI routine generator formats output strictly into validated schema matching `workout_routines` and `routine_exercises`, automatically persisting the routine to PostgreSQL so the user can immediately start live sessions from it.
- **Reason:** Bridging advice into immediate action eliminates manual re-typing and fits cleanly into the unified mobile tracker.
- **Impact if changed:** User would have to manually recreate suggested exercises set-by-set.

---

## 16. Body Progress Tracking, Weight Delta & Profile Synchronization
- **Context:** Logging body weight and circumference measurements (waist, chest, hips).
- **Options:** Keep measurements isolated from user profile vs synchronize `users.weight_kg` with latest entry.
- **Decision:** Whenever a new measurement is logged, `users.weight_kg` is updated to keep Mifflin-St Jeor TDEE calculations fresh. `weight_delta` is computed deterministically comparing the latest entry against the baseline (earliest) record.
- **Reason:** Prevents calorie targets from becoming stale as the user progresses in their fitness journey; ensures holistic consistency between gym and nutrition modules.
- **Impact if changed:** TDEE calculations would drift from actual body weight.

---

## 17. Gamification XP Idempotency, 500 XP Daily Cap & Progressive Level Curve
- **Context:** Rewarding healthy habits (meal logging +10 XP, gym workout +25 XP, community post +15 XP) without opening loopholes for spam, botting, or gaming the system.
- **Options:** Uncapped XP vs strict daily cap with audit logs and idempotent keys.
- **Decision:** Every XP transaction requires an `idempotency_key` stored in `xp_audit_logs`. A strict ceiling of **500 XP/day** per user is enforced at the database level. User level is calculated deterministically via progressive square curve `Level = Math.floor(Math.sqrt(total_xp / 100)) + 1`.
- **Reason:** Anti-cheat integrity; protects leaderboard fairness; encourages consistent daily engagement over unhealthy binge-activity.
- **Impact if changed:** Uncapped XP invites spam logging; altering formula resets user levels.

---

## 18. Weekly Leaderboard Canonical Timezone (Asia/Jakarta) & Fair Tie-Breaking
- **Context:** Global leaderboards across different user timezones can cause unfair reset windows and rank disputes.
- **Options:** Individual user timezone resets vs single canonical server timezone.
- **Decision:** **Asia/Jakarta** is chosen as the canonical timezone for all weekly leaderboard aggregations (`date_trunc('week', NOW() AT TIME ZONE 'Asia/Jakarta')`). Tie-breaking is deterministic: users with identical XP totals are ranked by `MIN(created_at)` (who achieved the XP earlier).
- **Reason:** Fulfills Section 5 specifications; provides complete transparency and mathematical predictability.
- **Impact if changed:** Changing timezone changes reset boundaries for all active users.

---

## 19. Non-Shaming Notifications & Health Sensor Graceful Fallback
- **Context:** Push/local reminder copy (meals, hydration, workouts) and step tracking sensors (Health Connect / Apple Health).
- **Options:** Aggressive urgency notifications vs gentle, supportive (*non-shaming*) copy.
- **Decision:** All default reminders use supportive, positive framing (e.g., "Satu gelas air sejuk akan menyegarkan kembali konsentrasi tubuhmu", "Waktunya sarapan bergizi untuk mengisi energimu"). Sensor health abstraction is guarded with safe dev/headless fallbacks, never crashing if permissions or hardware sensors are absent.
- **Reason:** Promotes long-term mental well-being and positive relationship with food/fitness; prevents runtime crashes on diverse devices.
- **Impact if changed:** Crucial for user retention and ethical fitness app compliance.

---

## 20. Deterministic Weekly Habit Insights & Safe Absence vs Zero Distinction
- **Context:** Aggregating 7-day progress metrics (average calories, protein adherence, gym volume load) and generating habit insight narratives.
- **Options:** Pure LLM generation on every request vs deterministic relational math with structured rule-based narrative synthesis.
- **Decision:** All metrics (average calories, delta percentage, protein adherence %, and volume load) are computed via strict SQL aggregation over `meal_logs`, `meal_log_items`, and `workout_sessions`. The system **strictly distinguishes between "no data logged" (`daysLogged = 0`, `hasData = false`) and "zero values logged"**. Narratives are generated via verifiable mathematical thresholds, ensuring recommendations are 100% truthful, safe, and reproducible.
- **Reason:** Adheres to Section 3 rule ("Numbers calculated in code, not LLM"). Eliminates hallucinated calorie reports, guarantees instant latency, and provides transparent coaching feedback.
- **Impact if changed:** Fundamental data integrity principle for user trust and safety.





