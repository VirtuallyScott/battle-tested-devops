# Development Environment Setup Tools

This repository contains scripts to configure and maintain a secure development environment.

## Main Installer: `install_misc.sh`

The primary installation script that sets up all configurations.

### Features:
- Installs Zsh configuration files (`.zshrc`, `.zlogout`)
- Sets up secure environment directories (`~/.env`, `~/.secure_env`)
- Downloads and installs utility scripts
- Handles backups of existing files
- Provides detailed logging

### Installation:

Recommended method:
```bash
curl -sSL https://raw.githubusercontent.com/codeSnapped-LLC/misc/refs/heads/develop/install_misc.sh -o install_misc.sh
chmod +x install_misc.sh
./install_misc.sh
```

One-line method (less recommended):
```bash
curl -sSL https://raw.githubusercontent.com/codeSnapped-LLC/misc/refs/heads/develop/install_misc.sh | bash
```

Alternative method (clone repo):
```bash
git clone https://github.com/codeSnapped-LLC/misc.git
cd misc
./install_misc.sh
```

## Utility Scripts

### 1. `refresh_scripts.sh`
Updates all installed scripts to their latest versions.

**Usage:**
```bash
~/scripts/refresh_scripts.sh
```

**Features:**
- Downloads latest versions of all scripts
- Preserves existing permissions
- Maintains detailed log file
- Can self-update
- Safe error handling

### 2. `create_uv_env.sh`
Creates Python virtual environments using UV.

**Usage:**
```bash
./create_uv_env.sh [env_name]  # Default: .venv
```

**Features:**
- Creates UV virtual environment
- Upgrades pip automatically
- Generates empty `.env` and `requirements.txt` if missing
- Validates UV installation

### 3. `fix_permissions.sh`
Unified permissions management for secure directories and files.

**Usage:**
```bash
./fix_permissions.sh
```

**Features:**
- Handles multiple secure locations:
  - `~/.ssh` directory and key files
  - `~/.env` directory and files
  - `~/.secure_env` directory and files
- Sets appropriate permissions for each file type:
  - 700 for secure directories
  - 600 for sensitive files
  - 644 for non-sensitive configs
- Color-coded output and error handling
- Detailed logging of changes

### 4. `setup_git_config.sh`
Interactive Git configuration setup.

**Usage:**
```bash
./setup_git_config.sh
```

**Features:**
- Guides through global Git setup
- Validates email format
- Provides sensible defaults
- Shows confirmation before applying changes

## Security Features

All scripts include:
- Strict error handling (`set -euo pipefail`)
- Permission validation
- Backup systems for existing files
- Detailed logging
- Input validation where applicable

## Requirements

- Bash 4.0+
- Core utilities (curl, chmod, etc.)
- For UV script: Python and UV installed

## Best Practices

1. Review scripts before running
2. Check logs after installation:
   - Main installer: `~/misc_install.log`
   - Permission scripts: `~/.env/.permissions_log` and `~/.secure_env/.permissions_log`
3. Store sensitive data only in `~/.secure_env/`
