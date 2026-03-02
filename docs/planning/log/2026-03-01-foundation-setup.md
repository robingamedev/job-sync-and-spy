# Development Log: Foundation & Scraper Setup

**Date:** 2026-03-01

## Overview

Successfully laid the groundwork for the PocketSpy Stack, establishing the "Zero-Config" Docker Compose environment, setting up the Next.js frontend (forked from JobSync), migrating the database from SQLite to PostgreSQL, and writing the initial Producer Python Scraper.

## What We Accomplished

1. **Architecture Planning**: Discussed and documented core architecture, codebase rules, and AI agent boundaries (`docs/project.md`, `docs/rules.md`).
2. **Infrastructure setup**: Initialized a `docker-compose.yml` to orchestrate a PostgreSQL database alongside the Next.js frontend.
3. **Frontend Integration**: Cloned the JobSync base frontend and updated its Prisma schema to use `postgresql` instead of `sqlite`.
4. **Data Modeling**: Extended the JobSync Prisma schema with `PocketSpySettings` and `SystemLog` to support the scraper and AI capabilities, including critical unique constraints to prevent job application duplication.
5. **Database Initialization**: Rebuilt the frontend container to apply the new Prisma migrations to PostgreSQL safely on boot via `migrate deploy`.
6. **Scraper Build**: Wrote the Python scraper (`main.py`) which periodically fetches user configurations from PostgreSQL, scrapes job boards using `jobspy`, and inserts deduplicated job entries back into the DB adhering to the Prisma schema's FK constraints.

## Challenges & Fixes

### The Problem

During the initialization of the Next.js frontend, Prisma threw the error `P3019` complaining that the provider inside the `schema.prisma` (`postgresql`) did not match the provider in `migration_lock.toml` (`sqlite`).

### The Solution

We temporarily removed the existing `frontend/prisma/migrations` folder originally built for SQLite and spawned a temporary Node.js container within the Docker network to run `npx prisma migrate dev --name init`. This rebuilt the migration history specifically compiled for PostgreSQL.

### The Problem

The Python scraper container encountered a `psycopg2.ProgrammingError: invalid connection option "schema"`.

### The Solution

The Prisma Next.js environment explicitly injects `?schema=public` into `DATABASE_URL`, which is unsupported by Python's `psycopg2` and `SQLAlchemy`. Added a quick string manipulation to strip out `?schema` before the SQLAlchemy engine creation in `main.py`.

## New Knowledge

- In "Zero-Config" local Docker architectures, keeping migrations pristine is crucial. `prisma migrate deploy` is much safer than `db push` to prevent unintentional column drops during user updates.
- Python ORMs strictly parsing Prisma connection strings require slight scrubbing on the `DATABASE_URL` specifically for parameters like `schema`.

## Key Takeaways

- The database is the only bridge necessary between decoupled microservices (Producer Python / Consumer Next.js).
- Hardcoding the PostgreSQL credentials in the docker-compose file for a purely local context eliminates user friction with `.env` files, hitting the project's primary "KISS" goal.
