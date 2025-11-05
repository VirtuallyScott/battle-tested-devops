#!/usr/bin/env python3
"""
Create CLD Files from CVD Files

This script creates CLD (Compressed Local Database) files from existing CVD files.
CLD files are essentially compressed CVD files used by FreshClam when local
compression is enabled.
"""

import argparse
import logging
import sys
import gzip
import shutil
from pathlib import Path
from datetime import datetime


def setup_logging(verbose=False):
    """Set up logging configuration."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler(f'create_cld_{datetime.now().strftime("%Y%m%d")}.log')
        ]
    )
    return logging.getLogger(__name__)


def get_cvdupdate_db_dir():
    """Get the cvdupdate database directory."""
    # Use default cvdupdate directory
    default_dir = Path.home() / '.cvdupdate' / 'database'
    return default_dir


def compress_cvd_to_cld(cvd_path, cld_path):
    """Compress a CVD file to create a CLD file."""
    logger = logging.getLogger(__name__)
    
    try:
        with open(cvd_path, 'rb') as f_in:
            with gzip.open(cld_path, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
        
        original_size = cvd_path.stat().st_size
        compressed_size = cld_path.stat().st_size
        compression_ratio = (1 - compressed_size / original_size) * 100
        
        logger.info(f"Created {cld_path.name}: {original_size:,} -> {compressed_size:,} bytes ({compression_ratio:.1f}% compression)")
        return True
        
    except Exception as e:
        logger.error(f"Failed to compress {cvd_path.name}: {e}")
        return False


def create_cld_files(db_dir, verbose=False):
    """Create CLD files from existing CVD files."""
    logger = setup_logging(verbose)
    
    logger.info("Creating CLD files from CVD files...")
    
    db_path = Path(db_dir)
    if not db_path.exists():
        logger.error(f"Database directory not found: {db_path}")
        return False
    
    # List of CVD files to convert
    cvd_files = ['main.cvd', 'daily.cvd', 'bytecode.cvd']
    created_files = []
    
    for cvd_filename in cvd_files:
        cvd_path = db_path / cvd_filename
        cld_filename = cvd_filename.replace('.cvd', '.cld')
        cld_path = db_path / cld_filename
        
        if not cvd_path.exists():
            logger.warning(f"CVD file not found: {cvd_path}")
            continue
        
        if cld_path.exists():
            logger.info(f"CLD file already exists: {cld_filename}")
            continue
        
        logger.info(f"Compressing {cvd_filename} to {cld_filename}...")
        if compress_cvd_to_cld(cvd_path, cld_path):
            created_files.append(cld_filename)
        else:
            logger.error(f"Failed to create {cld_filename}")
    
    if created_files:
        logger.info(f"Successfully created CLD files: {created_files}")
        
        # Show final listing
        logger.info("Current database files:")
        for file_path in sorted(db_path.iterdir()):
            if file_path.suffix in ['.cvd', '.cld', '.dat']:
                size = file_path.stat().st_size
                logger.info(f"  {file_path.name} ({size:,} bytes)")
    else:
        logger.warning("No CLD files were created")
    
    return len(created_files) > 0


def main():
    """Main function."""
    parser = argparse.ArgumentParser(
        description='Create CLD files from CVD files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
This script creates CLD (Compressed Local Database) files from existing
CVD files. CLD files are gzip-compressed versions of CVD files that are
used when FreshClam's CompressLocalDatabase option is enabled.

The script will create:
- main.cld from main.cvd
- daily.cld from daily.cvd  
- bytecode.cld from bytecode.cvd

These files match what you see in the S3 bucket.
        """
    )
    
    parser.add_argument('-v', '--verbose', action='store_true', 
                       help='Enable verbose output')
    parser.add_argument('--db-dir', type=str,
                       help='Database directory (default: ~/.cvdupdate/database)')
    
    args = parser.parse_args()
    
    if args.db_dir:
        db_dir = Path(args.db_dir)
    else:
        db_dir = get_cvdupdate_db_dir()
    
    success = create_cld_files(db_dir, args.verbose)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()