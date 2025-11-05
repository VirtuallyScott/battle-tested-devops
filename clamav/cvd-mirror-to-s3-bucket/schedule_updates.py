#!/usr/bin/env python3
"""
ClamAV Database Update Scheduler

This script sets up and manages scheduled ClamAV database updates.
Supports cron-like scheduling and background execution.
"""

import argparse
import logging
import subprocess
import sys
import time
import threading
import signal
from datetime import datetime, timedelta
from pathlib import Path


def setup_logging(verbose=False):
    """Set up logging configuration."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler(f'scheduler_{datetime.now().strftime("%Y%m%d")}.log')
        ]
    )
    return logging.getLogger(__name__)


class DatabaseScheduler:
    """Scheduler for ClamAV database updates."""
    
    def __init__(self, interval_hours=4, verbose=False):
        self.interval_hours = interval_hours
        self.verbose = verbose
        self.logger = setup_logging(verbose)
        self.running = False
        self.thread = None
    
    def update_databases(self):
        """Perform database update."""
        self.logger.info("Starting scheduled database update...")
        
        try:
            # Use the update_databases.py script
            cmd = [sys.executable, 'update_databases.py']
            if self.verbose:
                cmd.append('-v')
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                self.logger.info("Scheduled database update completed successfully")
                if self.verbose and result.stdout:
                    self.logger.debug(f"Output: {result.stdout}")
            else:
                self.logger.error(f"Scheduled database update failed: {result.stderr}")
                
        except Exception as e:
            self.logger.error(f"Error during scheduled update: {e}")
    
    def run_scheduler(self):
        """Run the scheduler loop."""
        self.logger.info(f"Starting database update scheduler (interval: {self.interval_hours} hours)")
        
        while self.running:
            try:
                # Perform update
                self.update_databases()
                
                # Calculate next update time
                next_update = datetime.now() + timedelta(hours=self.interval_hours)
                self.logger.info(f"Next update scheduled for: {next_update.strftime('%Y-%m-%d %H:%M:%S')}")
                
                # Wait for the interval (in seconds)
                sleep_time = self.interval_hours * 3600
                
                # Sleep in chunks to allow for graceful shutdown
                elapsed = 0
                while elapsed < sleep_time and self.running:
                    time.sleep(min(60, sleep_time - elapsed))  # Sleep in 1-minute chunks
                    elapsed += 60
                    
            except Exception as e:
                self.logger.error(f"Error in scheduler loop: {e}")
                # Wait a bit before retrying
                time.sleep(300)  # 5 minutes
    
    def start(self):
        """Start the scheduler."""
        if self.running:
            self.logger.warning("Scheduler is already running")
            return
        
        self.running = True
        self.thread = threading.Thread(target=self.run_scheduler)
        self.thread.daemon = True
        self.thread.start()
        
        self.logger.info("Database update scheduler started")
    
    def stop(self):
        """Stop the scheduler."""
        if not self.running:
            self.logger.warning("Scheduler is not running")
            return
        
        self.logger.info("Stopping database update scheduler...")
        self.running = False
        
        if self.thread:
            self.thread.join(timeout=5)
        
        self.logger.info("Database update scheduler stopped")


def generate_cron_entry(interval_hours=4, script_path=None):
    """Generate a cron entry for database updates."""
    if script_path is None:
        script_path = Path(__file__).parent / "update_databases.py"
    
    # For simplicity, we'll schedule at fixed intervals
    # Convert hours to cron format (every N hours)
    if interval_hours == 1:
        cron_time = "0 * * * *"
    elif interval_hours == 2:
        cron_time = "0 */2 * * *"
    elif interval_hours == 4:
        cron_time = "30 */4 * * *"  # Default from cvdupdate docs
    elif interval_hours == 6:
        cron_time = "0 */6 * * *"
    elif interval_hours == 12:
        cron_time = "0 */12 * * *"
    elif interval_hours == 24:
        cron_time = "0 0 * * *"  # Daily at midnight
    else:
        # For other intervals, use the 4-hour default
        cron_time = "30 */4 * * *"
    
    python_path = sys.executable
    cron_entry = f"{cron_time} {python_path} {script_path} > /dev/null 2>&1"
    
    return cron_entry


def install_cron_job(interval_hours=4, verbose=False):
    """Install a cron job for database updates."""
    logger = setup_logging(verbose)
    
    script_path = Path(__file__).parent.absolute() / "update_databases.py"
    cron_entry = generate_cron_entry(interval_hours, script_path)
    
    logger.info(f"Generated cron entry: {cron_entry}")
    logger.info("To install this cron job manually:")
    logger.info("1. Run: crontab -e")
    logger.info(f"2. Add this line: {cron_entry}")
    logger.info("3. Save and exit")
    
    return cron_entry


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description='Schedule ClamAV database updates')
    parser.add_argument('-i', '--interval', type=int, default=4,
                       help='Update interval in hours (default: 4)')
    parser.add_argument('-v', '--verbose', action='store_true',
                       help='Enable verbose output')
    parser.add_argument('--daemon', action='store_true',
                       help='Run as background daemon')
    parser.add_argument('--cron', action='store_true',
                       help='Generate cron entry and exit')
    parser.add_argument('--once', action='store_true',
                       help='Run update once and exit')
    
    args = parser.parse_args()
    
    if args.cron:
        cron_entry = install_cron_job(args.interval, args.verbose)
        print(f"Cron entry: {cron_entry}")
        sys.exit(0)
    
    if args.once:
        # Run update once
        scheduler = DatabaseScheduler(args.interval, args.verbose)
        scheduler.update_databases()
        sys.exit(0)
    
    # Create scheduler
    scheduler = DatabaseScheduler(args.interval, args.verbose)
    
    # Set up signal handlers for graceful shutdown
    def signal_handler(sig, frame):
        scheduler.logger.info("Received shutdown signal")
        scheduler.stop()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        if args.daemon:
            # Run as daemon
            scheduler.start()
            
            # Keep the main thread alive
            while scheduler.running:
                time.sleep(1)
        else:
            # Run in foreground
            scheduler.start()
            scheduler.logger.info("Scheduler running in foreground. Press Ctrl+C to stop.")
            
            # Keep the main thread alive
            while True:
                time.sleep(1)
                
    except KeyboardInterrupt:
        scheduler.logger.info("Received keyboard interrupt")
        scheduler.stop()
        sys.exit(0)


if __name__ == '__main__':
    main()