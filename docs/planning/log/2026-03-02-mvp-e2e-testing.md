# Development Log: Launching the Prototype Stack & End-to-End Testing

**Date:** 2026-03-02

## Overview

Following the theoretical architecture planning from the earlier setup phase, we deployed the PocketSpy Stack locally using Docker Compose to see if the standalone JobSync frontend could successfully interoperate with our custom Python `jobspy` scraper via the shared Postgres schema. We put the app through a full end-to-end user evaluation, starting from repository cloning to initiating an active scraping job.

## What We Accomplished

- Wrote the root `README.md` defining the "Zero-Config" setup guide for the project.
- Successfully aligned the frontend to map container port 3000 to the preferred user port 3737 in `docker-compose.yml`.
- Re-activated and executed the Python Scraper against a new live Search Automation injected from the frontend UI.
- Identified multiple critical integration errors bridging the Next.js frontend to the python jobs system.

## Challenges & Fixes

### 1. The NextAuth UntrustedHost Error

#### The Problem

After mapping the frontend container to port 3737, the JobSync Next.js application allowed account creation but silently failed the user login flow without any visual UI feedback. The Next.js container logs revealed an `UntrustedHost` exception deep inside Auth.js (NextAuth), rejecting the authentication payload because it came from `localhost:3737` whereas Next.js internally thought it was running strictly on `localhost:3000`.

#### The Solution

We injected two critical environment variables into the frontend configuration in `docker-compose.yml`:

- `AUTH_TRUST_HOST=true` (disabling strict Host header equivalence)
- `NEXTAUTH_URL=http://localhost:3737` (telling Auth.js the absolute root path to safely callback to)

### 2. The Python JobSpy NaN Crash

#### The Problem

When testing a new Automation (Keywords: `hospitality, manager, hotel`), the Python Jobspy container repeatedly crashed during the database ingestion phase with `AttributeError: 'float' object has no attribute 'lower'`. The crash was originating inside `job_row.to_dict()` whenever the scraper ingested a listing that happened to miss a location string, causing Pandas to output mathematical `NaN` floats instead of empty strings. The subsequent `.lower()` string cast against the Postgres relation checker broke the script.

#### The Solution

We implemented a rigid typecasting helper function (`safe_str`) into `scraper/main.py`. This explicitly checks for `isinstance(val, float) and pd.isna(val)` prior to attempting Postgres insertion, successfully coercing all blank scraped values gracefully into fallbacks (e.g., `Unknown Company`).

## New Knowledge

- **The JobSync API:** Before incorporating PocketSpy, the base JobSync frontend was architected to rely on the paid RapidAPI/JSearch endpoint for pulling job data (triggering directly from a Vercel cron or the Next.js internals). Our Python container effectively intercepts this entire loop securely at the database level.
- **Python DataFrame Quirks:** Passing dataframes directly into relational PostgreSQL scripts via `to_dict` requires significant sanitation layers due to Pandas treating empty scraped cells as floats rather than NoneTypes or empty strings.

## Key Takeaways

The baseline MVP architecture works seamlessly. A single Postgres configuration effectively pairs two wholly separate container ecosystems (Next.js vs Python), providing users an instantaneous self-hosted environment without tedious configuration loops. As a primary next step, we've identified the need to un-hardcode parameters from the Python script (e.g., hours_old, job limits, and specific job boards) into environmental configurations for tighter granular control.
