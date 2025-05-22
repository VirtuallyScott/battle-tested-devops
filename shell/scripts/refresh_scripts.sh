#!/bin/bash

# Refresh all scripts from the repository without full reinstallation
# Maintains existing permissions and configurations

set -euo pipefail

# Constants
REPO_BASE="https://raw.githubusercontent.com/codeSnapped-LLC/misc"
REPO_BRANCH="refs/heads/develop"
REPO_URL="$REPO_BASE/$REPO_BRANCH"
SCRIPTS_DIR="$HOME/scripts"
LOG_FILE="$HOME/scripts_refresh.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log() {
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

success() {
  echo -e "${GREEN}$1${NC}" | tee -a "$LOG_FILE"
}

warn() {
  echo -e "${YELLOW}$1${NC}" | tee -a "$LOG_FILE"
}

error() {
  echo -e "${RED}$1${NC}" | tee -a "$LOG_FILE"
}

# Check dependencies
check_dependencies() {
  if ! command -v curl >/dev/null 2>&1; then
    error "curl is required but not installed."
    return 1
  fi
  return 0
}

# Download and update a single script
update_script() {
  local script_name="$1"
  local temp_file
  temp_file=$(mktemp)
  
  log "Updating $script_name..."
  
  if ! curl -sSL -f "$REPO_URL/scripts/$script_name" -o "$temp_file" 2>> "$LOG_FILE"; then
    warn "Failed to download $script_name"
    rm -f "$temp_file"
    return 1
  fi
  
  # Verify it's not an HTML error page
  if head -1 "$temp_file" | grep -q "<html"; then
    warn "Downloaded HTML error page for $script_name"
    rm -f "$temp_file"
    return 1
  fi
  
  # Preserve existing permissions
  local orig_perm="755"
  if [ -f "$SCRIPTS_DIR/$script_name" ]; then
    orig_perm=$(stat -c %a "$SCRIPTS_DIR/$script_name")
  fi
  
  mv "$temp_file" "$SCRIPTS_DIR/$script_name"
  chmod "$orig_perm" "$SCRIPTS_DIR/$script_name"
  
  log "Successfully updated $script_name (permissions: $orig_perm)"
  return 0
}

main() {
  log "Starting script refresh..."
  
  if ! check_dependencies; then
    error "Dependency check failed"
    exit 1
  fi
  
  if [ ! -d "$SCRIPTS_DIR" ]; then
    error "Scripts directory $SCRIPTS_DIR does not exist"
    exit 1
  fi
  
  # List of scripts to update (same as install_misc.sh)
  local scripts=(
    "fix_permissions.sh"
    "create_uv_env.sh"
    "refresh_scripts.sh"  # Self-updating
  )
  
  local errors=0
  for script in "${scripts[@]}"; do
    if ! update_script "$script"; then
      ((errors++))
    fi
  done
  
  if [ $errors -eq 0 ]; then
    success "All scripts updated successfully!"
  else
    warn "Completed with $errors error(s)"
  fi
  
  log "Refresh completed. Details logged to $LOG_FILE"
}

main "$@"
