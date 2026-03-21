# Job Sync and Spy

**✨ [Not a developer? Click here for the easy 3-click setup guide!](readme-easy.md)**

Job Sync and Spy is a completely free, open-source, self-hosted job search automation system. It combines the powerful [JobSync](https://github.com/Gsync/jobsync) frontend dashboard with a custom Python scraper (`jobspy`) to automatically find, deduplicate, and track job postings across LinkedIn, Indeed, and Glassdoor.

Say goodbye to the chaos of scattered information, endless scrolling, and bloated tracking sheets. With a single command, you will have a full Postgres database, a scheduled scraper, and a beautiful web dashboard running on your local machine.

## Key Features

1. **Automated Scraping Engine**: Runs periodically in the background, scraping job boards for your desired keywords and locations.
2. **Built-in Deduplication**: Ensures you never see the same job URL twice across multiple sync cycles.
3. **Application Tracking Dashboard**: Visualize your job search progress, move jobs between stages, and keep detailed records of your applications and interviews.
4. **Self-Hosted & Private**: Everything runs locally via Docker. You maintain 100% control over your data.
5. **Zero-Config Deployment**: A single `docker-compose` command spins up the database, the Node.js frontend, and the Python scraper instantly.

## 🚀 Quick Start (Developers)

You only need [Docker](https://www.docker.com/) installed and running.

1. **Clone the repository:**

   ```bash
   git clone --recurse-submodules <your-repo-url> job-sync-and-spy
   cd job-sync-and-spy
   ```

> [!TIP]
> **Forgot the `--recurse-submodules` flag?** Run `make init` to pull the missing frontend code.
>
> Want Git to always do this automatically? Run:
> `git config --global submodule.recurse true`

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

### How JobSpy and JobSync Automations Work Together

This project uses a "zero-conflict wrapper" approach to give you the best of both worlds without breaking upstream JobSync updates:

1. **JobSpy (Automated BACKGROUND Scraper):** Our custom Python scraper (`scraper/main.py`) runs fully autonomously in the background via a Docker container schedule. As long as you have an Automation with an `active` status in the dashboard, the Python scraper will periodically read those keywords and locations, pulling hundreds of jobs directly into your database.
2. **JobSync JSearch (Manual FOREGROUND Scraper):** The native JobSync application also has its own TypeScript scraper (using the JSearch API). This native scraper _only_ runs when you explicitly click the **"Run Now"** button in the dashboard.

You do not need to choose between them! JobSpy will continuously find jobs for you in the background for free, and you can still trigger JobSync's native JSearch scraper manually whenever you want a real-time pull.

### Running Locally (Sleep Mode)

If you are running this app locally on your laptop, the Python background scraper will **pause** whenever your computer goes to sleep or is closed.

This is perfectly fine! The moment you wake your computer up, Docker will resume the container and the Python scheduler will immediately execute a "catch up" scrape cycle for any scheduled runs it missed while you were asleep. If you want the scraper to run strictly 24/7 without interruption, you can easily host this exact `docker-compose.yml` stack on a cheap cloud VPS (like DigitalOcean, AWS, or Hetzner).

## Advanced Configuration (Environment Variables)

Both the Next.js frontend and Python scraper can be configured through environment variables. You can set them up by editing the `docker-compose.yml` file, or via `.env` files.

### Scraper Configuration (`docker-compose.yml`)

The scraper comes with a set of default parameters. You can tweak how aggressively it searches by modifying the `environment` section under the `scraper` service:

- `SCRAPER_RESULTS_WANTED`: Number of jobs to scrape per search term (Default: `20`)
- `SCRAPER_HOURS_OLD`: Maximum age of jobs to include, in hours (Default: `24`)
- `SCRAPER_COUNTRY`: The country localization to target (Default: `usa`)

_Example:_

```yaml
scraper:
  environment:
    - SCRAPER_RESULTS_WANTED=50
    - SCRAPER_HOURS_OLD=72
    - SCRAPER_COUNTRY=canada
```

### Frontend Configuration

The UI has several optional configurations for integrations. You can uncomment or add these variables under the `frontend` service in `docker-compose.yml`:

- `ENCRYPTION_KEY`: A secure string (used to encrypt stored API keys in the dashboard). Recommended to generate one with `openssl rand -base64 32`.
- `OPENAI_API_KEY`: Your OpenAI key, used for AI job skill and semantic extraction in the JobSync app.
- `DEEPSEEK_API_KEY`: Used as an alternative LLM to OpenAI.
- `OLLAMA_BASE_URL`: For connecting to local open-source LLMs hosted via Ollama.
- `TZ`: Your local timezone (Default: `America/Los_Angeles`).

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

## Troubleshooting

### Empty `frontend` Directory

If you cloned the repository without the `--recurse-submodules` flag, your `frontend` folder will be empty and `docker compose` will fail.

**Fix:** Run `make init` (or `git submodule update --init --recursive`) from the project root.

## Testing the Scraper

If you want to manually trigger the scraper instead of waiting for its scheduled cycle, you can run the following command from the root of the project:

```bash
make test-scrape
```

This will execute the Python script immediately inside the running scraper container and you can watch the output.
