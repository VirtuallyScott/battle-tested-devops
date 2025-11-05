#!/usr/bin/env python3
"""
S3 Sync Script for ClamAV Databases

This script syncs ClamAV database files to/from AWS S3 bucket.
Supports upload, download, dry-run, and force sync options.
"""

import argparse
import json
import logging
import os
import sys
from pathlib import Path
from datetime import datetime

import boto3
from botocore.exceptions import ClientError, NoCredentialsError
from env_setup import setup_environment


def setup_logging(verbose=False):
    """Set up logging configuration."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    return logging.getLogger(__name__)


def load_s3_config():
    """Load S3 configuration from environment variables or config file."""
    # Check for environment variables first (for command-line override)
    env_bucket = os.environ.get('S3_BUCKET_NAME')
    env_region = os.environ.get('S3_REGION')
    
    if env_bucket:
        # Use environment variables (command-line override)
        return {
            'bucket': env_bucket,
            'region': env_region or 'us-east-1',
            'prefix': 'clamav/databases/',
            'sync_enabled': True  # Assume enabled if bucket is provided via env
        }
    
    # Fall back to config file
    config_file = Path.home() / '.cvdupdate' / 's3_config.json'
    
    if not config_file.exists():
        return {
            'bucket': None,
            'region': 'us-east-1',
            'prefix': 'clamav/databases/',
            'sync_enabled': False
        }
    
    try:
        with open(config_file, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        return {
            'bucket': None,
            'region': 'us-east-1', 
            'prefix': 'clamav/databases/',
            'sync_enabled': False
        }


def get_database_directory():
    """Get the database directory from cvdupdate config."""
    setup_environment()
    
    # Try to get from cvdupdate config
    config_dir = Path.home() / '.cvdupdate'
    config_file = config_dir / 'config.json'
    
    if config_file.exists():
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
                return Path(config.get('database_directory', config_dir / 'database'))
        except (json.JSONDecodeError, KeyError):
            pass
    
    # Default location
    return config_dir / 'database'


def create_s3_client(region):
    """Create S3 client with proper region."""
    try:
        return boto3.client('s3', region_name=region)
    except NoCredentialsError:
        raise Exception("AWS credentials not found. Please configure with 'aws configure' or set environment variables.")


def get_local_files(db_dir, logger):
    """Get list of local database files to sync."""
    if not db_dir.exists():
        logger.warning(f"Database directory does not exist: {db_dir}")
        return []
    
    # ClamAV database file patterns
    # Include main databases, incremental updates, signatures, and other ClamAV files
    patterns = [
        '*.cvd',     # ClamAV database files
        '*.cld',     # ClamAV database files (alternative format)
        '*.cdiff',   # Incremental update files (critical for freshclam)
        '*.sign',    # Signature verification files
        '*.dat',     # Additional database files
        '*.inc',     # Include files
        '*.txt',     # Text files (like dns.txt)
        '*.info',    # Info files
        '*.cfg'      # Config files
    ]
    files = []
    
    for pattern in patterns:
        files.extend(db_dir.glob(pattern))
    
    # Also include state and config files
    state_files = [
        db_dir.parent / 'state.json',
        db_dir.parent / 'config.json'
    ]
    
    for state_file in state_files:
        if state_file.exists():
            files.append(state_file)
    
    logger.info(f"Found {len(files)} local files to potentially sync")
    return files


def upload_to_s3(s3_client, bucket, prefix, local_files, force=False, dry_run=False, logger=None):
    """Upload local files to S3."""
    if not local_files:
        logger.warning("No local files to upload")
        return True
    
    success_count = 0
    total_files = len(local_files)
    
    for local_file in local_files:
        # Calculate S3 key
        relative_path = local_file.name
        if local_file.parent.name == '.cvdupdate':
            relative_path = f"metadata/{local_file.name}"
        
        s3_key = f"{prefix}{relative_path}".replace('//', '/')
        
        try:
            # Check if file should be uploaded
            should_upload = force
            
            if not force:
                try:
                    # Get S3 object metadata
                    response = s3_client.head_object(Bucket=bucket, Key=s3_key)
                    s3_modified = response['LastModified'].timestamp()
                    local_modified = local_file.stat().st_mtime
                    
                    should_upload = local_modified > s3_modified
                    if not should_upload:
                        logger.debug(f"Skipping {local_file.name} (S3 version is newer)")
                        continue
                        
                except ClientError as e:
                    if e.response['Error']['Code'] == '404':
                        should_upload = True  # File doesn't exist in S3
                    else:
                        raise
            
            if should_upload:
                if dry_run:
                    logger.info(f"[DRY RUN] Would upload: {local_file.name} -> s3://{bucket}/{s3_key}")
                else:
                    logger.info(f"Uploading: {local_file.name} -> s3://{bucket}/{s3_key}")
                    s3_client.upload_file(str(local_file), bucket, s3_key)
                
                success_count += 1
            
        except ClientError as e:
            logger.error(f"Failed to upload {local_file.name}: {e}")
            continue
    
    if not dry_run:
        logger.info(f"Successfully uploaded {success_count}/{total_files} files to S3")
    else:
        logger.info(f"[DRY RUN] Would upload {success_count}/{total_files} files to S3")
    
    return success_count == total_files


def download_from_s3(s3_client, bucket, prefix, db_dir, force=False, dry_run=False, logger=None):
    """Download files from S3 to local directory."""
    try:
        # List objects in S3
        response = s3_client.list_objects_v2(Bucket=bucket, Prefix=prefix)
        
        if 'Contents' not in response:
            logger.warning(f"No files found in S3 bucket {bucket} with prefix {prefix}")
            return True
        
        db_dir.mkdir(parents=True, exist_ok=True)
        success_count = 0
        total_files = len(response['Contents'])
        
        for obj in response['Contents']:
            s3_key = obj['Key']
            relative_path = s3_key[len(prefix):].lstrip('/')
            
            # Handle metadata files
            if relative_path.startswith('metadata/'):
                local_file = db_dir.parent / relative_path[9:]  # Remove 'metadata/' prefix
            else:
                local_file = db_dir / relative_path
            
            # Check if file should be downloaded
            should_download = force
            
            if not force and local_file.exists():
                s3_modified = obj['LastModified'].timestamp()
                local_modified = local_file.stat().st_mtime
                should_download = s3_modified > local_modified
                
                if not should_download:
                    logger.debug(f"Skipping {relative_path} (local version is newer)")
                    continue
            
            if should_download:
                if dry_run:
                    logger.info(f"[DRY RUN] Would download: s3://{bucket}/{s3_key} -> {local_file}")
                else:
                    logger.info(f"Downloading: s3://{bucket}/{s3_key} -> {local_file}")
                    local_file.parent.mkdir(parents=True, exist_ok=True)
                    s3_client.download_file(bucket, s3_key, str(local_file))
                
                success_count += 1
        
        if not dry_run:
            logger.info(f"Successfully downloaded {success_count}/{total_files} files from S3")
        else:
            logger.info(f"[DRY RUN] Would download {success_count}/{total_files} files from S3")
        
        return True
        
    except ClientError as e:
        logger.error(f"Failed to download from S3: {e}")
        return False


def test_s3_connection(s3_client, bucket, logger):
    """Test S3 connection and bucket access."""
    try:
        logger.info(f"Testing connection to S3 bucket: {bucket}")
        
        # Test bucket access
        response = s3_client.head_bucket(Bucket=bucket)
        logger.info(f"✓ Bucket accessible: {bucket}")
        logger.info(f"✓ Bucket region: {response.get('BucketRegion', 'unknown')}")
        
        # Test list permissions
        try:
            response = s3_client.list_objects_v2(Bucket=bucket, MaxKeys=1)
            logger.info("✓ List objects permission confirmed")
        except ClientError as e:
            if e.response['Error']['Code'] == 'AccessDenied':
                logger.warning("⚠ Limited list permissions (may still work for upload/download)")
            else:
                raise
        
        logger.info("✓ S3 connection test successful")
        return True
        
    except ClientError as e:
        logger.error(f"✗ S3 connection test failed: {e}")
        return False


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description='Sync ClamAV databases with S3')
    parser.add_argument('-v', '--verbose', action='store_true',
                       help='Enable verbose output')
    
    # Sync direction
    action_group = parser.add_mutually_exclusive_group()
    action_group.add_argument('--upload', action='store_true',
                             help='Upload local databases to S3')
    action_group.add_argument('--download', action='store_true',
                             help='Download databases from S3 to local')
    action_group.add_argument('--test-connection', action='store_true',
                             help='Test S3 connection and permissions')
    
    # Options
    parser.add_argument('--force', action='store_true',
                       help='Force sync (ignore timestamps)')
    parser.add_argument('--dry-run', action='store_true',
                       help='Show what would be synced without actually doing it')
    
    args = parser.parse_args()
    
    logger = setup_logging(args.verbose)
    
    # Load S3 configuration
    s3_config = load_s3_config()
    
    if not s3_config['bucket']:
        logger.error("S3 bucket not configured. Use: config_manager.py set-s3-bucket <bucket-name>")
        sys.exit(1)
    
    if not s3_config['sync_enabled']:
        logger.error("S3 sync is disabled. Use: config_manager.py set-s3-sync enabled")
        sys.exit(1)
    
    # Create S3 client
    try:
        s3_client = create_s3_client(s3_config['region'])
    except Exception as e:
        logger.error(f"Failed to create S3 client: {e}")
        sys.exit(1)
    
    # Test connection if requested
    if args.test_connection:
        success = test_s3_connection(s3_client, s3_config['bucket'], logger)
        sys.exit(0 if success else 1)
    
    # Get database directory
    db_dir = get_database_directory()
    
    # Default action is upload
    if not args.download:
        args.upload = True
    
    if args.upload:
        logger.info("Starting S3 upload...")
        local_files = get_local_files(db_dir, logger)
        success = upload_to_s3(
            s3_client, 
            s3_config['bucket'], 
            s3_config['prefix'], 
            local_files,
            force=args.force,
            dry_run=args.dry_run,
            logger=logger
        )
    else:  # download
        logger.info("Starting S3 download...")
        success = download_from_s3(
            s3_client,
            s3_config['bucket'],
            s3_config['prefix'],
            db_dir,
            force=args.force,
            dry_run=args.dry_run,
            logger=logger
        )
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()