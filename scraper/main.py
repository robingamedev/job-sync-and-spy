import os
import sys
import time
import uuid
import json
import logging
import schedule
import pandas as pd
from datetime import datetime
from sqlalchemy import create_engine, text
from jobspy import scrape_jobs

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger("scraper")

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    logger.error("No DATABASE_URL provided.")
    sys.exit(1)

# Remove Prisma specific parameters that break SQLAlchemy
if "?schema=" in DATABASE_URL:
    DATABASE_URL = DATABASE_URL.split("?schema=")[0]

# SQLAlchemy engine
engine = create_engine(DATABASE_URL)

def create_automation_run(conn, automation_id):
    run_id = str(uuid.uuid4())
    conn.execute(
        text("""
            INSERT INTO "AutomationRun" (id, "automationId", status, "startedAt")
            VALUES (:id, :autoId, 'running', :startedAt)
        """),
        {
            "id": run_id,
            "autoId": automation_id,
            "startedAt": datetime.utcnow()
        }
    )
    return run_id

def finish_automation_run(conn, run_id, status, searched=0, saved=0, error_message=None):
    try:
        conn.execute(
            text("""
                UPDATE "AutomationRun" 
                SET status = :status, "jobsSearched" = :searched, "jobsSaved" = :saved, 
                    "errorMessage" = :error, "completedAt" = :completedAt
                WHERE id = :id
            """),
            {
                "status": status,
                "searched": searched,
                "saved": saved,
                "error": error_message,
                "completedAt": datetime.utcnow(),
                "id": run_id
            }
        )
    except Exception as e:
        logger.error(f"Failed to update AutomationRun: {e}")

def get_or_create(conn, table, user_id, label, value):
    # Fetch existing
    result = conn.execute(
        text(f'SELECT id FROM "{table}" WHERE "createdBy" = :userId AND "value" = :value'),
        {"userId": user_id, "value": value}
    ).fetchone()

    if result:
        return result[0]

    # Create new
    new_id = str(uuid.uuid4())
    conn.execute(
        text(f'INSERT INTO "{table}" (id, label, value, "createdBy") VALUES (:id, :label, :value, :userId)'),
        {"id": new_id, "label": label, "value": value, "userId": user_id}
    )
    return new_id

def get_or_create_status(conn):
    result = conn.execute(text('SELECT id FROM "JobStatus" WHERE "value" = :value'), {"value": "discovery"}).fetchone()
    if result:
        return result[0]
    
    new_id = str(uuid.uuid4())
    conn.execute(
        text('INSERT INTO "JobStatus" (id, label, value) VALUES (:id, :label, :value)'),
        {"id": new_id, "label": "Discovery", "value": "discovery"}
    )
    return new_id

def process_job(conn, user_id, status_id, automation_id, job):
    job_url = job.get("job_url", "")
    if not job_url:
        return False # Need a URL for deduplication

    # Deduplicate against Job table
    exists = conn.execute(
        text('SELECT id FROM "Job" WHERE "userId" = :userId AND "jobUrl" = :jobUrl'),
        {"userId": user_id, "jobUrl": job_url}
    ).fetchone()

    if exists:
        return False

    # Safe string extractor
    def safe_str(val, default):
        if val is None:
            return default
        if isinstance(val, float) and pd.isna(val):
            return default
        val_str = str(val).strip()
        return val_str if val_str else default

    # Get relations
    company_name = safe_str(job.get("company"), "Unknown Company")
    company_id = get_or_create(conn, "Company", user_id, company_name, company_name.lower())

    title_name = safe_str(job.get("title"), "Unknown Title")
    title_id = get_or_create(conn, "JobTitle", user_id, title_name, title_name.lower())

    location_name = safe_str(job.get("location"), "Remote")
    location_id = get_or_create(conn, "Location", user_id, location_name, location_name.lower())

    job_source_name = safe_str(job.get("site"), "jobspy")
    source_id = get_or_create(conn, "JobSource", user_id, job_source_name, job_source_name.lower())

    # Insert Job
    job_id = str(uuid.uuid4())
    conn.execute(
        text("""
            INSERT INTO "Job" (
                id, "userId", "jobUrl", description, "jobType", "createdAt", applied, "statusId",
                "jobTitleId", "companyId", "jobSourceId", "salaryRange", "locationId", "discoveryStatus", "discoveredAt",
                "automationId"
            ) VALUES (
                :id, :userId, :jobUrl, :desc, :jobType, :createdAt, false, :statusId,
                :titleId, :companyId, :sourceId, :salary, :locationId, 'new', :createdAt,
                :automationId
            )
        """),
        {
            "id": job_id,
            "userId": user_id,
            "jobUrl": job_url,
            "desc": job.get("description", "No description provided.") or "No description provided.",
            "jobType": job.get("job_type", "fulltime") or "fulltime",
            "createdAt": datetime.utcnow(),
            "statusId": status_id,
            "titleId": title_id,
            "companyId": company_id,
            "sourceId": source_id,
            "salary": job.get("salary_source", None),
            "locationId": location_id,
            "automationId": automation_id
        }
    )
    return True

def run_scraper():
    logger.info("Starting scrape cycle...")
    try:
        with engine.begin() as conn:
            # Get all active automations
            automations = conn.execute(text('SELECT id, "userId", keywords, location, "jobBoard" FROM "Automation" WHERE status = \'active\'')).fetchall()
            
            if not automations:
                logger.info("No active automations found.")
                return

            status_id = get_or_create_status(conn)

            for auto_id, user_id, keywords, location, job_board in automations:
                run_id = None
                try:
                    logger.info(f"Running automation {auto_id} - Keywords: {keywords}, Location: {location}")
                    run_id = create_automation_run(conn, auto_id)
                    
                    if not keywords:
                        logger.warning(f"Automation {auto_id} has no keywords, skipping.")
                        finish_automation_run(conn, run_id, status='error', error_message="No keywords defined")
                        continue

                    # Fallback to general location if None
                    loc = location if location else "Remote"
                    
                    # Convert single string keywords to list if necessary, depending on how JobSync saves them.
                    # Usually JobSync saves keywords as comma separated strings in the DB.
                    terms = [k.strip() for k in keywords.split(",")] if "," in keywords else [keywords]
                    
                    total_found = 0
                    total_added = 0

                    for term in terms:
                        logger.info(f"Targeting: '{term}' in '{loc}' for user {user_id}")
                        
                        jobs = scrape_jobs(
                            site_name=["linkedin", "indeed", "glassdoor"],
                            search_term=term,
                            location=loc,
                            results_wanted=20,
                            hours_old=24, 
                            country_alice="usa"
                        )

                        if jobs is None or jobs.empty:
                            continue

                        total_found += len(jobs)
                        
                        # Convert DataFrame to dicts
                        for _, job_row in jobs.iterrows():
                            # job_row.to_dict() gives NaNs for empty cells, we must convert to None to avoid float errors
                            job_dict = {k: (None if pd.isna(v) else v) for k, v in job_row.to_dict().items()}
                            if process_job(conn, user_id, status_id, auto_id, job_dict):
                                total_added += 1
                                    
                    logger.info(f"Automation {auto_id} complete. Found {total_found}, Added {total_added}.")
                    finish_automation_run(conn, run_id, status='completed', searched=total_found, saved=total_added)

                except Exception as e:
                    logger.error(f"Error scraping automation {auto_id}: {e}")
                    if run_id:
                        finish_automation_run(conn, run_id, status='error', error_message=str(e)[:255])

    except Exception as e:
        logger.error(f"Critical Scraper Error: {e}")

if __name__ == "__main__":
    logger.info("Scraper container started. Running initial scrape...")
    run_scraper()
    
    # Run every 6 hours by default. Advanced scheduling should read from DB interval, but keeping KISS for now
    schedule.every(6).hours.do(run_scraper)

    while True:
        schedule.run_pending()
        time.sleep(60)
