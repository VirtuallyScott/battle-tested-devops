# macOS Development Environment Configuration

This repository contains scripts to configure and maintain a secure development environment on Apple Silicon Macs.

## Main Installer: `install_misc.sh`

The primary installation script that configures Zsh and maintains environment hygiene.

### Purpose:
- Configures Zsh for optimal development on Apple Silicon Macs
- Maintains security hygiene by separating sensitive data from configuration files
- Provides utility scripts for common development tasks

### Key Features:
- Installs optimized Zsh configuration files (`.zshrc`, `.zlogout`)
- Sets up secure environment directories with proper permissions:
  - `~/.env` for general environment variables (700)
  - `~/.secure_env` for sensitive credentials (700)
- Implements secure credential handling:
  - Sensitive variables are loaded from separate, permission-protected files
  - Never stores credentials directly in `.zshrc`
- Includes utility scripts for:
  - Virtual environment management (UV)
  - Permission hygiene
  - Script updates
- Handles backups of existing files before modification
- Provides detailed logging of all changes

### Installation:

For Apple Silicon Macs (Recommended):

1. Download and review:
```bash
curl -sSL https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/refs/heads/main/shell/install_misc.sh -o install_misc.sh
chmod +x install_misc.sh
./install_misc.sh
```

2. One-line method (less recommended):
```bash
curl -sSL https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/refs/heads/main/shell/install_misc.sh | bash
```

3. Alternative method (clone repo):
```bash
git clone https://github.com/VirtuallyScott/battle-tested-devops.git -b main
cd battle-tested-devops/shell
./install_misc.sh
```

### Post-Installation:
- Review the installed `.zshrc` and `.zlogout` files
- Store sensitive credentials in `~/.secure_env/secrets.sh` (automatically created with 600 permissions)
- General environment variables can go in `~/.secure_env/exports.sh`

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
