# GastRotator Android - Progress Log

## Session: April 2026 - V1 Release Finalization

### Date: 2026-04-12
- **UI Refinement:**
    - Corrected "AI AI Magic Import" button label to "AI Magic Import".
    - Removed redundant "Vibe Check / See All" header from the Home screen.
    - Restored "Culinary Curator" editorial design to the Recipe Detail screen (Noto Serif/Manrope typography, monochromatic depth).
    - Fixed parsing bug in `_parseList` that misinterpreted multi-digit instruction numbers (e.g., Step 10).
- **Onboarding & Accessibility:**
    - Implemented `HelpScreen` (`lib/screens/help_screen.dart`) with a 4-step visual guide for Gemini API key generation.
    - Integrated direct links to the Setup Guide in `SettingsScreen` and `ImportRecipeScreen`.
    - Added "Open Studio" and "Setup Guide" shortcut buttons for easier onboarding.
- **Error Handling:**
    - Updated `TranscriptFetchError.notAccessible` message to "there is no transcript associated with this video" for clarity.
- **Release Engineering:**
    - Generated production release keystore (`upload-keystore.jks`).
    - Configured `android/key.properties` and `android/app/build.gradle.kts` for production signing.
    - Successfully built signed App Bundle (.aab) and Release APK (.apk).
    - Verified signed build on physical device (moto g57 power).

### Date: 2026-04-14
- **Bug Fixes:**
    - Resolved widespread 503 (Service Unavailable) errors by switching the Gemini API fallback from `gemini-2.0-flash` to the more stable `gemini-1.5-flash`.
    - Added explicit `GenerativeAIException` handling for 429 and 503 errors to improve resilience.
- **Architectural Resilience:**
    - Implemented "Dynamic Model Ladder" in `GeminiService`. The app now automatically discovers all available models for an API key and builds a priority-based fallback queue.
    - Added cascading real-time failover: If a top-tier model (e.g., Gemini 2.0 Flash) is overloaded (503) or deprecated (404), the app automatically retries with the next best available model (e.g., 1.5 Flash).
    - Integrated Technical Logging: All ladder transitions and server-side responses are now visible in the new "System Logs" screen for debugging.
- **System Synchronization:**
    - Recovered uncommitted "Culinary Curator" design tokens and "Smart Parser" logic in the local workspace.
    - Aligned `pubspec.yaml` versioning with `SYSTEM_INTEGRITY.md` (Bumped to `1.1.2+3`).
    - Staged untracked documentation files (`ARCH_MAP.md`, `PROGRESS_LOG.md`, `SYSTEM_INTEGRITY.md`) for repository tracking.
- **Testing:**
    - Updated `integration_test/app_test.dart` to match the current "Backup & Restore" section title.
    - Verified core navigation and visual restoration on physical hardware.
- **Regression Fixes & System Integrity:**
    - Restored "Culinary Curator" design system to `RecipeDetailScreen` after accidental regression during parser update.
    - Implemented high-fidelity "Smart Parser" using lookaheads to support "wall of text" inputs and correctly handle multi-digit steps (Step 10+).
    - Created `SYSTEM_INTEGRITY.md` to track protected UI/UX components and prevent future regressions.
    - Added `[PROTECTED UI]` and `[PROTECTED LOGIC]` headers to critical files.
    - Standardized `AppTheme` tokens for pixel-perfect alignment with Stitch blueprints.
