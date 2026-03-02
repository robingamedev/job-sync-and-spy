# PocketSpy Stack Roadmap

## Milestone 1: Foundation

- [x] Initialize Git repository
- [x] Set up `docker-compose.yml` with PostgreSQL service
- [x] Create `frontend/` directory
- [x] Fork/Clone base JobSync Next.js application into `frontend/`
- [x] Add Next.js service to `docker-compose.yml`
- [x] Verify `docker compose up -d` successfully boots Postgres and the Next.js app
- [x] Verify we are using Docker containers for Node.js and Python environments to prevent host OS dependency issues

## Milestone 2: Database Schema & Migrations

- [x] Define `Settings` table in Prisma schema (API keys, search terms, intervals)
- [x] Define `Jobs` table in Prisma schema (scraped leads, deduplication by URL)
- [x] Define `System Logs` table in Prisma schema (scraper health, errors)
- [x] Update Next.js Dockerfile startup script to run `npx prisma migrate deploy`
- [x] Verify auto-migrations run seamlessly on boot without user interaction

## Milestone 3: The Python Scraper (Producer)

- [x] Create `scraper/` directory with Python Dockerfile
- [x] Install `jobspy`, `sqlalchemy` (or `psycopg2`), and `schedule` via `requirements.txt`
- [x] Implement database connection to read active search terms from `Settings` table
- [x] Implement the core `jobspy` scraping loop
- [x] Implement deduplication and database insertion (`ON CONFLICT DO NOTHING`) into `Jobs` table
- [x] Implement error handling and logging to `System Logs` table
- [x] Add `scraper` service to `docker-compose.yml`

## Milestone 4: Dashboard Integration (Consumer)

- [ ] Create Settings UI in Next.js to input/encrypt API keys and search parameters
- [ ] Create Dashboard UI in Next.js to display scraped job leads from the `Jobs` table
- [ ] Create System Health UI in Next.js to display logs and the next scheduled scrape countdown
- [ ] Ensure frontend components correctly read/write to the database via Prisma

## Milestone 5: The Brain (AI Tailoring) & Polish

- [ ] Integrate LLM provider (OpenAI by default) into Next.js server actions/API routes
- [ ] Implement AI categorization/summary for each scraped job using `gpt-4o-mini` with structured JSON output
- [ ] Implement "Tailor Resume" feature using user's Master Resume and job description
- [ ] Implement PDF generation for the tailored resume
- [ ] Final UI/UX polish and end-to-end testing
- [ ] Write `README.md` with "Zero-Config" setup instructions for end users
