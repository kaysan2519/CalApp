# Cal - Design System & UI/UX Guidelines (docs/DESIGN.md)

Generated and refined using **UI/UX Pro Max** intelligence for "fitness nutrition tracker mobile app" (Flutter stack).

---

## 1. Research Summary & Query Audit

- **Tool:** `ui-ux-pro-max-skill/scripts/search.py`
- **Queries:**
  - `--design-system -p "Cal"`: Product pattern, style, colors, typography, effects, anti-patterns.
  - `--stack flutter`: Navigator 2.0 / GoRouter, dark theme in `MaterialApp`, theme extensions.
  - `--domain color`: Emerald green palette for nutrition, energetic warm orange for workouts, dark slate surfaces.
  - `--domain ux`: Touch targets (≥48dp Android, ≥44pt iOS), touch spacing (≥8dp gap), bottom nav destinations (≤5).

---

## 2. Recommendations Adopted vs Rejected

### Adopted:
1. **Emerald Brand Primary (`#10B981` / `#059669`):** Fresh, healthy, non-medical feeling for calorie and nutrition tracking.
2. **Distinct Macro Colors:**
   - **Protein:** Indigo / Royal Blue (`#6366F1`) – muscle building, focus.
   - **Carbohydrates:** Energy Warm Orange (`#F97316`) – sustained energy, vitality.
   - **Fat:** Golden Amber (`#F59E0B`) – essential nutrients, balance.
   - **Calories:** Emerald Green (`#10B981`) – overarching balance.
3. **Calm Dark Surface Default (`#0F172A` background, `#1E293B` cards):**
   - High contrast readability for gym environments and low light.
   - 4.5:1 minimum text contrast maintained (`#F8FAFC` foreground).
4. **Touch & Spacing Standards:**
   - Minimum button/action touch target: 48dp on Android.
   - Minimum 8dp spacing between interactive elements.
   - Bottom navigation limited to 4 core tabs: **Hari Ini (Today)**, **Nutrisi (Nutrition)**, **Latihan (Workout)**, **Komunitas (Community)** (Profile accessible via top bar).
5. **No Generic Emojis as Icons:**
   - Consistent Material Symbols / SVG-style vector iconography.
6. **State-Driven Feedback:**
   - Explicit loading spinners/shimmers, empty state illustrations with helpful call-to-actions, clear error cards with retry buttons.

### Rejected / Adapted:
1. **Web-specific Hero Carousel with Testimonials:**
   - *Rejected:* Web landing page patterns are unsuitable for an authenticated daily mobile utility app.
   - *Adapted:* Replaced with an actionable Daily Dashboard (calorie ring, remaining macros, quick action sheet, and today's workout snippet).
2. **Pure White / Neon Accents:**
   - *Rejected:* Overly aggressive neon greens and high glare strain eyes during evening meal logging and workouts.
   - *Adapted:* Calibrated emerald `#10B981` with balanced surface dark tones.
3. **Heavy 3D Engines:**
   - *Rejected:* Avoided Three.js/heavy 3D assets to maintain instant 60fps responsiveness on mobile devices.
   - *Adapted:* Clean vector illustrations, lightweight ring custom painters, and smooth Flutter transitions (150–250ms ease).

---

## 3. Flutter Design Tokens Architecture

The design tokens are implemented natively in Flutter:
- `AppColors`: Palette definitions for light and dark modes, semantic tokens, and macro colors.
- `AppTypography`: Clean modern typography using standard legible sans-serif with clear scale hierarchy (`headlineMedium`, `titleMedium`, `bodyMedium`, `labelSmall`).
- `AppTheme`: `ThemeData.dark()` and `ThemeData.light()` configurations using `ColorScheme.fromSeed` with custom semantic extensions (`CalThemeExtension` for macro colors and custom card borders).
- `AppSpacing`: Consistent 4px grid (4, 8, 12, 16, 24, 32, 48).
- `AppRadius`: Subtle rounded corners (8, 12, 16, 24).
