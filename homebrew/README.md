# Homebrew Package Management

This directory contains scripts to maintain consistent Homebrew package installations across developer machines.

## Purpose

The `install_brew_packages.sh` script:
- Downloads the latest package list from GitHub
- Installs all listed Homebrew formulae and casks
- Handles errors gracefully and logs all operations
- Can be run repeatedly to keep packages up-to-date

## Usage

### Basic Installation
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/YOUR_REPO/main/homebrew/install_brew_packages.sh)"
```

### With Debugging
```bash
/bin/bash -x -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/YOUR_REPO/main/homebrew/install_brew_packages.sh)"
```

### Manual Download & Run
```bash
curl -O https://raw.githubusercontent.com/YOUR_ORG/YOUR_REPO/main/homebrew/install_brew_packages.sh
chmod +x install_brew_packages.sh
./install_brew_packages.sh
```

## Package List Management

1. Edit `brew_list.txt` to add/remove packages
2. Commit and push changes
3. All team members can run the installer to sync their packages

## Requirements

- macOS or Linux with Homebrew installed
- `curl` command available
- Write permissions in your home directory for logs

## Notes

- The script will skip already installed packages
- Failed installations are logged but don't stop the entire process
- Logs are written to `~/install_brew_packages.log`
