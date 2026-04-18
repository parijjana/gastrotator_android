# AI Mandates & Constraints - GastRotator

This file serves as the **Contextual Precedence** for all AI-driven development. These mandates are absolute and must be reviewed before implementing or modifying any feature.

## 1. The Model Ladder Contract
- **Fast Path Mandate:** Never trigger model discovery (`discoverAndRankModels`) if a `lastSuccessfulModel` is saved and currently valid.
- **Persistence Mandate:** The `lastSuccessfulModel` must be persisted across app restarts via `FlutterSecureStorage`.
- **Success Callback:** Every successful extraction must report the model name back to the storage layer to ensure the "Fast Path" stays updated with the best performing model.

## 2. The Extraction Contract (JSON Schema)
- **Numbered List Mandate:** The `recipe` field in the extracted JSON **MUST** be a numbered list (1., 2., 3.).
- **Instruction Structure:** Each step must be on a new line. 
- **Constraint Enforcement:** Any change to `lib/services/gemini_service.dart` must preserve the explicit system instruction: *"Use a numbered list (1., 2., 3.) with each step on a new line."*

## 3. System Integrity & Logging
- **Persistence:** System logs must be stored in the SQLite database (`logs` table).
- **Size Limit:** Logs must be auto-pruned to a maximum of **500 entries**. Oldest logs are deleted first.
- **Sharing:** The "Share Logs" functionality must remain accessible in the UI to prevent technical debug data from being posted to public GitHub issues.

## 4. UI/UX Consistency
- **Editorial Aesthetic:** Headlines must use `Noto Serif`, body text must use `Manrope`.
- **SI Units Only:** All measurements in the database and display must be SI units (grams, milliliters). Never implement Imperial toggles.
- **Protected Logic:** The "Smart Parser" in `RecipeDetailScreen` is protected. It must support multi-digit step detection (Step 10+) using lookahead RegEx.

## 5. Regression Prevention Workflow
- **Before Coding:** Read `ARCH_MAP.md` and `PROGRESS_LOG.md` to understand current state.
- **Prompt Versioning:** Keep system instructions deterministic. If an instruction is changed to fix a bug, document the fix in `PROGRESS_LOG.md` as a "Contract Change."
- **TDD:** Always run `flutter test` after changing the AI pipeline or parser logic.
- **Full Suite Mandate:** Before any `flutter build` or deployment to a physical device, you **MUST** run the full test suite (`flutter test`) and achieve 100% green status. Partial test runs are for development; full runs are for verification.
- **State-Preservation Mandate:** When refactoring or using `write_file`, you must explicitly verify that existing Provider listeners (e.g., `themeProvider`, `apiKeyProvider`) and their dynamic logic are preserved. Never simplify code by hardcoding values that were previously dynamic.
- **URL Integrity Mandate:** The `YouTubeUrlParser` is a foundational utility. Any change to import logic must be verified against the parser's normalization rules to ensure test data and production data remain synchronized.
- **Browser-First UI Verification:** For any UI-related changes, verification must be performed in Chrome using `integration_test/browser_ui_test.dart`. The project data layer is web-safe (using in-memory fallbacks) to facilitate this.

## 6. Web-Safe Architecture Standard
- **Data Layer:** `DatabaseHelper` must maintain a `kIsWeb` branch using in-memory storage (`_webDb`) to prevent crashes in non-native environments.
- **Logging:** `AppLogger` must fail gracefully if persistence is unavailable (e.g. on Web).
- **Services:** External services (YouTube, etc.) must provide mock data when `kIsWeb` is true to allow UI flow testing without network/platform dependencies.
