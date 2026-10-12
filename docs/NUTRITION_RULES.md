# Cal - Nutrition Calculation Standards & Rules (docs/NUTRITION_RULES.md)

This document standardizes the clinical and mathematical rules used throughout Cal's backend and client code. All calculations are executed strictly in deterministic code, never hallucinated by an LLM.

---

## 1. Basal Metabolic Rate (BMR) - Mifflin-St Jeor Formula

Recognized by the Academy of Nutrition and Dietetics as the most reliable non-clinical estimation formula.

$$\text{BMR}_{\text{male}} = (10 \times \text{weight}_{\text{kg}}) + (6.25 \times \text{height}_{\text{cm}}) - (5 \times \text{age}_{\text{years}}) + 5$$

$$\text{BMR}_{\text{female}} = (10 \times \text{weight}_{\text{kg}}) + (6.25 \times \text{height}_{\text{cm}}) - (5 \times \text{age}_{\text{years}}) - 161$$

$$\text{BMR}_{\text{neutral}} = (10 \times \text{weight}_{\text{kg}}) + (6.25 \times \text{height}_{\text{cm}}) - (5 \times \text{age}_{\text{years}}) - 78$$

*Minimum Age:* 18 years old. Min weight: 35 kg. Min height: 120 cm.

---

## 2. Total Daily Energy Expenditure (TDEE) & Physical Activity Level (PAL)

$$\text{TDEE} = \text{BMR} \times \text{PAL}$$

| Activity Level | PAL Factor | Description |
|:---|:---:|:---|
| **Sedentary** | 1.200 | Little or no exercise, desk work |
| **Lightly Active** | 1.375 | Light exercise / sports 1–3 days/week |
| **Moderately Active** | 1.550 | Moderate exercise / sports 3–5 days/week |
| **Very Active** | 1.725 | Heavy exercise / sports 6–7 days/week |
| **Extremely Active** | 1.900 | Very intense training, physical job |

---

## 3. Caloric Target by Goal & Safety Floor Limits

| Goal | Daily Calorie Delta | Safe Weekly Rate |
|:---|:---:|:---:|
| **Lose Weight (Moderate)** | -300 to -500 kcal | -0.3 to -0.5 kg / week |
| **Lose Weight (Max Safe)** | -750 kcal | -0.75 to -1.0 kg / week |
| **Maintain Weight** | 0 kcal | 0.0 kg / week |
| **Gain Weight (Lean Bulk)** | +300 to +500 kcal | +0.25 to +0.5 kg / week |

### Critical Safety Floor Limits:
- **Female Floor:** Absolute minimum **1200 kcal/day**.
- **Male Floor:** Absolute minimum **1500 kcal/day**.
- **Neutral Floor:** Absolute minimum **1350 kcal/day**.
*If calculated target falls below the floor, the floor is strictly enforced.*

---

## 4. Macronutrient Distribution

Standard fitness macro split:
1. **Protein:**
   - 1.8g to 2.2g per kg bodyweight for resistance training / caloric deficit;
   - Or ~25%–30% of total daily calories.
   - Energy density: **4 kcal / gram**.
2. **Fats:**
   - Essential for hormonal balance: 25%–30% of total daily calories (floor: 0.6g/kg).
   - Energy density: **9 kcal / gram**.
3. **Carbohydrates:**
   - Supplies workout energy: all remaining calories after protein and fat allocation.
   - Energy density: **4 kcal / gram**.

$$\text{Carbs (g)} = \frac{\text{Target Calories} - (\text{Protein (g)} \times 4) - (\text{Fat (g)} \times 9)}{4}$$

---

## 5. Daily Water Intake Target

$$\text{Target Air (ml)} = \max(2000, \text{weight}_{\text{kg}} \times 35) + (\text{workout minutes} \times 10)$$
Default baseline: 2000 ml – 3000 ml / day.

---

## 6. Local Food Unit Conversion Norms

| Unit (Satuan) | Standard Equivalent (g) | Typical Food Examples |
|:---|:---:|:---|
| 1 centong nasi | 100g | Nasi putih, nasi merah |
| 1 piring sedang | 200g | Nasi uduk, nasi goreng porsi biasa |
| 1 potong sedang | 50g | Tempe goreng, tahu goreng |
| 1 potong dada ayam | 150g | Ayam bakar, dada ayam fillet |
| 1 butir | 50g | Telur rebus, telur ceplok |
| 1 sendok makan (sdm) | 15g | Minyak, kecap, selai |
| 1 mangkok | 250g | Sayur sop, soto ayam (kuah + isi) |
| 1 gelas air | 250 ml | Air putih standar |
