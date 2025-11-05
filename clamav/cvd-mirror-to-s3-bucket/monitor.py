#!/usr/bin/env python3
"""
ClamAV Database Health Monitor

This script monitors the health and status of ClamAV databases,
checking for outdated files, missing databases, and other issues.
"""

import argparse
import json
import logging
import subprocess
import sys
from datetime import datetime, timedelta
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


def get_config_data():
    """Get configuration data from cvdupdate."""
    try:
        setup_environment()
        cvd_cmd = get_cvd_command()
        
        if isinstance(cvd_cmd, list):
            cmd = cvd_cmd + ['config', 'show']
        else:
            cmd = [cvd_cmd, 'config', 'show']
        
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        
        # Parse configuration
        config = {}
        lines = result.stdout.split('\n')
        in_config = False
        
        for line in lines:
            if 'Config:' in line:
                in_config = True
                continue
            elif 'State file:' in line:
                in_config = False
                continue
            
            if in_config and ':' in line:
                key, value = line.split(':', 1)
                key = key.strip().strip('"')
                value = value.strip().strip('",')
                config[key] = value
        
        return config
    except Exception as e:
        return {}


def get_state_data():
    """Get state data from cvdupdate."""
    try:
        config = get_config_data()
        state_file = config.get('state file', '~/.cvdupdate/state.json')
        state_path = Path(state_file).expanduser()
        
        if state_path.exists():
            with open(state_path, 'r') as f:
                return json.load(f)
    except Exception as e:
        pass
    
    return {}


def check_database_files():
    """Check if database files exist and are recent."""
    logger = setup_logging()
    config = get_config_data()
    db_dir = config.get('db directory', '~/.cvdupdate/database')
    db_path = Path(db_dir).expanduser()
    
    results = {
        'directory_exists': db_path.exists(),
        'directory_path': str(db_path),
        'files': {},
        'total_files': 0,
        'total_size': 0
    }
    
    if not db_path.exists():
        return results
    
    # Check for database files
    for pattern in ['*.cvd', '*.cld', '*.cdiff']:
        for file_path in db_path.glob(pattern):
            stat = file_path.stat()
            file_info = {
                'size': stat.st_size,
                'modified': datetime.fromtimestamp(stat.st_mtime),
                'age_hours': (datetime.now() - datetime.fromtimestamp(stat.st_mtime)).total_seconds() / 3600
            }
            results['files'][file_path.name] = file_info
            results['total_files'] += 1
            results['total_size'] += stat.st_size
    
    return results


def check_last_update():
    """Check when databases were last updated."""
    state = get_state_data()
    results = {
        'databases': {},
        'oldest_check': None,
        'newest_check': None
    }
    
    if 'dbs' not in state:
        return results
    
    oldest_timestamp = float('inf')
    newest_timestamp = 0
    
    for db_name, db_info in state['dbs'].items():
        last_checked = db_info.get('last checked', 0)
        last_modified = db_info.get('last modified', 0)
        local_version = db_info.get('local version', 0)
        
        if last_checked > 0:
            check_time = datetime.fromtimestamp(last_checked)
            age_hours = (datetime.now() - check_time).total_seconds() / 3600
            
            results['databases'][db_name] = {
                'last_checked': check_time,
                'last_modified': datetime.fromtimestamp(last_modified) if last_modified > 0 else None,
                'local_version': local_version,
                'age_hours': age_hours,
                'status': 'downloaded' if local_version > 0 else 'not_downloaded'
            }
            
            if last_checked < oldest_timestamp:
                oldest_timestamp = last_checked
                results['oldest_check'] = check_time
            
            if last_checked > newest_timestamp:
                newest_timestamp = last_checked
                results['newest_check'] = check_time
    
    return results


def health_check(verbose=False):
    """Perform comprehensive health check."""
    logger = setup_logging(verbose)
    
    logger.info("Performing ClamAV database health check...")
    
    # Check configuration
    config = get_config_data()
    if not config:
        logger.error("❌ Could not read configuration")
        return False
    
    logger.info("✅ Configuration accessible")
    
    # Check database files
    file_results = check_database_files()
    
    if not file_results['directory_exists']:
        logger.error(f"❌ Database directory does not exist: {file_results['directory_path']}")
        return False
    
    logger.info(f"✅ Database directory exists: {file_results['directory_path']}")
    
    if file_results['total_files'] == 0:
        logger.warning("⚠️  No database files found - run update first")
    else:
        logger.info(f"✅ Found {file_results['total_files']} database files ({file_results['total_size']:,} bytes)")
        
        # Check file ages
        for filename, info in file_results['files'].items():
            if filename.endswith('.cvd'):
                if info['age_hours'] > 48:  # Older than 2 days
                    logger.warning(f"⚠️  {filename} is {info['age_hours']:.1f} hours old")
                else:
                    logger.info(f"✅ {filename} is recent ({info['age_hours']:.1f} hours old)")
    
    # Check update status
    update_results = check_last_update()
    
    if not update_results['databases']:
        logger.warning("⚠️  No update history found")
    else:
        logger.info(f"✅ Found update history for {len(update_results['databases'])} databases")
        
        for db_name, info in update_results['databases'].items():
            if info['status'] == 'not_downloaded':
                logger.warning(f"⚠️  {db_name} has not been downloaded")
            elif info['age_hours'] > 24:
                logger.warning(f"⚠️  {db_name} last checked {info['age_hours']:.1f} hours ago")
            else:
                logger.info(f"✅ {db_name} recently checked ({info['age_hours']:.1f} hours ago)")
    
    logger.info("Health check completed")
    return True


def status_report(verbose=False):
    """Generate detailed status report."""
    logger = setup_logging(verbose)
    
    print("ClamAV Database Status Report")
    print("=" * 50)
    print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Configuration
    config = get_config_data()
    print("Configuration:")
    for key, value in config.items():
        print(f"  {key}: {value}")
    print()
    
    # File status
    file_results = check_database_files()
    print("Database Files:")
    print(f"  Directory: {file_results['directory_path']}")
    print(f"  Exists: {file_results['directory_exists']}")
    print(f"  Total files: {file_results['total_files']}")
    print(f"  Total size: {file_results['total_size']:,} bytes")
    
    if file_results['files']:
        print("  Files:")
        for filename, info in sorted(file_results['files'].items()):
            print(f"    {filename}:")
            print(f"      Size: {info['size']:,} bytes")
            print(f"      Modified: {info['modified'].strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"      Age: {info['age_hours']:.1f} hours")
    print()
    
    # Update status
    update_results = check_last_update()
    print("Update Status:")
    if update_results['databases']:
        for db_name, info in sorted(update_results['databases'].items()):
            print(f"  {db_name}:")
            print(f"    Status: {info['status']}")
            print(f"    Local version: {info['local_version']}")
            print(f"    Last checked: {info['last_checked'].strftime('%Y-%m-%d %H:%M:%S')}")
            if info['last_modified']:
                print(f"    Last modified: {info['last_modified'].strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"    Age: {info['age_hours']:.1f} hours")
    else:
        print("  No update history available")


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description='Monitor ClamAV database health')
    parser.add_argument('-v', '--verbose', action='store_true',
                       help='Enable verbose output')
    parser.add_argument('--health', action='store_true',
                       help='Perform health check')
    parser.add_argument('--status', action='store_true',
                       help='Generate status report')
    
    args = parser.parse_args()
    
    if args.status:
        status_report(args.verbose)
    elif args.health:
        success = health_check(args.verbose)
        sys.exit(0 if success else 1)
    else:
        # Default: both health check and status
        print("Performing health check...")
        success = health_check(args.verbose)
        print("\nGenerating status report...")
        status_report(args.verbose)
        sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()