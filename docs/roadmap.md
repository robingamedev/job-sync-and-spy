# Job Sync and Spy Roadmap

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

- [x] Create Settings UI in Next.js to input search parameters (NATIVELY HANDLED by JobSync Automation UI)
- [x] Create Dashboard UI in Next.js to display scraped job leads from the `Jobs` table (NATIVELY HANDLED by JobSync Jobs UI)
- [x] Create System Health UI in Next.js to display logs and the next scheduled scrape countdown (NATIVELY HANDLED by JobSync AutomationRun UI)
- [ ] Create Settings UI specifically for inputting and saving the OpenAI API key to the `ApiKey` table
- [x] Ensure frontend components correctly read/write to the database via Prisma

## Milestone 5: Polish

- [x] Final UI/UX polish and end-to-end testing
- [x] Write `README.md` with "Zero-Config" setup instructions for end users

## Future Requests

- [x] A way to add env variables to the docker-compose.yml file to make it easier to set up the app (maybe it trickle downs to frontend and scraper env vars?)
- [x] Replace PocketSpy with the actual project name 'Job Sync and Spy'.
- [ ] In Settings, you can add API Keys for OpenAI, DeepSeek, and Ollama. What about other AI platforms like Claude (Anthropic), Gemini (Google), and Mistral?
- [x] add terminal commands to run scraping as a test. (docker exec job-sync-and-spy-scraper-1 python main.py)
- [x] There is hardcoded data in the scraper. Let's move it to the scraper env file.
