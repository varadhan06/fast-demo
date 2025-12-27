#!/usr/bin/env python3
import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    logger.info("Background worker started")
    while True:
        logger.info("Worker is running...")
        time.sleep(30)  # Do work every 30 seconds

if __name__ == "__main__":
    main()