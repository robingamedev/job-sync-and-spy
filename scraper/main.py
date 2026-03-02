import os
import sys
import time
import uuid
import json
import logging
import schedule
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

def log_to_db(level, source, message, details=None):
    try:
        with engine.begin() as conn:
            conn.execute(
                text("""
                    INSERT INTO "SystemLog" (id, level, source, message, details, "createdAt")
                    VALUES (:id, :level, :source, :message, :details, :createdAt)
                """),
                {
                    "id": str(uuid.uuid4()),
                    "level": level,
                    "source": source,
                    "message": message,
                    "details": json.dumps(details) if details else None,
                    "createdAt": datetime.utcnow()
                }
            )
            logger.info(f"DB LOG ({level}): {message}")
    except Exception as e:
        logger.error(f"Failed to write to SystemLog: {e}")

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

def process_job(conn, user_id, status_id, job):
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

    # Get relations
    company_name = job.get("company", "Unknown Company")
    company_id = get_or_create(conn, "Company", user_id, company_name, company_name.lower())

    title_name = job.get("title", "Unknown Title")
    title_id = get_or_create(conn, "JobTitle", user_id, title_name, title_name.lower())

    location_name = job.get("location", "Remote")
    location_id = get_or_create(conn, "Location", user_id, location_name, location_name.lower())

    job_source_name = job.get("site", "jobspy")
    source_id = get_or_create(conn, "JobSource", user_id, job_source_name, job_source_name.lower())

    # Insert Job
    job_id = str(uuid.uuid4())
    conn.execute(
        text("""
            INSERT INTO "Job" (
                id, "userId", "jobUrl", description, "jobType", "createdAt", applied, "statusId",
                "jobTitleId", "companyId", "jobSourceId", "salaryRange", "locationId", "discoveryStatus", "discoveredAt"
            ) VALUES (
                :id, :userId, :jobUrl, :desc, :jobType, :createdAt, false, :statusId,
                :titleId, :companyId, :sourceId, :salary, :locationId, 'new', :createdAt
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
            "locationId": location_id
        }
    )
    return True

def run_scraper():
    logger.info("Starting scrape cycle...")
    try:
        with engine.connect() as conn:
            # Get all active user settings
            settings_rows = conn.execute(text('SELECT "userId", "searchTerms", "searchLocations" FROM "PocketSpySettings" WHERE "isActive" = true')).fetchall()
            
            if not settings_rows:
                logger.info("No active users configured for scraping.")
                return

            status_id = get_or_create_status(conn)

            for user_id, terms_json, locations_json in settings_rows:
                try:
                    search_terms = json.loads(terms_json) if terms_json else []
                    search_locations = json.loads(locations_json) if locations_json else []

                    if not search_terms:
                        continue

                    # Fallback to general location if None
                    if not search_locations:
                        search_locations = ["Remote"]

                    for term in search_terms:
                        for location in search_locations:
                            logger.info(f"Targeting: {term} in {location} for user {user_id}")
                            
                            jobs = scrape_jobs(
                                site_name=["linkedin", "indeed", "glassdoor"],
                                search_term=term,
                                location=location,
                                results_wanted=20,
                                hours_old=24, 
                                country_alice="usa"
                            )

                            if jobs is None or jobs.empty:
                                continue

                            added_count = 0
                            # Convert DataFrame to dicts
                            for _, job_row in jobs.iterrows():
                                job_dict = job_row.to_dict()
                                # ensure db transaction commits
                                with engine.begin() as transaction_conn:
                                    if process_job(transaction_conn, user_id, status_id, job_dict):
                                        added_count += 1
                                        
                            log_to_db("info", "scraper", f"Scraped {added_count} new jobs for '{term}'", {"term": term, "found": len(jobs), "added": added_count})

                except Exception as e:
                    logger.error(f"Error scraping for user {user_id}: {e}")
                    log_to_db("error", "scraper", f"Scraping failed for user {user_id}", {"error": str(e)})

    except Exception as e:
        logger.error(f"Critical Scraper Error: {e}")
        log_to_db("error", "scraper", "Critical scraper loop failure", {"error": str(e)})

if __name__ == "__main__":
    logger.info("Scraper container started. Running initial scrape...")
    run_scraper()
    
    # Run every 6 hours by default. Advanced scheduling should read from DB interval, but keeping KISS for now
    schedule.every(6).hours.do(run_scraper)

    while True:
        schedule.run_pending()
        time.sleep(60)
