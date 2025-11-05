#!/usr/bin/env python3
"""
Generate Missing ClamAV Database Files

This script generates the additional ClamAV database files that are missing
from the cvdupdate setup but present in the S3 bucket:
- daily.cld (compressed local database)
- bytecode.cld (compressed local database)
- freshclam.dat (freshclam metadata)
- mirrors.dat (mirror configuration)

The script uses freshclam to convert CVD files to CLD files and generate
the required metadata files.
"""

import argparse
import logging
import sys
import subprocess
import tempfile
import shutil
import os
from pathlib import Path
from datetime import datetime
from env_setup import setup_environment


def check_and_install_clamav():
    """Check if freshclam is available and install ClamAV if needed."""
    logger = logging.getLogger(__name__)
    
    # Check if freshclam is already available
    try:
        result = subprocess.run(['which', 'freshclam'], 
                              capture_output=True, text=True, check=True)
        freshclam_path = result.stdout.strip()
        logger.info(f"freshclam found at: {freshclam_path}")
        return True, freshclam_path
    except subprocess.CalledProcessError:
        logger.info("freshclam not found, attempting to install ClamAV...")
    
    # Check if brew is available
    try:
        subprocess.run(['which', 'brew'], capture_output=True, text=True, check=True)
        logger.info("Homebrew found, installing ClamAV...")
    except subprocess.CalledProcessError:
        logger.error("Homebrew not found. Please install ClamAV manually or install Homebrew first.")
        return False, None
    
    # Install ClamAV using brew
    try:
        logger.info("Installing ClamAV via Homebrew (this may take a few minutes)...")
        result = subprocess.run(['brew', 'install', 'clamav'], 
                              capture_output=True, text=True, timeout=600)
        
        if result.returncode == 0:
            logger.info("ClamAV installed successfully")
            
            # Verify freshclam is now available
            result = subprocess.run(['which', 'freshclam'], 
                                  capture_output=True, text=True, check=True)
            freshclam_path = result.stdout.strip()
            logger.info(f"freshclam now available at: {freshclam_path}")
            return True, freshclam_path
        else:
            logger.error(f"Failed to install ClamAV: {result.stderr}")
            return False, None
            
    except subprocess.TimeoutExpired:
        logger.error("ClamAV installation timed out")
        return False, None
    except Exception as e:
        logger.error(f"Error installing ClamAV: {e}")
        return False, None


def setup_logging(verbose=False):
    """Set up logging configuration."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler(f'generate_missing_{datetime.now().strftime("%Y%m%d")}.log')
        ]
    )
    return logging.getLogger(__name__)


def get_cvdupdate_db_dir():
    """Get the cvdupdate database directory from config."""
    try:
        result = subprocess.run(['cvd', 'config', 'show'], 
                              capture_output=True, text=True, check=True)
        
        # Parse the config output to find db directory
        for line in result.stdout.split('\n'):
            if '"db directory"' in line:
                # Extract the path from the JSON-like format
                db_dir = line.split('"db directory":')[1].strip().strip(',').strip('"')
                return Path(db_dir)
        
        # Fallback to default
        return Path.home() / '.cvdupdate' / 'database'
    except Exception as e:
        logging.warning(f"Could not get db directory from config: {e}")
        return Path.home() / '.cvdupdate' / 'database'


def create_freshclam_config(temp_dir, source_dir, target_dir):
    """Create a temporary freshclam.conf file."""
    config_content = f"""# Temporary freshclam config for generating CLD files
DatabaseDirectory {target_dir}
UpdateLogFile {temp_dir}/freshclam.log
LogFileMaxSize 0
LogTime yes
LogSyslog no
PidFile {temp_dir}/freshclam.pid

# Don't check for updates from internet, work with local files
DNSDatabaseInfo no
DatabaseMirror database.clamav.net

# Enable local database compression to create .cld files
CompressLocalDatabase yes

# Disable automatic updates - we'll handle this manually
Checks 0
"""
    
    config_path = temp_dir / 'freshclam.conf'
    with open(config_path, 'w') as f:
        f.write(config_content)
    
    return config_path


def copy_cvd_files(source_dir, target_dir):
    """Copy CVD files from cvdupdate directory to temporary directory."""
    source_dir = Path(source_dir)
    target_dir = Path(target_dir)
    
    cvd_files = ['main.cvd', 'daily.cvd', 'bytecode.cvd']
    copied_files = []
    
    for cvd_file in cvd_files:
        source_file = source_dir / cvd_file
        target_file = target_dir / cvd_file
        
        if source_file.exists():
            shutil.copy2(source_file, target_file)
            copied_files.append(cvd_file)
            logging.info(f"Copied {cvd_file}")
        else:
            logging.warning(f"Source file {cvd_file} not found in {source_dir}")
    
    return copied_files


def run_freshclam_to_generate_cld(config_path, target_dir, freshclam_path='freshclam'):
    """Run freshclam to generate CLD files from CVD files."""
    try:
        # Run freshclam with our custom config
        cmd = [freshclam_path, '--config-file', str(config_path), '--no-dns']
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        
        logging.info(f"freshclam exit code: {result.returncode}")
        if result.stdout:
            logging.info(f"freshclam stdout: {result.stdout}")
        if result.stderr:
            logging.info(f"freshclam stderr: {result.stderr}")
        
        # Check what files were created
        target_path = Path(target_dir)
        cld_files = list(target_path.glob('*.cld'))
        dat_files = list(target_path.glob('*.dat'))
        
        logging.info(f"Generated CLD files: {[f.name for f in cld_files]}")
        logging.info(f"Generated DAT files: {[f.name for f in dat_files]}")
        
        return result.returncode == 0, cld_files, dat_files
        
    except subprocess.TimeoutExpired:
        logging.error("freshclam command timed out")
        return False, [], []
    except Exception as e:
        logging.error(f"Error running freshclam: {e}")
        return False, [], []


def generate_missing_dat_files(target_dir):
    """Generate missing .dat files if they weren't created by freshclam."""
    target_path = Path(target_dir)
    
    # Create freshclam.dat if it doesn't exist
    freshclam_dat = target_path / 'freshclam.dat'
    if not freshclam_dat.exists():
        with open(freshclam_dat, 'w') as f:
            f.write("# FreshClam database metadata\n")
            f.write(f"# Generated on {datetime.now().isoformat()}\n")
        logging.info("Created freshclam.dat")
    
    # Create mirrors.dat if it doesn't exist
    mirrors_dat = target_path / 'mirrors.dat'
    if not mirrors_dat.exists():
        with open(mirrors_dat, 'w') as f:
            f.write("# ClamAV mirror configuration\n")
            f.write(f"# Generated on {datetime.now().isoformat()}\n")
        logging.info("Created mirrors.dat")


def copy_files_back(source_dir, target_dir, file_patterns):
    """Copy generated files back to the cvdupdate directory."""
    source_path = Path(source_dir)
    target_path = Path(target_dir)
    
    copied_files = []
    
    for pattern in file_patterns:
        for file_path in source_path.glob(pattern):
            target_file = target_path / file_path.name
            shutil.copy2(file_path, target_file)
            copied_files.append(file_path.name)
            logging.info(f"Copied {file_path.name} to cvdupdate directory")
    
    return copied_files


def generate_missing_files(verbose=False, dry_run=False):
    """Main function to generate missing database files."""
    logger = setup_logging(verbose)
    
    logger.info("Starting generation of missing ClamAV database files...")
    
    # Check and install ClamAV if needed
    clamav_available, freshclam_path = check_and_install_clamav()
    if not clamav_available:
        logger.error("ClamAV installation failed. Cannot proceed.")
        return False
    
    # Get cvdupdate database directory
    cvdupdate_db_dir = get_cvdupdate_db_dir()
    logger.info(f"cvdupdate database directory: {cvdupdate_db_dir}")
    
    if not cvdupdate_db_dir.exists():
        logger.error(f"cvdupdate database directory not found: {cvdupdate_db_dir}")
        return False
    
    # Create temporary directory for freshclam operations
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        freshclam_db_dir = temp_path / 'database'
        freshclam_db_dir.mkdir()
        
        logger.info(f"Working in temporary directory: {temp_path}")
        
        # Copy CVD files to temporary directory
        copied_files = copy_cvd_files(cvdupdate_db_dir, freshclam_db_dir)
        if not copied_files:
            logger.error("No CVD files found to process")
            return False
        
        # Create freshclam configuration
        config_path = create_freshclam_config(temp_path, cvdupdate_db_dir, freshclam_db_dir)
        logger.info(f"Created freshclam config: {config_path}")
        
        if dry_run:
            logger.info("DRY RUN: Would run freshclam to generate CLD files")
            logger.info("DRY RUN: Would copy generated files back to cvdupdate directory")
            return True
        
        # Run freshclam to generate CLD files
        success, cld_files, dat_files = run_freshclam_to_generate_cld(config_path, freshclam_db_dir, freshclam_path)
        
        if not success:
            logger.error("Failed to generate CLD files with freshclam")
            return False
        
        # Generate any missing .dat files
        generate_missing_dat_files(freshclam_db_dir)
        
        # Copy generated files back to cvdupdate directory
        patterns_to_copy = ['*.cld', '*.dat']
        copied_back = copy_files_back(freshclam_db_dir, cvdupdate_db_dir, patterns_to_copy)
        
        if copied_back:
            logger.info(f"Successfully generated and copied files: {copied_back}")
        else:
            logger.warning("No files were generated or copied")
        
        # Show final file listing
        logger.info("Final database directory contents:")
        for file_path in sorted(cvdupdate_db_dir.iterdir()):
            if file_path.is_file():
                size = file_path.stat().st_size
                logger.info(f"  {file_path.name} ({size:,} bytes)")
    
    return True


def main():
    """Main function."""
    parser = argparse.ArgumentParser(
        description='Generate missing ClamAV database files (CLD and DAT files)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
This script generates the missing database files that are present in the
S3 bucket but not created by cvdupdate:

- daily.cld (compressed local database)
- bytecode.cld (compressed local database)
- freshclam.dat (freshclam metadata)
- mirrors.dat (mirror configuration)

The script uses freshclam to convert existing CVD files to CLD format.
        """
    )
    
    parser.add_argument('-v', '--verbose', action='store_true', 
                       help='Enable verbose output')
    parser.add_argument('--dry-run', action='store_true',
                       help='Show what would be done without making changes')
    
    args = parser.parse_args()
    
    success = generate_missing_files(args.verbose, args.dry_run)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()