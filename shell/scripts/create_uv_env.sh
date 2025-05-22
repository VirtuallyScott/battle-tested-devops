#!/bin/bash

# Create a new Python virtual environment using UV
# Also generates empty .env and requirements.txt files if missing

set -euo pipefail

DEFAULT_ENV_NAME=".venv"

log() {
  echo "[INFO] $1"
}

warn() {
  echo "[WARN] $1" >&2
}

error_exit() {
  echo "[ERROR] $1" >&2
  exit 1
}

check_dependencies() {
  if ! command -v uv >/dev/null 2>&1; then
    error_exit "'uv' is not installed or not in PATH. Install via: pipx install uv"
  fi
}

create_env() {
  local env_name="$1"

  if [ -d "$env_name" ]; then
    error_exit "Directory '$env_name' already exists. Choose another name or remove it."
  fi

  log "Creating UV environment in '$env_name'..."
  uv venv "$env_name" || error_exit "Failed to create UV environment."

  log "Activating environment and upgrading pip..."
  source "$env_name/bin/activate"
  python -m ensurepip --upgrade || error_exit "Failed to upgrade pip."

  log "Virtual environment created and pip installed."
}

init_project_files() {
  # Create .env with secure permissions
  if [ ! -f .env ]; then
    touch .env
    chmod 600 .env
    log "Created empty .env with secure permissions (600)"
  else
    log ".env already exists — ensuring permissions..."
    chmod 600 .env
  fi
  
  if [ ! -f requirements.txt ]; then
    touch requirements.txt
    log "Created empty requirements.txt"
  else
    log "requirements.txt already exists — skipped."
  fi
}

main() {
  check_dependencies
  local env_dir="${1:-$DEFAULT_ENV_NAME}"
  create_env "$env_dir"
  init_project_files
  log "Setup complete. Activate with: source $env_dir/bin/activate"
}

main "$@"
