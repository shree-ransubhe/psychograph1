# Subcategory Screen – Design & Behavior Spec

**Figma:** [Mobile-App-R-D node 7-10](https://www.figma.com/design/rwV06ykqcJ7Abn6BU45pks/Mobile-App-R-D?node-id=7-10)

---

## 1. Entry & Flow

- **Entry:** User taps one of the 4 main categories (भय, राग, धैर्य, शांति) on the “Log your today’s Psychograph” screen.
- **Result:** Subcategory screen opens for that parent category (e.g. tap भय → screen shows भय and its subcategories).

---

## 2. Selection

- **Multi-select:** User can select **one or many** subcategories.
- **Persistence:** Selection is per parent category and per “session” until Done is tapped (then stored).

---

## 3. Parent Category Switching (Swipe / Carousel)

- **Behavior:** User can **swipe left–right** to move between the 4 parent categories (भय → राग → धैर्य → शांति).
- **Per category:** Each parent shows its own subcategory list and its own selection state.
- **UI:** Same layout and styling for each parent; only emoji, title, and subcategory chips change.

---

## 4. Layout (from Figma)

- **Container:** Rounded card (e.g. `cornerRadius(40)`), light blue–grey gradient background (same as Add Today’s Graph card: #C0D7DA → #D9E0E1), shadow.
- **Header:**
  - **Left:** Circular “back” / “previous category” button (chevron left).
  - **Right:** Circular “close” (X) button.
  - Both: light grey background, subtle shadow.
- **Content:**
  - **Emoji:** Large, centered (e.g. 😱 for भय).
  - **Parent title:** Centered, bold (e.g. “भय”).
  - **Subcategory chips:** Grid (e.g. 3 per row), pill-shaped, with spacing.
- **Footer:** Single primary “Done” button at bottom (same style as PrimaryButton: teal, `cornerRadius(66)`, shadow).

---

## 5. Chip States (match Figma selection state)

- **Unselected:**
  - Background: white / very light grey.
  - Border: thin, light grey.
  - Text: black.
- **Selected (e.g. 1st and 3rd in your set):**
  - Background: light blue–green / teal (e.g. `Color(red: 0, green: 0.62, blue: 0.71)` or slightly lighter tint).
  - Border: slightly darker teal.
  - Text: black.
- Use this style consistently for all selected chips across all 4 parent categories.

---

## 6. Done Button & Data

- **Action:** “Done” at bottom **closes the subcategory screen** and **stores the data**.
- **Stored data:** For the current “Log your today’s Psychograph” session (and its selected date), persist which subcategories were selected for each of the 4 parent categories (e.g. dateKey + category A/B/C/D + set of selected subcategory indices or IDs).
- **Reuse:** Use the existing **PrimaryButton** component for “Done” (same teal, cornerRadius 66, shadow).

---

## 7. Data Model (for implementation)

- **Per date:** e.g. `dateKey: String` (yyyy-MM-dd).
- **Per parent category:** A, B, C, D.
- **Per category:** Set of selected subcategory indices (e.g. `Set<Int>` for indices 0..<count).
- **Storage:** Reuse/expand existing check-in storage (e.g. StorageService) so that “Add Today’s Graph” flow writes the same structure the Report/Check-in reads (subcategory toggles per day).

---

## 8. Summary Checklist

| Item | Spec |
|------|------|
| Entry | Tap main category on “Log your today’s Psychograph” → open subcategory screen for that category. |
| Selection | One or many subcategories per parent; multi-select. |
| Swipe | Left–right to switch among 4 parent categories (carousel). |
| Selected style | Teal-like fill + darker teal border, black text (match Figma 1st & 3rd). |
| Done | PrimaryButton “Done” at bottom; on tap: close + save selections for current date. |

---

*Use this spec when implementing the subcategory screen so layout, selection state, and Done behavior stay aligned with Figma and requirements.*
