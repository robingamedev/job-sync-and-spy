# PocketSpy Stack Roadmap

## Milestone 1: Foundation

- [ ] Initialize Git repository
- [ ] Set up `docker-compose.yml` with PostgreSQL service
- [ ] Create `frontend/` directory
- [ ] Fork/Clone base JobSync Next.js application into `frontend/`
- [ ] Add Next.js service to `docker-compose.yml`
- [ ] Verify `docker compose up -d` successfully boots Postgres and the Next.js app

## Milestone 2: Database Schema & Migrations

- [ ] Define `Settings` table in Prisma schema (API keys, search terms, intervals)
- [ ] Define `Jobs` table in Prisma schema (scraped leads, deduplication by URL)
- [ ] Define `System Logs` table in Prisma schema (scraper health, errors)
- [ ] Update Next.js Dockerfile startup script to run `npx prisma migrate deploy`
- [ ] Verify auto-migrations run seamlessly on boot without user interaction

## Milestone 3: The Python Scraper (Producer)

- [ ] Create `scraper/` directory with Python Dockerfile
- [ ] Install `jobspy`, `sqlalchemy` (or `psycopg2`), and `schedule` via `requirements.txt`
- [ ] Implement database connection to read active search terms from `Settings` table
- [ ] Implement the core `jobspy` scraping loop
- [ ] Implement deduplication and database insertion (`ON CONFLICT DO NOTHING`) into `Jobs` table
- [ ] Implement error handling and logging to `System Logs` table
- [ ] Add `scraper` service to `docker-compose.yml`

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
