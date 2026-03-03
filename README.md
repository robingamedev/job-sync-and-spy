# Job Sync and Spy

Job Sync and Spy is a completely free, open-source, self-hosted job search automation system. It combines the powerful [JobSync](https://github.com/Gsync/jobsync) frontend dashboard with a custom Python scraper (`jobspy`) to automatically find, deduplicate, and track job postings across LinkedIn, Indeed, and Glassdoor.

Say goodbye to the chaos of scattered information, endless scrolling, and bloated tracking sheets. With a single command, you will have a full Postgres database, a scheduled scraper, and a beautiful web dashboard running on your local machine.

## Key Features

1. **Automated Scraping Engine**: Runs periodically in the background, scraping job boards for your desired keywords and locations.
2. **Built-in Deduplication**: Ensures you never see the same job URL twice across multiple sync cycles.
3. **Application Tracking Dashboard**: Visualize your job search progress, move jobs between stages, and keep detailed records of your applications and interviews.
4. **Self-Hosted & Private**: Everything runs locally via Docker. You maintain 100% control over your data.
5. **Zero-Config Deployment**: A single `docker-compose` command spins up the database, the Node.js frontend, and the Python scraper instantly.

## 🚀 Zero-Config Quick Start

You only need [Docker](https://www.docker.com/) installed and running.

1. **Clone the repository:**

   ```bash
   git clone <your-repo-url> job-sync-and-spy
   cd job-sync-and-spy
   ```

2. **Run the stack:**

   ```bash
   docker compose up -d
   ```

3. **Access the Application:**
   Open your browser to [http://localhost:3737](http://localhost:3737) and create an account. The database migrations run automatically on startup!

## Setting Up Your First Automation (Scraper)

Once you have created an account and logged into the dashboard:

1. Navigate to the **Automations** tab.
2. Create a new Automation.
3. Enter your desired **Keywords** (e.g., `Software Engineer, React Developer`) and **Location** (e.g., `New York, NY` or `Remote`).
4. Set it to `Active`.

The Python Scraper container reads these active automations directly from your database and will automatically begin pulling in matching job posts. You will see the results appear in your **My Jobs** list!

## System Architecture

- **PostgreSQL**: The central persistence layer (defined via Prisma schema).
- **Next.js Frontend (`/frontend`)**: A tracking dashboard, handling the UI, user accounts, and data presentation.
- **Python Scraper (`/scraper`)**: A lightweight container running `jobspy` on a schedule, directly inserting leads into the Postgres database.

## Stopping the App

To shut down the app and stop the background scraper, simply run:

```bash
docker compose down
```

_Note: This preserves your data in the Docker volumes. The next time you run `up -d`, all your saved jobs will still be there._
