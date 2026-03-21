.PHONY: test-scrape init

# Initialize submodules (useful if cloned without --recurse-submodules)
init:
	git submodule update --init --recursive

# Run a manual test scrape cycle inside the running container
test-scrape:
	docker exec job-sync-and-spy-scraper-1 python main.py
