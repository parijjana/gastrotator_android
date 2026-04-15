# GastRotator Android - Architectural Map

## Project Vision: The Culinary Curator
A local-first, privacy-centric recipe manager utilizing generative AI for extraction. The UI follows an "Editorial Journal" aesthetic: monochromatic foundations, Noto Serif headlines, Manrope body text, and "Heat Signature" (Orange) accents.

## Core Layers

### 1. Presentation (Screens)
- **`HomeScreen`**: Grid/List of recipes with category filtering and search. Primary entry point for AI Import.
- **`RecipeDetailScreen`**: Editorial layout. Parses raw text into structured ingredients and numbered steps.
- **`ImportRecipeScreen`**: Multi-input (URL + Search) screen for adding new recipes. Includes API key guards.
- **`SettingsScreen`**: Central hub for API keys, visual themes, and data backup/restore.
- **`HelpScreen`**: Visual onboarding guide for API key generation.
- **`AboutScreen`**: Versioning information and future roadmap.

### 2. Domain (Models)
- **`Recipe`**: Core entity storing dish data, nutritional info, and AI-generated metadata.
- **`TranscriptFetchError`**: Enum-based error handling for YouTube/AI pipeline failures.
- **`ValidationResult`**: Quality flags for AI extractions (e.g., "Food Adjacent", "Low Confidence").

### 3. Data (Services & Providers)
- **`DatabaseHelper`**: SQLite (sqflite) implementation. Managed via `onUpgrade` for seamless data persistence during updates. Current schema: **v8**.
- **`GeminiService`**: BYOK (Bring Your Own Key) integration for LLM-based recipe extraction and cleaning.
- **`YouTubeService`**: Uses InnerTube protocol for resilient transcript fetching.
- **`Providers`**: Riverpod-based state management for recipes, API keys, and theme settings.

### 4. Technical Infrastructure
- **Release Signing**: Production keys managed via `key.properties` (ignored by git).
- **ProGuard/R8**: Optimized for release with specific rules to keep SQLite and Play Core components.
- **SI-Standardization**: Mandatory use of Grams/Milliliters across all data points.

## Integration & Automation
- **`main_driver.dart`**: Entry point for automated UI testing via Flutter Driver.
- **Integration Tests**: `app_test.dart` (navigation) and `ux_improvements_test.dart` (functional flows).
