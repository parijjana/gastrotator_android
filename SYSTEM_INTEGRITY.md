# GastRotator - System Integrity & Protected Components

This document tracks "Protected" components and architectural decisions that must not be regressed during maintenance or feature updates.

## 🛡️ PROTECTED UI: "The Culinary Curator"
**Location:** `lib/screens/recipe_detail_screen.dart`, `lib/theme/app_theme.dart`

### Core Design Rules
1.  **Typography:**
    *   Headlines: **Noto Serif** (FontWeight.w900).
    *   Body/Instructions: **Manrope**.
    *   Strictly avoid: `Share Tech Mono` (used only for raw data debugging).
2.  **Colors:**
    *   Primary: `#944A00` (The "Heat Signature").
    *   Surface: `#FCF9F8` (Off-white editorial base).
    *   Avoid hardcoded hex codes; use `Theme.of(context).colorScheme`.
3.  **Layout:**
    *   Editorial masthead style for titles.
    *   Asymmetrical spacing (generous vertical gutters).
    *   Step-by-step numbering (01, 02...) with low-opacity primary color markers.

---

## 🛠️ PROTECTED LOGIC: "The Smart Parser"
**Location:** `lib/screens/recipe_detail_screen.dart` -> `_parseList()`

### Purpose
AI-generated transcripts often come as a "wall of text" or with inconsistent numbering (1., •, -). The parser must break these into clean `List<String>` items for the editorial UI.

### Logic Requirements
1.  **Multi-Digit Support:** Must handle Step 10, 11, etc., without stripping the "0" or "1".
2.  **Wall-of-Text Fallback:** If no newlines are present, split by detection of "1.", "2." markers using lookaheads.
3.  **Prefix Cleanup:** Strip leading bullets and numbers while preserving the instruction content.

---

## 📅 VERSION HISTORY (Detail Screen)
- **v1.0.0:** Initial Flutter implementation.
- **v1.1.0:** Applied "Culinary Curator" Stitch Design.
- **v1.1.1:** Attempted Step 10 fix (Caused Theme Regression).
- **v1.1.2 (CURRENT):** Restored Theme + Improved Smart Parser + Integrity Documentation.
