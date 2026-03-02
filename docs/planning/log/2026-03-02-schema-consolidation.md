# Development Log: Upstream Schema Consolidation

**Date:** 2026-03-02

## Overview

We resolved a major architectural divergence by decoupling the PocketSpy Stack from a custom Prisma schema and realigning it entirely with the upstream JobSync project's database schema. The Python scraper was refactored to act as a headless worker that natively interacts with JobSync's `Automation` and `AutomationRun` tables.

## What We Accomplished

1. **Schema Reversion**: Removed `PocketSpySettings` and `SystemLog` models from `frontend/prisma/schema.prisma` to prevent permanent schema forks from the upstream JobSync repo.
2. **Database Migration**: Generated and applied the `remove_pocketspy_schema` Prisma migration within the frontend Docker container.
3. **Scraper Refactor**: Rewrote `scraper/main.py` to pull its scraping directives (keywords, locations) dynamically from active rows in the JobSync `Automation` table, rather than a custom settings table.
4. **Data Contract Realignment**: Updated the Python scraper to save its execution logs and telemetry directly to the `AutomationRun` table, and correctly link scraped `Job` records back to their parent `Automation` via the `automationId` foreign key.
5. **Upstream Strategy**: Documented the strategy for pitching the Python scraper back to the main JobSync repository, emphasizing its database-agnostic design (SQLAlchemy) and the `docker-compose` PostgreSQL setup as a power-user alternative to their default SQLite implementation.

## Challenges & Fixes

### The Problem

During the Prisma migration, the backend container did not immediately register the changes to `schema.prisma`. Furthermore, the Python scraper continued to crash looking for the deleted tables even after the code was rewritten.

### The Solution

Because the Docker Compose environment uses a `build` step for the containers rather than a live volume bind-mount, we had to fully force a rebuild of both the `frontend` and `scraper` Docker images (`docker compose build`) to inject the modified schema and the updated `main.py` code into the virtualized environments before restarting them.

## New Knowledge

- The JobSync upstream project already possesses highly robust data models (`Automation`, `AutomationRun`, `ApiKey`) that perfectly map to our scraper needs, eliminating the need to build any custom React UI dashboards for Milestone 4.
- Prisma migration histories (`migration_lock.toml`) are strictly tied to specific database providers. Swapping from `sqlite` to `postgresql` requires generating a completely fresh migrations folder, which we safely managed.

## Key Takeaways

- **Reuse Over Reinvention**: By mapping our data to existing upstream tables, we drastically reduced our own UI workload and maintained perfect code compatibility with the parent repository.
- **Architectural Flexibility**: The Python scraper remains completely database-agnostic. It continues to work seamlessly with JobSync's default SQLite setup for beginner users, while our local Docker deployment leverages PostgreSQL to prevent database locks for heavy workloads.
