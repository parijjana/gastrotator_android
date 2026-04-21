# Distributed API Gatekeeper & Pacing Blueprint
**Strategic Architectural One-Pager for Large-Scale Backend Systems**

## 1. The Challenge
When a backend service receives concurrent requests from thousands of clients but relies on external APIs with strict rate limits (e.g., Gemini's 15 RPM), a simple local delay is insufficient. High-concurrency traffic must be **serialized, paced, and buffered** to prevent API blocks and cascading system failures.

---

## 2. The "Gatekeeper" Architecture (Distributed)

### A. The Request Tier (Non-Blocking)
*   **API Gateway (Nginx/Traefik):** Handles SSL and initial rate limiting per IP to prevent DDoS.
*   **Backend Service (Node/Go/Python):** Receives client requests. Instead of calling the external API, it validates the request and immediately pushes a "Job" into the **Message Broker**.
*   **User UX:** Returns a `202 Accepted` status with a `job_id`. The client app shows a "Processing" state.

### B. The Pacing Tier (The State)
*   **Redis (Distributed Cache):** Maintains the "Token Bucket" or "Leaky Bucket" state. Every request across all server instances checks Redis before proceeding.
*   **Message Broker (RabbitMQ / Redis Streams):** Acts as the "Waiting Room." It stores the payloads securely until a worker is ready to process them. *RabbitMQ is recommended for reliability; Redis Streams for simplicity.*

### C. The Execution Tier (Throttled Workers)
*   **Worker Pool:** A set of isolated processes that "consume" jobs from the broker.
*   **Global Semaphore:** Workers are strictly limited in concurrency. To stay under 15 RPM, you might run only **2 workers** with a mandatory **5-second cooldown** after every successful API response.

---

## 3. Resilience Patterns
*   **Circuit Breaker:** If the external API returns a `429` or `503`, the system "trips." For the next 60 seconds, all new incoming jobs are rejected immediately to allow the external service to recover.
*   **Dead Letter Queue (DLQ):** If a job fails 3 times, move it to a DLQ for manual inspection instead of clogging the main pipeline.
*   **Eager Load:** Always cache successful configurations (like AI model versions) in Redis to avoid redundant "discovery" calls.

---

## 4. Deployment & Cost Strategy (Self-Hosted VPS)

| Component | Tool (OSS) | VPS Requirements | Role |
| :--- | :--- | :--- | :--- |
| **Logic** | Docker + Go/Node | Shared CPU | API Handlers |
| **Pacing** | **Valkey** (Redis fork) | 512MB RAM | Counters & Rate Limits |
| **Buffer** | **RabbitMQ** | 1GB RAM | Reliable Job Queue |
| **Database** | **PostgreSQL** | 1GB RAM | Permanent Storage |

**Total Infrastructure Cost:** ~$20–$40/mo on a single 4GB RAM VPS (DigitalOcean/Hetzner/Linode).
**Comparison:** Equivalent managed cloud services (AWS/Confluent) would cost **$250+/mo**.

---

## 5. Summary Recommendation
For GastRotator-scale transitions to a centralized backend:
1.  **Buffer everything:** Never make synchronous external API calls.
2.  **State is Central:** Use Redis for the clock, not local variables.
3.  **Worker-as-Gatekeeper:** Let a single-threaded worker own the API interaction to ensure 100% compliance with rate limits.
