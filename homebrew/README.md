# Homebrew Package Management

This directory contains scripts to maintain role-specific Homebrew package installations across developer machines.

## Purpose

The `install_brew_packages.sh` script:
- Presents a menu of available roles (DevOps, QA Engineer, Cloud Engineer)
- Downloads the appropriate package list for the selected role
- Installs all listed Homebrew formulae and casks
- Handles errors gracefully and logs all operations
- Can be run repeatedly to keep packages up-to-date

## Usage

### Install from Main Branch

To install using the latest script and package list from the `main` branch, run:

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

## Package List Management

### Role-Specific Packages
Each role has its own package list file following this naming convention:
- `brewList-devops.txt`
- `brewList-qa-engineer.txt`
- `brewList-cloud-engineer.txt`

To add a new role:
1. Create a new package list file with the naming pattern `brewList-<role>.txt`
   - Use lowercase
   - Hyphenate spaces (e.g., "data-engineer" becomes `brewList-data-engineer.txt`)
2. Add the role name to the `ROLES` array in `install_brew_packages.sh`
3. Commit and push changes to the `develop` branch

## Requirements

- macOS or Linux with Homebrew installed
- `curl` command available
- Write permissions in your home directory for logs

## Notes

- The script will skip already installed packages
- Failed installations are logged but don't stop the entire process
- Logs are written to `~/install_brew_packages.log`
- Package lists are pulled from the `develop` branch by default
- Default role if not specified: DevOps
