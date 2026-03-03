.PHONY: test-scrape

# Run a manual test scrape cycle inside the running container
test-scrape:
	docker exec job-sync-and-spy-scraper-1 python main.py
