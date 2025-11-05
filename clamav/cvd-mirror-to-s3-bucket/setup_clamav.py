#!/usr/bin/env python3
"""
Setup ClamAV Dependencies

This script sets up the necessary dependencies for generating missing ClamAV
database files in a build pipeline environment.
"""

import subprocess
import sys
import logging
import argparse
from pathlib import Path


def setup_logging(verbose=False):
    """Set up logging configuration."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    return logging.getLogger(__name__)


def check_command_available(command):
    """Check if a command is available in the system PATH."""
    try:
        subprocess.run(['which', command], capture_output=True, text=True, check=True)
        return True
    except subprocess.CalledProcessError:
        return False


def install_clamav_homebrew():
    """Install ClamAV using Homebrew."""
    logger = logging.getLogger(__name__)
    
    if not check_command_available('brew'):
        logger.error("Homebrew not found. Please install Homebrew first.")
        logger.info("Install Homebrew with: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
        return False
    
    logger.info("Installing ClamAV via Homebrew...")
    try:
        result = subprocess.run(['brew', 'install', 'clamav'], 
                              capture_output=True, text=True, timeout=600)
        
        if result.returncode == 0:
            logger.info("ClamAV installed successfully")
            return True
        else:
            logger.error(f"Failed to install ClamAV: {result.stderr}")
            return False
            
    except subprocess.TimeoutExpired:
        logger.error("ClamAV installation timed out")
        return False
    except Exception as e:
        logger.error(f"Error installing ClamAV: {e}")
        return False


def install_clamav_apt():
    """Install ClamAV using apt (for Ubuntu/Debian)."""
    logger = logging.getLogger(__name__)
    
    if not check_command_available('apt'):
        logger.error("apt not found. This system doesn't appear to be Ubuntu/Debian.")
        return False
    
    logger.info("Installing ClamAV via apt...")
    try:
        # Update package list
        subprocess.run(['sudo', 'apt', 'update'], check=True)
        
        # Install ClamAV
        result = subprocess.run(['sudo', 'apt', 'install', '-y', 'clamav', 'clamav-daemon'], 
                              capture_output=True, text=True, timeout=600)
        
        if result.returncode == 0:
            logger.info("ClamAV installed successfully")
            return True
        else:
            logger.error(f"Failed to install ClamAV: {result.stderr}")
            return False
            
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to install ClamAV: {e}")
        return False
    except subprocess.TimeoutExpired:
        logger.error("ClamAV installation timed out")
        return False
    except Exception as e:
        logger.error(f"Error installing ClamAV: {e}")
        return False


def install_clamav_yum():
    """Install ClamAV using yum (for RHEL/CentOS)."""
    logger = logging.getLogger(__name__)
    
    if not check_command_available('yum'):
        logger.error("yum not found. This system doesn't appear to be RHEL/CentOS.")
        return False
    
    logger.info("Installing ClamAV via yum...")
    try:
        result = subprocess.run(['sudo', 'yum', 'install', '-y', 'clamav', 'clamav-update'], 
                              capture_output=True, text=True, timeout=600)
        
        if result.returncode == 0:
            logger.info("ClamAV installed successfully")
            return True
        else:
            logger.error(f"Failed to install ClamAV: {result.stderr}")
            return False
            
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to install ClamAV: {e}")
        return False
    except subprocess.TimeoutExpired:
        logger.error("ClamAV installation timed out")
        return False
    except Exception as e:
        logger.error(f"Error installing ClamAV: {e}")
        return False


def detect_and_install_clamav():
    """Detect the system and install ClamAV using the appropriate package manager."""
    logger = logging.getLogger(__name__)
    
    # Check if freshclam is already available
    if check_command_available('freshclam'):
        logger.info("freshclam is already available")
        result = subprocess.run(['which', 'freshclam'], capture_output=True, text=True)
        logger.info(f"freshclam location: {result.stdout.strip()}")
        return True
    
    logger.info("freshclam not found, attempting to install...")
    
    # Try different package managers in order of preference
    if check_command_available('brew'):
        logger.info("Detected macOS/Homebrew system")
        return install_clamav_homebrew()
    elif check_command_available('apt'):
        logger.info("Detected Ubuntu/Debian system")
        return install_clamav_apt()
    elif check_command_available('yum'):
        logger.info("Detected RHEL/CentOS system")
        return install_clamav_yum()
    else:
        logger.error("No supported package manager found (brew, apt, yum)")
        logger.info("Please install ClamAV manually for your system")
        return False


def verify_installation():
    """Verify that ClamAV was installed correctly."""
    logger = logging.getLogger(__name__)
    
    if not check_command_available('freshclam'):
        logger.error("freshclam is still not available after installation")
        return False
    
    try:
        # Test freshclam help
        result = subprocess.run(['freshclam', '--help'], 
                              capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0:
            logger.info("freshclam is working correctly")
            return True
        else:
            logger.error("freshclam installation verification failed")
            return False
            
    except Exception as e:
        logger.error(f"Error verifying freshclam installation: {e}")
        return False


def main():
    """Main function."""
    parser = argparse.ArgumentParser(
        description='Setup ClamAV dependencies for build pipeline',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
This script automatically detects your system and installs ClamAV using
the appropriate package manager:

- macOS: Homebrew (brew install clamav)
- Ubuntu/Debian: apt (sudo apt install clamav clamav-daemon)
- RHEL/CentOS: yum (sudo yum install clamav clamav-update)

The script will verify the installation by checking that freshclam is
available and working.
        """
    )
    
    parser.add_argument('-v', '--verbose', action='store_true', 
                       help='Enable verbose output')
    parser.add_argument('--verify-only', action='store_true',
                       help='Only verify existing installation, do not install')
    
    args = parser.parse_args()
    
    logger = setup_logging(args.verbose)
    
    if args.verify_only:
        success = verify_installation()
    else:
        success = detect_and_install_clamav()
        if success:
            success = verify_installation()
    
    if success:
        logger.info("ClamAV setup completed successfully")
        sys.exit(0)
    else:
        logger.error("ClamAV setup failed")
        sys.exit(1)


if __name__ == '__main__':
    main()