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

