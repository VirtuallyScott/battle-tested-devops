#!/usr/bin/env python3
"""
ClamAV Database Mirror Server

This script serves the ClamAV database directory as an HTTP mirror.
Useful for testing with FreshClam and providing local database access.
"""

import argparse
import logging
import subprocess
import sys
import signal
import os
from pathlib import Path
from env_setup import setup_environment, get_cvd_command


def setup_logging(verbose=False):
    """Set up logging configuration."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    return logging.getLogger(__name__)


def run_cvd_serve(port=8000, verbose=False):
    """Start the CVD serve command."""
    logger = setup_logging(verbose)
    
    logger.info(f"Starting ClamAV database mirror server on port {port}...")
    logger.info("Press Ctrl+C to stop the server")
    
    setup_environment()
    
    # Build serve command
    cvd_cmd = get_cvd_command()
    if isinstance(cvd_cmd, list):
        command = cvd_cmd + ['serve']
    else:
        command = [cvd_cmd, 'serve']
        
    if verbose:
        command.append('-V')
    
    try:
        # Start the server process
        process = subprocess.Popen(command, stdout=subprocess.PIPE, 
                                 stderr=subprocess.PIPE, text=True)
        
        def signal_handler(sig, frame):
            logger.info("Stopping server...")
            process.terminate()
            sys.exit(0)
        
        signal.signal(signal.SIGINT, signal_handler)
        
        # Wait for process to complete
        stdout, stderr = process.communicate()
        
        if process.returncode == 0:
            logger.info("Server stopped successfully")
        else:
            logger.error(f"Server failed with return code {process.returncode}")
            if stderr:
                logger.error(f"Error: {stderr}")
        
        return process.returncode == 0
        
    except FileNotFoundError:
        logger.error("cvd command not found. Make sure cvdupdate is installed.")
        return False
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
        return True


def get_database_directory():
    """Get the current database directory from config."""
    try:
        setup_environment()
        cvd_cmd = get_cvd_command()
        
        if isinstance(cvd_cmd, list):
            cmd = cvd_cmd + ['config', 'show']
        else:
            cmd = [cvd_cmd, 'config', 'show']
            
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        
        # Parse the config output to find database directory
        for line in result.stdout.split('\n'):
            if 'database' in line.lower() and 'dir' in line.lower():
                # Extract directory path from the line
                parts = line.split(':')
                if len(parts) > 1:
                    return parts[1].strip().strip('"')
        
        # Default path if not found in config
        return os.path.expanduser("~/.cvdupdate/databases")
        
    except subprocess.CalledProcessError:
        # Return default path if config command fails
        return os.path.expanduser("~/.cvdupdate/databases")


def check_database_directory():
    """Check if database directory exists and has content."""
    db_dir = get_database_directory()
    db_path = Path(db_dir)
    
    if not db_path.exists():
        return False, f"Database directory does not exist: {db_dir}"
    
    # Check for .cvd files
    cvd_files = list(db_path.glob("*.cvd"))
    if not cvd_files:
        return False, f"No .cvd files found in {db_dir}. Run update_databases.py first."
    
    return True, f"Found {len(cvd_files)} database files in {db_dir}"


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description='Serve ClamAV databases as HTTP mirror')
    parser.add_argument('-p', '--port', type=int, default=8000,
                       help='Port to serve on (default: 8000)')
    parser.add_argument('-v', '--verbose', action='store_true',
                       help='Enable verbose output')
    parser.add_argument('--check', action='store_true',
                       help='Check database directory and exit')
    
    args = parser.parse_args()
    
    logger = setup_logging(args.verbose)
    
    # Check database directory
    exists, message = check_database_directory()
    if args.check:
        print(message)
        sys.exit(0 if exists else 1)
    
    if not exists:
        logger.error(message)
        logger.info("Please run 'python update_databases.py' first to download databases")
        sys.exit(1)
    
    logger.info(message)
    
    # Start the server
    success = run_cvd_serve(args.port, args.verbose)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()