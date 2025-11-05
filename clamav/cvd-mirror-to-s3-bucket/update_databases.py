#!/usr/bin/env python3
"""
ClamAV Database Update Script

This script downloads and updates ClamAV databases using the cvdupdate library.
It provides options for verbose output, custom configuration, and error handling.
"""

import argparse
import logging
import sys
import subprocess
import json
from pathlib import Path
from datetime import datetime
from env_setup import setup_environment, get_cvd_command


def setup_logging(verbose=False):
    """Set up logging configuration."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler(f'update_{datetime.now().strftime("%Y%m%d")}.log')
        ]
    )
    return logging.getLogger(__name__)


def run_cvd_command(command, verbose=False):
    """Run a cvd command and return the result."""
    setup_environment()
    
    cvd_cmd = get_cvd_command()
    if isinstance(cvd_cmd, list):
        cmd = cvd_cmd + command
    else:
        cmd = [cvd_cmd] + command
        
    if verbose:
        cmd.append('-V')
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return result.stdout, result.stderr, 0
    except subprocess.CalledProcessError as e:
        return e.stdout, e.stderr, e.returncode


def s3_sync_databases(verbose=False, s3_bucket=None, s3_region=None, dry_run=False):
    """Sync databases to S3 after update."""
    logger = setup_logging(verbose)
    
    # If bucket is provided via command line, use it directly
    if s3_bucket:
        logger.info(f"Using S3 bucket from command line: {s3_bucket}")
        bucket_name = s3_bucket
        region = s3_region or 'us-east-1'  # Default region if not specified
    else:
        # Check if S3 sync is enabled via config file
        s3_config_file = Path.home() / '.cvdupdate' / 's3_config.json'
        
        if not s3_config_file.exists():
            logger.warning("S3 configuration not found and no bucket specified. Use config_manager.py to configure S3 settings or specify --s3-bucket-name.")
            return False
        
        try:
            with open(s3_config_file, 'r') as f:
                s3_config = json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            logger.error("Failed to read S3 configuration")
            return False
        
        if not s3_config.get('sync_enabled', False):
            logger.warning("S3 sync is disabled. Use: config_manager.py set-s3-sync enabled")
            return False
        
        if not s3_config.get('bucket'):
            logger.error("S3 bucket not configured. Use: config_manager.py set-s3-bucket <bucket-name> or specify --s3-bucket-name")
            return False
        
        bucket_name = s3_config.get('bucket')
        region = s3_config.get('region', 'us-east-1')
    
    logger.info(f"Starting S3 sync to bucket: {bucket_name} (region: {region})")
    
    # Run s3_sync.py script
    script_dir = Path(__file__).parent
    s3_sync_script = script_dir / 's3_sync.py'
    
    if not s3_sync_script.exists():
        logger.error(f"S3 sync script not found: {s3_sync_script}")
        return False
    
    try:
        cmd = [sys.executable, str(s3_sync_script), '--upload']
        if verbose:
            cmd.append('--verbose')
        if dry_run:
            cmd.append('--dry-run')
        
        # Set environment variables for S3 configuration
        import os
        env = os.environ.copy()
        env['S3_BUCKET_NAME'] = bucket_name
        env['S3_REGION'] = region
        
        logger.info(f"Running S3 sync: {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True, text=True, check=True, env=env)
        
        if verbose and result.stdout:
            logger.info(f"S3 sync output: {result.stdout}")
        
        logger.info("S3 sync completed successfully")
        return True
        
    except subprocess.CalledProcessError as e:
        logger.error(f"S3 sync failed with return code {e.returncode}")
        if e.stderr:
            logger.error(f"S3 sync error: {e.stderr}")
        if e.stdout:
            logger.error(f"S3 sync output: {e.stdout}")
        return False
    except Exception as e:
        logger.error(f"Failed to run S3 sync: {e}")
        return False


def update_databases(verbose=False, config_file=None, s3_sync=False, s3_bucket=None, s3_region=None, dry_run=False):
    """Update ClamAV databases."""
    logger = setup_logging(verbose)
    
    logger.info("Starting ClamAV database update...")
    
    # Build update command
    command = ['update']
    
    # Run the update
    stdout, stderr, returncode = run_cvd_command(command, verbose)
    
    if returncode == 0:
        logger.info("Database update completed successfully")
        if verbose and stdout:
            logger.debug(f"Output: {stdout}")
        
        # Sync to S3 if requested and update was successful
        if s3_sync:
            s3_success = s3_sync_databases(verbose, s3_bucket, s3_region, dry_run)
            if not s3_success:
                logger.warning("Database update succeeded but S3 sync failed")
                return False  # Return False if S3 sync was requested but failed
    else:
        logger.error(f"Database update failed with return code {returncode}")
        if stderr:
            logger.error(f"Error: {stderr}")
        if stdout:
            logger.error(f"Output: {stdout}")
    
    return returncode == 0


def list_databases(verbose=False):
    """List current databases."""
    logger = setup_logging(verbose)
    
    logger.info("Listing current databases...")
    
    stdout, stderr, returncode = run_cvd_command(['list'], verbose)
    
    if returncode == 0:
        logger.info("Database list:")
        if stdout:
            print(stdout)
    else:
        logger.error(f"Failed to list databases: {stderr}")
    
    return returncode == 0


def show_config():
    """Show current configuration."""
    stdout, stderr, returncode = run_cvd_command(['config', 'show'])
    
    if returncode == 0:
        print("Current CVD Configuration:")
        print(stdout)
    else:
        print(f"Failed to show configuration: {stderr}")
    
    return returncode == 0


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description='Update ClamAV databases using cvdupdate')
    parser.add_argument('-v', '--verbose', action='store_true', 
                       help='Enable verbose output')
    parser.add_argument('-l', '--list', action='store_true',
                       help='List current databases')
    parser.add_argument('-c', '--config', action='store_true',
                       help='Show current configuration')
    parser.add_argument('--config-file', type=str,
                       help='Path to custom config file')
    parser.add_argument('--s3-sync', action='store_true',
                       help='Sync databases to S3 after successful update')
    parser.add_argument('--s3-bucket-name', type=str,
                       help='S3 bucket name for sync (overrides config file)')
    parser.add_argument('--s3-region', type=str,
                       help='S3 region for sync (default: us-east-1)')
    parser.add_argument('--dry-run', action='store_true',
                       help='Show what would be uploaded without actually uploading')
    
    args = parser.parse_args()
    
    # Validate S3 arguments
    if (args.s3_bucket_name or args.s3_region) and not args.s3_sync:
        parser.error("--s3-bucket-name and --s3-region require --s3-sync")
    
    if args.list:
        success = list_databases(args.verbose)
        sys.exit(0 if success else 1)
    
    if args.config:
        success = show_config()
        sys.exit(0 if success else 1)
    
    # Default action: update databases
    success = update_databases(args.verbose, args.config_file, args.s3_sync, 
                              args.s3_bucket_name, args.s3_region, args.dry_run)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()