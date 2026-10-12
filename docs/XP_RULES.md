# Cal - Gamification & XP Rules (docs/XP_RULES.md)

This document specifies the rules for XP, streaks, levels, and achievements.

---

## 1. Principles & Safety Protections
- **No XP for Extreme Behaviors:** No XP is awarded for eating excessively below caloric floor, fasting unsafely, or overtraining beyond healthy thresholds.
- **Idempotency:** Every XP award is keyed by a unique `idempotency_key` (e.g., `user_id + ':' + event_type + ':' + date_or_resource_id`). Duplicate submissions return the existing award without double-counting.
- **Daily XP Cap:** Maximum **500 XP** per user per calendar day (Asia/Jakarta timezone) to prevent gaming and promote balanced consistency.
- **Audit Logging:** Every grant writes an immutable row into `xp_audit_logs`.

---

## 2. XP Reward Table

| Event Code | Action / Event | XP | Idempotency Key Format | Max Times / Day |
|:---|:---|:---:|:---|:---:|
| `LOG_MEAL` | Logging a meal (Breakfast, Lunch, Dinner, Snack) | 15 XP | `LOG_MEAL:{userId}:{date}:{mealType}` | 4 |
| `COMPLETE_DAILY_NUTRITION` | Logging at least 3 meals within caloric target range (±10%) | 40 XP | `COMPLETE_NUTRITION:{userId}:{date}` | 1 |
| `LOG_WATER_TARGET` | Reaching daily water target | 20 XP | `LOG_WATER:{userId}:{date}` | 1 |
| `COMPLETE_WORKOUT` | Completing a recorded gym workout session | 50 XP | `COMPLETE_WORKOUT:{userId}:{workoutId}` | 2 |
| `NEW_PERSONAL_RECORD` | Achieving a verified personal record (PR) on any exercise | 30 XP | `NEW_PR:{userId}:{exerciseId}:{date}` | 3 |
| `COMPLETE_CHALLENGE` | Completing an active daily challenge | 35 XP | `CHALLENGE:{userId}:{challengeId}` | 1 |
| `COMPLETE_WEEKLY_CHALLENGE`| Completing an active weekly challenge | 100 XP | `WEEKLY_CHALLENGE:{userId}:{challengeId}`| 1 |
| `LOG_BODY_PROGRESS` | Logging weight or body measurements (max once a week) | 25 XP | `BODY_PROGRESS:{userId}:{weekKey}` | 1 |
| `COMMUNITY_CHEER` | Giving supportive reaction on a friend's workout post | 5 XP | `COMMUNITY_CHEER:{userId}:{postId}` | 5 |

---

## 3. Level Progression Formula

Levels start at 1 and scale progressively:

$$\text{Total XP Required for Level } L = 100 \times (L - 1)^{1.6}$$

| Level | Title | Cumulative XP Required | Next Level Delta |
|:---:|:---|:---:|:---:|
| 1 | Pemula (Beginner) | 0 | 100 |
| 2 | Berkomitmen (Committed) | 100 | 150 |
| 3 | Konsisten (Consistent) | 250 | 200 |
| 4 | Pelari Rutin (Regular) | 450 | 260 |
| 5 | Atlet Pemula (Aspiring Athlete) | 710 | 320 |
| 10 | Pejuang Sehat (Fitness Warrior) | 2,500 | 600 |
| 20 | Master Kebugaran (Fitness Master) | 10,000 | 1,200 |

---

## 4. Initial Achievements List

1. **Langkah Pertama (First Step):** Catat makanan pertama kali. (50 XP bonus)
2. **Ksatria Air (Hydration Knight):** Capai target air 3 hari berturut-turut. (75 XP bonus)
3. **Pahlawan Angkat Beban (Iron Lifter):** Selesaikan sesi latihan gym pertama. (75 XP bonus)
4. **Streak Emas 7 Hari (7-Day Streak):** Catat nutrisi atau latihan selama 7 hari berturut-turut. (150 XP bonus)
5. **Pencetak Rekor (PR Breaker):** Cetak Personal Record (PR) pertama pada latihan apa pun. (100 XP bonus)
6. **Sahabat Sehat (Community Ally):** Bergabung ke grup komunitas pertama. (50 XP bonus)
