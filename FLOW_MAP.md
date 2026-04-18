# GastRotator - Process Flow Map

This document maps the interaction flows and background pipelines of the GastRotator application. 

## 1. Import Entry Points (Unified)

Regardless of the entry point, all imports funnel through `RecipesNotifier.triggerMagicImport`.

```text
[ SOURCE: Shared Link ] ----> [ IntentHandler ] ---|
                                                   |
[ SOURCE: Home Search ] ----> [ _triggerDirect ] --|--> [ RecipesNotifier.triggerMagicImport ]
                                                   |      |-- Centralized Duplicate Check (ID-based)
[ SOURCE: Import Field ] ---> [ _triggerManual ] --|      |-- IF DUP: Shake existing card
                                                   |      |-- Create DB Placeholder
[ SOURCE: Import Search ] --> [ _triggerManual ] --|      |-- Status: "In Queue"
                                                          |-- Start _startQueueWorker()
```

## 2. The Sequential Queue Worker

The background engine that ensures recipes are processed one-by-one.

```text
[ _startQueueWorker ]
  |-- Lock: _isWorkerBusy = true
  |-- Loop: _processQueue()
        |-- Find lowest queue_position with "In Queue" status
        |-- ACTION: autoProcessRecipe(recipe)
        |-- IF USER TAPS "PROCESS NOW":
              |-- Target position = min - 1
              |-- Worker pivots to target on next loop iteration
  |-- Unlock: _isWorkerBusy = false
```

## 3. The AI Extraction Pipeline

The state machine managed by `RecipesNotifier.autoProcessRecipe`.

```text
[ STATUS: In Queue / Placeholder Created ]
  |-- (Action: _fetchMetadata)
  V
[ STATUS: Metadata Fetched ]
  |-- (Action: _fetchTranscript via TranscriptService)
  |      |-- Try: YouTube Transcript API
  |      |-- Fallback: YouTube Explode CC
  V
[ STATUS: Transcript Fetched ]
  |-- (Action: _runGemini)
  |      |-- Language Detection (English Only)
  |      |-- Content Validation (Recipe vs. Other)
  |      |-- AI Extraction (Gemini 1.5 Flash/Pro)
  V
[ STATUS: Completed ]
```

## 4. UI Navigation & State Persistence

### Success Scenarios
- **From Import Screen:** User starts import -> Global Overlay (1.5s) -> return to Home.
- **From Sharing:** User shares -> Global Overlay (1.5s) -> return to Home.
- **From Error Screen:** User taps 'Re-extract' -> status prioritized -> Success Overlay -> Detail Screen.

### User Priority ("Jump the Queue")
- **Home Screen Card:** Tapping the "Bolt" icon calls `processRecipeImmediately(id)`.
- **Error Screen:** "Try Re-extracting" calls `processRecipeImmediately(id)`.

## 5. Integrity Mandates
- **Duplicate Scrubbing:** Must happen in `triggerMagicImport` using `YouTubeUrlParser` (ID-based).
- **Sequential Processing:** AI extraction must NEVER happen in parallel to protect API limits.
- **Transcripts:** Must use the multi-stage `TranscriptService`.
