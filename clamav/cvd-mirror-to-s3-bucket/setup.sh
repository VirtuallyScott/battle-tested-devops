#!/bin/bash
# ClamAV Database Update Setup Script

echo "Setting up ClamAV Database Update environment..."

# Activate virtual environment
source .venv/bin/activate

# Verify cvdupdate installation
echo "Checking cvdupdate installation..."
python -c "import cvdupdate; print(f'cvdupdate version: {cvdupdate.__version__}')" 2>/dev/null || echo "cvdupdate not found in Python imports"

# Check if cvd command is available
if command -v cvd &> /dev/null; then
    echo "cvd command is available"
    cvd --help | head -5
else
    echo "cvd command not found in PATH, will use 'python -m cvdupdate'"
    python -m cvdupdate --help | head -5
fi

echo ""
echo "Available scripts:"
echo "  ./update_databases.py     - Update ClamAV databases"
echo "  ./serve_mirror.py         - Serve databases as HTTP mirror"
echo "  ./config_manager.py       - Manage configuration"
echo "  ./schedule_updates.py     - Schedule automatic updates"
echo "  ./cvd_manager.py          - Unified management interface"
echo ""
echo "Examples:"
echo "  ./update_databases.py -v                    # Update with verbose output"
echo "  ./config_manager.py show                    # Show current config"
echo "  ./serve_mirror.py --check                   # Check database directory"
echo "  ./cvd_manager.py update -v                  # Use unified interface"
echo ""
echo "Setup complete!"