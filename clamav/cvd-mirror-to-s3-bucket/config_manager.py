#!/usr/bin/env python3
"""
ClamAV Database Update Configuration Manager

This script manages cvdupdate configuration settings including:
- Database directory
- Log directory
- DNS servers
- Custom databases
"""

import argparse
import json
import logging
import subprocess
import sys
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


def run_cvd_config_command(command, verbose=False):
    """Run a cvd config command and return the result."""
    setup_environment()
    
    cvd_cmd = get_cvd_command()
    if isinstance(cvd_cmd, list):
        cmd = cvd_cmd + ['config'] + command
    else:
        cmd = [cvd_cmd, 'config'] + command
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return result.stdout, result.stderr, 0
    except subprocess.CalledProcessError as e:
        return e.stdout, e.stderr, e.returncode
    except FileNotFoundError:
        return "", "cvd command not found", 1


def show_config(verbose=False):
    """Show current configuration."""
    logger = setup_logging(verbose)
    
    stdout, stderr, returncode = run_cvd_config_command(['show'], verbose)
    
    if returncode == 0:
        logger.info("Current CVD Configuration:")
        print(stdout)
    else:
        logger.error(f"Failed to show configuration: {stderr}")
    
    return returncode == 0


def set_database_directory(directory, verbose=False):
    """Set the database directory."""
    logger = setup_logging(verbose)
    
    # Expand user path
    directory = Path(directory).expanduser().absolute()
    
    logger.info(f"Setting database directory to: {directory}")
    
    # Create directory if it doesn't exist
    directory.mkdir(parents=True, exist_ok=True)
    
    stdout, stderr, returncode = run_cvd_config_command(['set', '--dbdir', str(directory)], verbose)
    
    if returncode == 0:
        logger.info("Database directory set successfully")
        if verbose and stdout:
            logger.debug(f"Output: {stdout}")
    else:
        logger.error(f"Failed to set database directory: {stderr}")
    
    return returncode == 0


def set_log_directory(directory, verbose=False):
    """Set the log directory."""
    logger = setup_logging(verbose)
    
    # Expand user path
    directory = Path(directory).expanduser().absolute()
    
    logger.info(f"Setting log directory to: {directory}")
    
    # Create directory if it doesn't exist
    directory.mkdir(parents=True, exist_ok=True)
    
    stdout, stderr, returncode = run_cvd_config_command(['set', '--logdir', str(directory)], verbose)
    
    if returncode == 0:
        logger.info("Log directory set successfully")
        if verbose and stdout:
            logger.debug(f"Output: {stdout}")
    else:
        logger.error(f"Failed to set log directory: {stderr}")
    
    return returncode == 0


def set_nameserver(nameserver, verbose=False):
    """Set the DNS nameserver."""
    logger = setup_logging(verbose)
    
    logger.info(f"Setting nameserver to: {nameserver}")
    
    stdout, stderr, returncode = run_cvd_config_command(['set', '--nameserver', nameserver], verbose)
    
    if returncode == 0:
        logger.info("Nameserver set successfully")
        if verbose and stdout:
            logger.debug(f"Output: {stdout}")
    else:
        logger.error(f"Failed to set nameserver: {stderr}")
    
    return returncode == 0


def add_custom_database(name, url, verbose=False):
    """Add a custom database."""
    logger = setup_logging(verbose)
    
    logger.info(f"Adding custom database: {name} from {url}")
    
    # Use cvd add command
    try:
        setup_environment()
        cvd_cmd = get_cvd_command()
        
        if isinstance(cvd_cmd, list):
            cmd = cvd_cmd + ['add', name, url]
        else:
            cmd = [cvd_cmd, 'add', name, url]
            
        if verbose:
            cmd.append('-V')
            
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        logger.info("Custom database added successfully")
        if verbose and result.stdout:
            logger.debug(f"Output: {result.stdout}")
        return True
        
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to add custom database: {e.stderr}")
        return False
    except FileNotFoundError:
        logger.error("cvd command not found")
        return False


def list_databases(verbose=False):
    """List all configured databases."""
    logger = setup_logging(verbose)
    
    try:
        setup_environment()
        cvd_cmd = get_cvd_command()
        
        if isinstance(cvd_cmd, list):
            cmd = cvd_cmd + ['list']
        else:
            cmd = [cvd_cmd, 'list']
            
        if verbose:
            cmd.append('-V')
            
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        logger.info("Configured databases:")
        print(result.stdout)
        return True
        
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to list databases: {e.stderr}")
        return False
    except FileNotFoundError:
        logger.error("cvd command not found")
        return False


def get_config_file_path():
    """Get the path to the config file."""
    return Path.home() / '.cvdupdate' / 'config.json'


def get_s3_config_file_path():
    """Get the path to the S3 config file."""
    return Path.home() / '.cvdupdate' / 's3_config.json'


def load_s3_config():
    """Load S3 configuration from file."""
    config_file = get_s3_config_file_path()
    if config_file.exists():
        try:
            with open(config_file, 'r') as f:
                return json.load(f)
        except Exception:
            pass
    return {}


def save_s3_config(config):
    """Save S3 configuration to file."""
    config_file = get_s3_config_file_path()
    config_file.parent.mkdir(parents=True, exist_ok=True)
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=2)


def set_s3_bucket(bucket_name, verbose=False):
    """Set the S3 bucket name."""
    logger = setup_logging(verbose)
    
    logger.info(f"Setting S3 bucket to: {bucket_name}")
    
    config = load_s3_config()
    config['bucket'] = bucket_name
    save_s3_config(config)
    
    logger.info("S3 bucket set successfully")
    return True


def set_s3_region(region, verbose=False):
    """Set the S3 region."""
    logger = setup_logging(verbose)
    
    logger.info(f"Setting S3 region to: {region}")
    
    config = load_s3_config()
    config['region'] = region
    save_s3_config(config)
    
    logger.info("S3 region set successfully")
    return True


def set_s3_prefix(prefix, verbose=False):
    """Set the S3 prefix."""
    logger = setup_logging(verbose)
    
    logger.info(f"Setting S3 prefix to: {prefix}")
    
    config = load_s3_config()
    config['prefix'] = prefix.rstrip('/') + '/' if prefix else ''
    save_s3_config(config)
    
    logger.info("S3 prefix set successfully")
    return True


def set_s3_sync(enabled, verbose=False):
    """Enable or disable S3 sync."""
    logger = setup_logging(verbose)
    
    enabled_bool = enabled.lower() in ['true', 'enabled', 'yes', '1', 'on']
    logger.info(f"Setting S3 sync to: {'enabled' if enabled_bool else 'disabled'}")
    
    config = load_s3_config()
    config['sync_enabled'] = enabled_bool
    save_s3_config(config)
    
    logger.info(f"S3 sync {'enabled' if enabled_bool else 'disabled'} successfully")
    return True


def show_s3_config(verbose=False):
    """Show S3 configuration."""
    logger = setup_logging(verbose)
    
    config = load_s3_config()
    
    if not config:
        logger.info("No S3 configuration found")
        print("S3 Configuration: Not configured")
        return True
    
    logger.info("Current S3 Configuration:")
    print("S3 Configuration:")
    print(f"  Bucket: {config.get('bucket', 'Not set')}")
    print(f"  Region: {config.get('region', 'Not set')}")
    print(f"  Prefix: {config.get('prefix', 'Not set')}")
    print(f"  Sync Enabled: {config.get('sync_enabled', False)}")
    
    return True


def backup_config(verbose=False):
    """Backup the current configuration."""
    logger = setup_logging(verbose)
    
    config_file = get_config_file_path()
    if not config_file.exists():
        logger.warning("No configuration file found to backup")
        return False
    
    backup_file = config_file.with_suffix('.json.backup')
    
    try:
        import shutil
        shutil.copy2(config_file, backup_file)
        logger.info(f"Configuration backed up to: {backup_file}")
        return True
    except Exception as e:
        logger.error(f"Failed to backup configuration: {e}")
        return False


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description='Manage CVD configuration')
    parser.add_argument('-v', '--verbose', action='store_true',
                       help='Enable verbose output')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Show config
    show_parser = subparsers.add_parser('show', help='Show current configuration')
    
    # Set database directory
    dbdir_parser = subparsers.add_parser('set-dbdir', help='Set database directory')
    dbdir_parser.add_argument('directory', help='Database directory path')
    
    # Set log directory
    logdir_parser = subparsers.add_parser('set-logdir', help='Set log directory')
    logdir_parser.add_argument('directory', help='Log directory path')
    
    # Set nameserver
    ns_parser = subparsers.add_parser('set-nameserver', help='Set DNS nameserver')
    ns_parser.add_argument('nameserver', help='DNS nameserver IP')
    
    # Add custom database
    add_parser = subparsers.add_parser('add-database', help='Add custom database')
    add_parser.add_argument('name', help='Database name (e.g., linux.cvd)')
    add_parser.add_argument('url', help='Database URL')
    
    # List databases
    list_parser = subparsers.add_parser('list', help='List configured databases')
    
    # Backup config
    backup_parser = subparsers.add_parser('backup', help='Backup configuration')
    
    # S3 commands
    s3_bucket_parser = subparsers.add_parser('set-s3-bucket', help='Set S3 bucket name')
    s3_bucket_parser.add_argument('bucket', help='S3 bucket name')
    
    s3_region_parser = subparsers.add_parser('set-s3-region', help='Set S3 region')
    s3_region_parser.add_argument('region', help='AWS region (e.g., us-east-1)')
    
    s3_prefix_parser = subparsers.add_parser('set-s3-prefix', help='Set S3 prefix')
    s3_prefix_parser.add_argument('prefix', help='S3 prefix/path')
    
    s3_sync_parser = subparsers.add_parser('set-s3-sync', help='Enable/disable S3 sync')
    s3_sync_parser.add_argument('enabled', help='Enable S3 sync (enabled/disabled)')
    
    s3_show_parser = subparsers.add_parser('show-s3', help='Show S3 configuration')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    success = False
    
    if args.command == 'show':
        success = show_config(args.verbose)
    elif args.command == 'set-dbdir':
        success = set_database_directory(args.directory, args.verbose)
    elif args.command == 'set-logdir':
        success = set_log_directory(args.directory, args.verbose)
    elif args.command == 'set-nameserver':
        success = set_nameserver(args.nameserver, args.verbose)
    elif args.command == 'add-database':
        success = add_custom_database(args.name, args.url, args.verbose)
    elif args.command == 'list':
        success = list_databases(args.verbose)
    elif args.command == 'backup':
        success = backup_config(args.verbose)
    elif args.command == 'set-s3-bucket':
        success = set_s3_bucket(args.bucket, args.verbose)
    elif args.command == 'set-s3-region':
        success = set_s3_region(args.region, args.verbose)
    elif args.command == 'set-s3-prefix':
        success = set_s3_prefix(args.prefix, args.verbose)
    elif args.command == 'set-s3-sync':
        success = set_s3_sync(args.enabled, args.verbose)
    elif args.command == 'show-s3':
        success = show_s3_config(args.verbose)
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()