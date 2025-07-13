# Homebrew Package Management

This directory contains scripts to maintain Homebrew package and cask installations across developer machines.

## Purpose

The `install_brew_packages.sh` script:
- Installs Homebrew formulae from the local `brew_list.txt` file
- Installs Homebrew casks from the local `cask_list.txt` file
- Installs packages first, then casks
- Handles errors gracefully and logs all operations
- Can be run repeatedly to keep packages up-to-date

## Usage

### Local Execution

To run the script locally (requires the repository to be cloned):

```bash
cd homebrew
./install_brew_packages.sh
```

### With Debugging

```bash
cd homebrew
bash -x install_brew_packages.sh
```

## Package List Management

### Package Sources
- **Formulae**: Listed in the local `brew_list.txt` file
- **Casks**: Listed in the local `cask_list.txt` file

### Adding Packages
- To add formulae: Edit the local `brew_list.txt` file
- To add casks: Edit the local `cask_list.txt` file

### Installation Order
1. All Homebrew formulae are installed first
2. All Homebrew casks are installed second

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
