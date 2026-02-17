#!/usr/bin/env python3
"""
ClamAV Database Management - Getting Started Guide

This script provides a quick start guide and menu system for managing ClamAV databases.
"""

import subprocess
import sys
from pathlib import Path
from env_setup import get_python_command


def print_banner():
    """Print welcome banner."""
    print("🦠 ClamAV Database Management System")
    print("=" * 50)
    print("Welcome! This tool helps you manage ClamAV database updates.")
    print()


def check_setup():
    """Check if the environment is properly set up."""
    venv_path = Path('.venv')
    if not venv_path.exists():
        print("❌ Virtual environment not found!")
        print("Please run: python3 setup_installer.py")
        return False

    python_cmd = get_python_command()
    if not Path(python_cmd).exists():
        print("❌ Python interpreter not found in virtual environment!")
        return False

    print("✅ Environment looks good!")
    return True


def run_script_interactive(script_name, args=None):
    """Run a script interactively."""
    if args is None:
        args = []

    python_cmd = get_python_command()
    cmd = [python_cmd, script_name] + args

    print(f"\n🚀 Running: {' '.join(cmd)}")
    print("-" * 50)

    try:
        subprocess.run(cmd, check=False)
        print("-" * 50)
        input("Press Enter to continue...")
    except KeyboardInterrupt:
        print("\n⏹️  Operation cancelled by user")
        input("Press Enter to continue...")


def show_menu():
    """Show the main menu."""
    while True:
        print("\n📋 Main Menu")
        print("=" * 30)
        print("1. 📊 Check system status")
        print("2. 🔄 Update databases")
        print("3. ⚙️  Show configuration")
        print("4. 📂 List databases")
        print("5. 🌐 Start mirror server")
        print("6. 🔍 Health monitor")
        print("7. 📅 Setup scheduling")
        print("8. 📚 Interactive tutorial")
        print("9. 🛠️  Configuration manager")
        print("10. 📖 Show help")
        print("0. ❌ Exit")
        print()

        try:
            choice = input("Choose an option (0-10): ").strip()

            if choice == "0":
                print("👋 Goodbye!")
                break
            elif choice == "1":
                run_script_interactive("monitor.py", ["--health"])
            elif choice == "2":
                verbose = input("Use verbose output? (y/N): ").lower().startswith('y')
                args = ["-v"] if verbose else []
                run_script_interactive("update_databases.py", args)
            elif choice == "3":
                run_script_interactive("config_manager.py", ["show"])
            elif choice == "4":
                run_script_interactive("update_databases.py", ["--list"])
            elif choice == "5":
                print("Starting mirror server (Press Ctrl+C to stop)")
                run_script_interactive("serve_mirror.py", ["--check"])
                start = input("Start the server? (y/N): ").lower().startswith('y')
                if start:
                    print("Server will start. Press Ctrl+C to stop it.")
                    run_script_interactive("serve_mirror.py")
            elif choice == "6":
                run_script_interactive("monitor.py")
            elif choice == "7":
                run_script_interactive("schedule_updates.py", ["--cron"])
            elif choice == "8":
                run_script_interactive("example_usage.py")
            elif choice == "9":
                show_config_menu()
            elif choice == "10":
                show_help()
            else:
                print("❌ Invalid choice. Please try again.")

        except KeyboardInterrupt:
            print("\n👋 Goodbye!")
            break
        except EOFError:
            print("\n👋 Goodbye!")
            break


def show_config_menu():
    """Show configuration management submenu."""
    while True:
        print("\n⚙️  Configuration Manager")
        print("=" * 30)
        print("1. 📋 Show current configuration")
        print("2. 📁 Set database directory")
        print("3. 📄 Set log directory")
        print("4. 🌐 Set DNS nameserver")
        print("5. ➕ Add custom database")
        print("6. 📂 List databases")
        print("7. 💾 Backup configuration")
        print("0. ⬅️  Back to main menu")
        print()

        try:
            choice = input("Choose an option (0-7): ").strip()

            if choice == "0":
                break
            elif choice == "1":
                run_script_interactive("config_manager.py", ["show"])
            elif choice == "2":
                path = input("Enter database directory path: ").strip()
                if path:
                    run_script_interactive("config_manager.py", ["set-dbdir", path])
            elif choice == "3":
                path = input("Enter log directory path: ").strip()
                if path:
                    run_script_interactive("config_manager.py", ["set-logdir", path])
            elif choice == "4":
                ns = input("Enter DNS nameserver IP: ").strip()
                if ns:
                    run_script_interactive("config_manager.py", ["set-nameserver", ns])
            elif choice == "5":
                name = input("Enter database name (e.g., linux.cvd): ").strip()
                url = input("Enter database URL: ").strip()
                if name and url:
                    run_script_interactive("config_manager.py", ["add-database", name, url])
            elif choice == "6":
                run_script_interactive("config_manager.py", ["list"])
            elif choice == "7":
                run_script_interactive("config_manager.py", ["backup"])
            else:
                print("❌ Invalid choice. Please try again.")

        except KeyboardInterrupt:
            break
        except EOFError:
            break


def show_help():
    """Show help information."""
    print("\n📖 Help Information")
    print("=" * 40)
    print("This system provides comprehensive ClamAV database management.")
    print()
    print("🔧 Setup:")
    print("- If this is your first time, run the tutorial (option 8)")
    print("- Check system status first (option 1)")
    print("- Update databases to get started (option 2)")
    print()
    print("📋 Common Workflows:")
    print("1. First time: Status → Update → Monitor")
    print("2. Regular use: Update → Monitor")
    print("3. Server setup: Update → Configure → Start server")
    print("4. Automation: Update → Setup scheduling")
    print()
    print("🆘 Troubleshooting:")
    print("- Use the health monitor to check for issues")
    print("- Check configuration if updates fail")
    print("- Ensure internet connectivity")
    print("- Review logs in ~/.cvdupdate/logs/")
    print()
    print("📚 Documentation:")
    print("- Each script supports --help for detailed options")
    print("- See README.md for comprehensive documentation")
    print("- Visit https://github.com/Cisco-Talos/cvdupdate for upstream docs")

    input("\nPress Enter to return to menu...")


def main():
    """Main function."""
    print_banner()

    if not check_setup():
        sys.exit(1)

    # Quick status check
    print("🔍 Quick status check...")
    python_cmd = get_python_command()
    try:
        result = subprocess.run([python_cmd, "monitor.py", "--health"],
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print("✅ System appears healthy")
        else:
            print("⚠️  System needs attention (check status for details)")
    except Exception as e:
        print(f"⚠️  Could not check status: {e}")

    print("\nWelcome to the ClamAV Database Management System!")
    print("Use the menu below to manage your databases.")

    show_menu()


if __name__ == '__main__':
    main()
