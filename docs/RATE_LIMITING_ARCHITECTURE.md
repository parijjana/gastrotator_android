# Rate Limiting & API Gatekeeper Architecture

## 1. Overview
GastRotator utilizes multiple external APIs (Google Gemini, YouTube) that enforce strict usage quotas. To ensure system stability and prevent permanent IP/Key flagging, we have implemented a custom **RateLimitDispatcher** (Gatekeeper Pattern).

## 2. Problem Statement: Why we didn't use generic libraries
While standard Dart packages like `ratelimiter` or `polly_dart` exist, they were rejected for the following reasons:
*   **Lack of Persistence:** Most libraries store "last hit" timestamps in volatile memory. If a user restarts the app during a rate-limit block, the timer resets, leading to immediate repeated violations.
*   **Execution Speed Discrepancy:** Production builds (AAB) run significantly faster than Debug APKs. Without a centralized gatekeeper, the optimized Release build fires API calls in bursts that exceed the 15 RPM (Requests Per Minute) limit of the Gemini Free Tier.
*   **Context Isolation:** Standard libraries treat every call as independent. We needed a system that understands the "video extraction lifecycle" (Metadata -> Transcript -> AI) and paces them as a single logical unit.

## 3. The Solution: RateLimitDispatcher
The `RateLimitDispatcher` acts as a centralized "Execution Queue" for all network traffic.

### Key Architectural Pillars:
1.  **Strict Serialization:** Every API request is submitted as a `Future` task. The Dispatcher ensures that only one request per API type is active at any given time, preventing "burst" collisions.
2.  **Invulnerability Windows:** 
    *   **Gemini:** Mandatory **5,000ms** cooldown between calls.
    *   **YouTube:** Mandatory **2,000ms** cooldown between calls.
    *   These windows are configurable via `assets/rate_limit_config.json`.
3.  **The "Single Ladder" Policy:**
    *   The expensive "Model Ladder" discovery process is now triggered exactly **once** at the start of an extraction.
    *   The app "locks" onto the successful model for the remainder of that specific video's processing, saving ~50% of the API quota.
4.  **Global Circuit Breaker (Halt):**
    *   If a `429 (Too Many Requests)` error is caught by the Dispatcher, it trips a global `halt` state. This instantly stops all other items in the queue to protect the user's IP reputation.

## 4. Maintenance & Configuration
The pacing of the app can be adjusted without changing source code by modifying the configuration file:
`assets/rate_limit_config.json`

```json
{
  "gemini_cooldown_ms": 5000,
  "youtube_cooldown_ms": 2000
}
```

## 5. Summary of Solved Regressions
*   **The Steamroller Bug:** Fixed the background worker failing an entire queue one-by-one upon hitting a rate limit.
*   **The Amnesia Bug:** Fixed the app forgetting the last successful model upon restart.
*   **The Discovery Loop:** Eliminated redundant "What models are available?" calls before every AI task.
