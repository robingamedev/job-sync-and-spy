"Hey! I built a Python background worker that automatically looks at your Automation table and fulfills the generic JobSpy scrapes, logging everything to AutomationRun.

The Python script is completely database agnostic. It works out-of-the-box with your current SQLite setup for users spinning it up via npm run dev. However, because Python runs asynchronously, users running heavy/frequent scraping campaigns on SQLite might encounter 'Database Locked' concurrency errors.

To solve this for power-users, I've also included an optional

docker-compose.yml
file they can use which spins up the stack using PostgreSQL instead, virtually eliminating concurrency locks."
