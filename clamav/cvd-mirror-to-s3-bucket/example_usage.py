#!/usr/bin/env python3
"""
Example Usage Script for ClamAV Database Management

This script demonstrates how to use the various CVD management tools
and provides a step-by-step walkthrough of common operations.
"""

import subprocess
import sys
import time
from pathlib import Path
from env_setup import setup_environment, get_cvd_command, get_python_command


def run_script(script_name, args=None, wait_for_user=True):
    """Run one of our management scripts."""
    if args is None:
        args = []
    
    python_cmd = get_python_command()
    cmd = [python_cmd, script_name] + args
    
    print(f"\n🚀 Running: {' '.join(cmd)}")
    print("=" * 60)
    
    try:
        result = subprocess.run(cmd, check=True)
        print("✅ Command completed successfully")
        
        if wait_for_user:
            input("\nPress Enter to continue...")
        
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Command failed with exit code {e.returncode}")
        if wait_for_user:
            input("\nPress Enter to continue...")
        return False


def main():
    """Main demonstration function."""
    print("🦠 ClamAV Database Management - Example Walkthrough")
    print("=" * 60)
    print("This script will demonstrate the various database management operations.")
    print("You can stop at any time with Ctrl+C")
    
    try:
        # Step 1: Show current configuration
        print("\n📋 Step 1: Show Current Configuration")
        print("This shows the current cvdupdate settings and database status.")
        if not run_script("config_manager.py", ["show"]):
            return
        
        # Step 2: List databases
        print("\n📂 Step 2: List Current Databases")
        print("This shows which databases are configured and their status.")
        if not run_script("update_databases.py", ["--list"]):
            return
        
        # Step 3: Ask if user wants to download databases
        print("\n💾 Step 3: Download Databases (Optional)")
        download = input("Would you like to download the ClamAV databases? This may take a few minutes. (y/N): ")
        
        if download.lower().startswith('y'):
            print("Downloading databases with verbose output...")
            if run_script("update_databases.py", ["-v"], wait_for_user=False):
                print("\n✅ Database download completed!")
            else:
                print("\n❌ Database download failed!")
            input("Press Enter to continue...")
        
        # Step 4: Check database directory
        print("\n🔍 Step 4: Check Database Directory")
        print("This verifies that databases are present and ready to serve.")
        if not run_script("serve_mirror.py", ["--check"]):
            return
        
        # Step 5: Configuration management examples
        print("\n⚙️  Step 5: Configuration Management Examples")
        print("Let's see how to manage configuration settings...")
        
        # Show available config commands
        print("\nAvailable configuration commands:")
        print("  config_manager.py show                    - Show current config")
        print("  config_manager.py set-dbdir /path         - Set database directory")
        print("  config_manager.py set-logdir /path        - Set log directory")
        print("  config_manager.py set-nameserver 8.8.8.8 - Set DNS server")
        print("  config_manager.py list                    - List databases")
        print("  config_manager.py backup                  - Backup configuration")
        
        backup_config = input("\nWould you like to backup the current configuration? (y/N): ")
        if backup_config.lower().startswith('y'):
            run_script("config_manager.py", ["backup"])
        
        # Step 6: Scheduling information
        print("\n⏰ Step 6: Scheduling Information")
        print("Here's how to schedule automatic database updates...")
        
        if not run_script("schedule_updates.py", ["--cron"]):
            return
        
        # Step 7: Server demonstration (optional)
        print("\n🌐 Step 7: Database Mirror Server (Optional)")
        print("The serve_mirror.py script can start a local HTTP server")
        print("to serve your databases for testing with FreshClam.")
        
        serve_demo = input("Would you like to see server information? (y/N): ")
        if serve_demo.lower().startswith('y'):
            print("\nTo start the mirror server, run:")
            print(f"  {get_python_command()} serve_mirror.py")
            print("  or")
            print(f"  {get_python_command()} serve_mirror.py -p 9000  # custom port")
            print("\nThe server will be available at http://localhost:8000")
            print("You can test it with FreshClam by setting:")
            print("  DatabaseMirror http://localhost:8000")
            print("in your freshclam.conf file.")
        
        # Final summary
        print("\n🎉 Summary")
        print("=" * 60)
        print("You now have a complete ClamAV database management setup!")
        print("\nMain scripts:")
        print(f"  {get_python_command()} update_databases.py    - Update databases")
        print(f"  {get_python_command()} serve_mirror.py        - Serve databases")
        print(f"  {get_python_command()} config_manager.py      - Manage configuration")
        print(f"  {get_python_command()} schedule_updates.py    - Schedule updates")
        print(f"  {get_python_command()} cvd_manager.py         - Unified interface")
        print(f"  {get_python_command()} example_usage.py       - This demonstration")
        
        print("\nNext steps:")
        print("1. Set up a cron job for automatic updates")
        print("2. Configure your web server to serve the database directory")
        print("3. Test with FreshClam using the local mirror")
        print("\nFor help with any script, add --help to see options.")
        
    except KeyboardInterrupt:
        print("\n\n👋 Demonstration stopped by user. Thanks for trying it out!")
    except Exception as e:
        print(f"\n❌ An error occurred: {e}")


if __name__ == '__main__':
    main()