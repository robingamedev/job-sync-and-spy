# Project Architecture: The PocketSpy Stack

**Subtitle:** A Self-Hosted, AI-Augmented Job Search CRM
**Status:** Architecture Phase

## 1. Executive Summary

The **PocketSpy Stack** is an open-source tool designed to automate the "discovery" and "preparation" phases of the job hunt. Unlike "Auto-Apply" bots that risk account bans, this project focuses on **High-Quality Lead Generation** and **Automated Tailoring**, leaving the final human-in-the-loop submission to the user.

It leverages **JobSpy** for resilient scraping, and a **Next.js** frontend (forked from [JobSync](https://github.com/Gsync/jobsync)) for a modern dashboard experience, all orchestrated cleanly inside a single Docker Compose deployment.

This project is designed to be purely self-hosted, running entirely within Docker, allowing non-technical users to spin up a personal job-hunting assistant without installing Node.js, Python, or dealing with complex configurations.

---

## 2. System Architecture

The system follows a "Producer-Consumer" pattern linked by a shared database.

| Component        | Responsibility                                                    | Tech Stack                    |
| ---------------- | ----------------------------------------------------------------- | ----------------------------- |
| **The Database** | Relational data, user settings, system logs                       | PostgreSQL (Dockerized)       |
| **The ORM**      | Database schema management and migrations                         | Prisma                        |
| **The Consumer** | User Dashboard, Query Management, Tracking, AI Tailoring          | Next.js (Forked from JobSync) |
| **The Producer** | Scheduled scraping, data cleaning, deduplication, error reporting | Python + JobSpy (Dockerized)  |
| **The Wrapper**  | Zero-config portability and startup                               | Docker Compose                |

---

## 3. Core Mechanisms

### A. Zero-Config Startup & Auto-Migrations

The primary goal is "No Tech Support" deployment for ~100 friends.

- The user runs `docker compose up -d`.
- Docker pulls all dependencies (Node, Python) isolated inside containers.
- The PostgreSQL container uses a **Docker Named Volume** (`pgdata`) to persist the database without triggering Mac/Windows OS-level file permission conflicts.
- On startup, the Next.js container automatically runs Prisma migrations (`npx prisma migrate deploy && npm start`), applying the schema safely before the UI becomes available. Zero clicks required.
- **Database Init:** Initialization is kept extremely simple (KISS) relying on standard Docker Compose setup.

### B. Setup Friction & The Settings UI

- Non-technical users shouldn't edit `.env` files.
- The Next.js dashboard will have a dedicated **Settings** screen.
- Users input their OpenAI API Keys, Job Search terms, and Scraper intervals here.
- This data is safely stored in a `settings` table in the PostgreSQL database (API keys will be encrypted at rest).
- The Python scraper reads directly from this table on startup.

### C. The Scraper (Producer)

- The Python application runs an infinite loop/scheduler inside a detached container. (To minimize scope and avoid needing a listener API, there is no "Run Now" button. The UI simply displays a countdown to the next scheduled run. Advanced users can trigger a run via terminal command if necessary).
- It pulls active search terms from the database.
- Uses the `jobspy` library to scrape LinkedIn, Indeed, etc.
- Deduplicates using the job URL before pushing to the database.
- **Error Handling:** If an IP block occurs or JobSpy hits a CAPTCHA, it reports the failure directly to a `system_logs` table in the DB. The UI surfaces this automatically.
- **Maintainability:** Scraper updates to adapt to job board changes will be shipped as container updates; users will simply pull the latest image.

### D. The Brain (AI Tailoring)

- The Next.js server handles AI prompts.
- Prompt Engineering ensures the LLM relies entirely on the user's provided "Body of Work" (Master Resume) to prevent AI hallucinations. (Note: Master Resume ingestion is already handled by the JobSync fork).
- The system is provider-agnostic, easily supporting OpenAI, Anthropic, or even Local Ollama (though Ollama requires more host configuration).

---

## 4. Development Roadmap

1. **Milestone 1:** Basic Docker Compose setup with PostgreSQL and Next.js (JobSync initial fork running).
2. **Milestone 2:** Implement the complete Prisma schema including the new tables for `Settings`, `Jobs`, and `System Logs` (and auto-migration on boot).
3. **Milestone 3:** Create the Dockerized Python Scraper that successfully pulls `Settings` and pushes data to `Jobs`.
4. **Milestone 4:** Dashboard Integration — JobSync UI modified to display scraped leads and expose the Scraper Health (Logs UI).
5. **Milestone 5:** Integrate AI resume tailoring, PDF generation, and final UI polish.

6.
