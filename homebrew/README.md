# Homebrew Package Management

This directory contains scripts to maintain Homebrew package and cask installations across developer machines.

## Purpose

The `install_brew_packages.sh` script:
- Downloads and installs Homebrew formulae from the remote `brew_list.txt` file
- Downloads and installs Homebrew casks from the remote `cask_list.txt` file
- Installs packages first, then casks
- Handles errors gracefully and logs all operations
- Can be run repeatedly to keep packages up-to-date

The `upgrade_brew_packages.sh` script:
- Updates Homebrew itself to the latest version
- Upgrades all installed Homebrew formulae to their latest versions
- Upgrades all installed Homebrew casks to their latest versions
- Performs cleanup to remove old versions and clear cache
- Handles errors gracefully and logs all operations
- Provides a summary of the upgrade process

## Usage

### Install Packages from Main Branch

To install using the latest script and package lists from the `main` branch, run:

```bash
curl -fsSL https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/refs/heads/main/homebrew/install_brew_packages.sh | bash
```

### With Debugging

```bash
curl -fsSL https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/refs/heads/main/homebrew/install_brew_packages.sh | bash -x
```

### Manual Download & Run

```bash
curl -O https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/refs/heads/main/homebrew/install_brew_packages.sh
chmod +x install_brew_packages.sh
./install_brew_packages.sh
```

### Upgrade Packages from Main Branch

To upgrade all installed Homebrew packages and casks using the latest script from the `main` branch, run:

```bash
curl -fsSL https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/refs/heads/main/homebrew/upgrade_brew_packages.sh | bash
```

### With Debugging

```bash
curl -fsSL https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/refs/heads/main/homebrew/upgrade_brew_packages.sh | bash -x
```

### Manual Download & Run

```bash
curl -O https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/refs/heads/main/homebrew/upgrade_brew_packages.sh
chmod +x upgrade_brew_packages.sh
./upgrade_brew_packages.sh
```

## Package List Management

### Package Sources
- **Formulae**: Downloaded from the remote `brew_list.txt` file in the main branch
- **Casks**: Downloaded from the remote `cask_list.txt` file in the main branch

### Adding Packages
- To add formulae: Edit the `brew_list.txt` file in the repository's main branch
- To add casks: Edit the `cask_list.txt` file in the repository's main branch

### Installation Order
1. All Homebrew formulae are installed first
2. All Homebrew casks are installed second

## Requirements

- macOS or Linux with Homebrew installed
- `curl` command available
- Write permissions in your home directory for logs

## Notes

- The script will skip already installed packages and casks
- Failed installations are logged but don't stop the entire process
- Logs are written to `~/install_brew_packages.log`
- Package lists are downloaded from the `main` branch
- Temporary files are cleaned up after installation
