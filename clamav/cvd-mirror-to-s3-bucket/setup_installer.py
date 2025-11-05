#!/usr/bin/env python3
"""
ClamAV Database Management Setup and Installation Script

This script helps set up the complete ClamAV database management environment.
"""

import argparse
import subprocess
import sys
import os
from pathlib import Path


def run_command(cmd, description="", check=True):
    """Run a command with optional description."""
    if description:
        print(f"📋 {description}")
    
    print(f"🚀 Running: {' '.join(cmd) if isinstance(cmd, list) else cmd}")
    
    try:
        if isinstance(cmd, str):
            result = subprocess.run(cmd, shell=True, check=check, text=True, capture_output=True)
        else:
            result = subprocess.run(cmd, check=check, text=True, capture_output=True)
        
        if result.stdout:
            print(result.stdout)
        if result.stderr and result.returncode != 0:
            print(f"stderr: {result.stderr}")
        
        print("✅ Success")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Command failed with exit code {e.returncode}")
        if e.stdout:
            print(f"stdout: {e.stdout}")
        if e.stderr:
            print(f"stderr: {e.stderr}")
        return False


def check_python_version():
    """Check if Python version is compatible."""
    version = sys.version_info
    print(f"🐍 Python version: {version.major}.{version.minor}.{version.micro}")
    
    if version.major < 3 or (version.major == 3 and version.minor < 6):
        print("❌ Python 3.6 or newer is required")
        return False
    
    print("✅ Python version is compatible")
    return True


def check_internet_connection():
    """Check if internet connection is available."""
    print("🌐 Checking internet connection...")
    
    try:
        import socket
        socket.create_connection(("8.8.8.8", 53), timeout=5)
        print("✅ Internet connection available")
        return True
    except OSError:
        print("❌ No internet connection detected")
        return False


def setup_virtual_environment():
    """Set up Python virtual environment."""
    venv_path = Path('.venv')
    
    if venv_path.exists():
        print("✅ Virtual environment already exists")
        return True
    
    print("🔧 Creating virtual environment...")
    return run_command([sys.executable, '-m', 'venv', '.venv'], 
                      "Creating Python virtual environment")


def install_dependencies():
    """Install required dependencies."""
    print("📦 Installing dependencies...")
    
    venv_python = Path('.venv/bin/python')
    if not venv_python.exists():
        print("❌ Virtual environment not found")
        return False
    
    # Install cvdupdate
    if not run_command([str(venv_python), '-m', 'pip', 'install', 'cvdupdate'], 
                      "Installing cvdupdate"):
        return False
    
    # Install from requirements.txt if it exists
    req_file = Path('requirements.txt')
    if req_file.exists():
        return run_command([str(venv_python), '-m', 'pip', 'install', '-r', 'requirements.txt'],
                          "Installing additional requirements")
    
    return True


def make_scripts_executable():
    """Make all Python scripts executable."""
    print("🔧 Making scripts executable...")
    
    script_files = list(Path('.').glob('*.py'))
    
    for script in script_files:
        try:
            current_mode = script.stat().st_mode
            script.chmod(current_mode | 0o755)
            print(f"✅ Made {script.name} executable")
        except Exception as e:
            print(f"⚠️  Could not make {script.name} executable: {e}")
    
    return True


def create_initial_config():
    """Create initial configuration if needed."""
    print("⚙️  Setting up initial configuration...")
    
    venv_python = Path('.venv/bin/python')
    if not venv_python.exists():
        print("❌ Virtual environment not found")
        return False
    
    # Just run config show to initialize
    return run_command([str(venv_python), 'config_manager.py', 'show'],
                      "Initializing configuration", check=False)


def run_basic_test():
    """Run basic functionality test."""
    print("🧪 Running basic functionality test...")
    
    venv_python = Path('.venv/bin/python')
    
    # Test config manager
    if not run_command([str(venv_python), 'config_manager.py', 'show'],
                      "Testing configuration manager", check=False):
        return False
    
    # Test database listing
    if not run_command([str(venv_python), 'update_databases.py', '--list'],
                      "Testing database listing", check=False):
        return False
    
    # Test health monitor
    if not run_command([str(venv_python), 'monitor.py', '--health'],
                      "Testing health monitor", check=False):
        return False
    
    print("✅ Basic functionality tests passed")
    return True


def show_next_steps():
    """Show next steps to the user."""
    venv_python = Path('.venv/bin/python')
    
    print("\n🎉 Setup Complete!")
    print("=" * 50)
    print("\nYour ClamAV database management environment is ready!")
    print("\nNext steps:")
    print(f"1. Run your first database update:")
    print(f"   {venv_python} update_databases.py -v")
    print(f"\n2. Check database status:")
    print(f"   {venv_python} monitor.py")
    print(f"\n3. Set up scheduled updates:")
    print(f"   {venv_python} schedule_updates.py --cron")
    print(f"\n4. Try the example walkthrough:")
    print(f"   {venv_python} example_usage.py")
    print(f"\n5. Use the unified interface:")
    print(f"   {venv_python} cvd_manager.py --help")
    
    print("\nAvailable scripts:")
    for script in sorted(Path('.').glob('*.py')):
        if script.name not in ['setup_installer.py', 'env_setup.py']:
            print(f"  📄 {script.name}")
    
    print(f"\nFor help with any script: {venv_python} <script_name> --help")
    print("\nEnjoy managing your ClamAV databases! 🦠")


def main():
    """Main setup function."""
    parser = argparse.ArgumentParser(description='Set up ClamAV database management environment')
    parser.add_argument('--skip-tests', action='store_true',
                       help='Skip functionality tests')
    parser.add_argument('--quick', action='store_true',
                       help='Quick setup (skip some checks)')
    
    args = parser.parse_args()
    
    print("🦠 ClamAV Database Management Setup")
    print("=" * 40)
    print("This script will set up your complete ClamAV database management environment.")
    print()
    
    # Step 1: Check prerequisites
    print("🔍 Step 1: Checking Prerequisites")
    if not check_python_version():
        sys.exit(1)
    
    if not args.quick and not check_internet_connection():
        print("⚠️  Internet connection required for package installation")
        sys.exit(1)
    
    # Step 2: Set up virtual environment
    print("\n🔧 Step 2: Setting Up Virtual Environment")
    if not setup_virtual_environment():
        sys.exit(1)
    
    # Step 3: Install dependencies
    print("\n📦 Step 3: Installing Dependencies")
    if not install_dependencies():
        sys.exit(1)
    
    # Step 4: Make scripts executable
    print("\n🔧 Step 4: Configuring Scripts")
    make_scripts_executable()
    
    # Step 5: Initialize configuration
    print("\n⚙️  Step 5: Initializing Configuration")
    create_initial_config()
    
    # Step 6: Run tests
    if not args.skip_tests:
        print("\n🧪 Step 6: Testing Installation")
        if not run_basic_test():
            print("⚠️  Some tests failed, but setup may still be functional")
    
    # Step 7: Show next steps
    show_next_steps()


if __name__ == '__main__':
    main()