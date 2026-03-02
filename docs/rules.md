# PocketSpy Stack Rules

These are the core architectural, coding, and agent-interaction rules for the **PocketSpy Stack**. All contributors (including AI agents) must adhere to these principles to maintain the project's simplicity, resiliency, and "Zero-Config" deployment goals.

## 1. Architecture Rules

- **Simplicity Above All (KISS):** If a feature requires the user to install dependencies on their host machine, configure reverse proxies, or manage complex `.env` files, it violates the core philosophy.
- **Monorepo Structure:** Keep everything in a single Git repository. A `frontend/` folder for Next.js, a `scraper/` folder for Python, and `docker-compose.yml` at the root.
- **The Database is the ONLY Bridge:** The Next.js frontend and Python scraper should _never_ communicate directly via APIs or webhooks. All communication happens asynchronously via the PostgreSQL database. Next.js writes settings/commands to DB tables; Python reads them. Python writes scraped jobs to DB tables; Next.js reads them.
- **Hardcoded Local Security:** As a 100% local, self-hosted tool not exposed to the internet, hardcode database credentials in `docker-compose.yml` (e.g., `POSTGRES_USER=pocketspy`, `POSTGRES_PASSWORD=localpassword`). Do not force users to manage database secrets. (Note: API Keys like OpenAI are the exception, and they must be stored encrypted in the DB via the Settings UI).
- **Idempotent Scraping:** The Python scraper must expect to be killed at any moment (e.g., stopping the Docker container). It should rely on unique constraints (like Job URLs) and handle inserts with `ON CONFLICT DO NOTHING` to prevent duplicate entries.
- **Strict Docker-First Execution:** All builds, package installations, database migrations, and scripts MUST be executed inside their respective Docker containers (e.g., using `docker compose exec`, `docker compose up --build`, or `docker run`). Never run commands like `npm install`, `node`, `python`, or `pip` directly on the host OS to prevent environmental contamination and ensure true zero-config portability.

## 2. Code Rules

- **Strict Boundary Typing:** Next.js uses Prisma for perfect frontend types. Because Python is dynamically typed, the Python scraper must use schema validation (like Pydantic or SQLAlchemy models) that strictly mirrors the Prisma schema.
- **No "Magic" AI Retries:** If an external API (OpenAI) times out or the scraper hits a CAPTCHA, fail fast. Log the exact error to the `system_logs` table in the database and gracefully sleep until the next scheduled interval. Avoid complex exponential backoff retry logic that makes debugging difficult.
- **Log Everything to the DB:** Use standard `console.log` for raw container debugging, but all significant lifecycle events ("Scrape started", "Found 10 jobs", "IP Blocked", "Tailored Resume for Company X") must be written to a `system_logs` table so the user can see them in the Next.js dashboard.
- **Database Migrations:** Always use `npx prisma migrate deploy` in the Next.js startup script to safely apply incremental schema changes on boot, preventing accidental data loss that can happen with `db push`.

## 3. Agent Rules (AI Integration)

- **Protect the User's Wallet:** Users provide their own OpenAI API keys. Enforce strict token limits (`max_tokens`) in all API calls. Default to cheaper, faster models (e.g., `gpt-4o-mini`) for bulk tasks like categorizing jobs. Reserve expensive models only for final, one-off resume generation when explicitly requested by the user.
- **Deterministic Outputs:** When asking the LLM to process data (extract skills, categorize jobs), strictly enforce structured outputs (JSON mode). If the LLM returns invalid JSON or unstructured text, fail gracefully by marking the job as "Failed to Parse" rather than crashing the application.
- **Prompt Isolation:** Keep AI system prompts out of deep React component logic or complex API routes. Centralize all prompts in a dedicated location (e.g., `frontend/lib/prompts.ts` or directly in the database) so they can be easily reviewed and tweaked.
- **No Hallucinations:** Prompt Engineering must heavily constrain the LLM to rely _entirely_ on the user's provided "Body of Work" (Master Resume) when generating tailoring content. No inventing skills or experiences. (Note: Master resume ingestion is handled by the base JobSync fork).
