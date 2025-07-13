#!/usr/bin/env bash

# Script to install Homebrew packages from local brew_list.txt file
# Handles both formulae and casks, with error handling and logging.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREW_LIST_FILE="${SCRIPT_DIR}/brew_list.txt"
LOG_FILE="${HOME:-/tmp}/install_brew_packages.log"

# Log a message with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Check if the brew list file exists
check_brew_list() {
    log "Checking for brew list at $BREW_LIST_FILE"
    if [[ -f "$BREW_LIST_FILE" ]]; then
        log "Found brew list file"
    else
        log "ERROR: Brew list file not found at $BREW_LIST_FILE"
        exit 1
    fi
}

# Install a single package (formula or cask)
install_package() {
    local pkg="$1"
    if brew list --formula | grep -qx "$pkg"; then
        log "Formula '$pkg' is already installed."
        return 0
    fi
    if brew list --cask | grep -qx "$pkg"; then
        log "Cask '$pkg' is already installed."
        return 0
    fi

    # Try as formula first, then as cask
    if brew info --formula "$pkg" &>/dev/null; then
        log "Installing formula: $pkg"
        if brew install "$pkg"; then
            log "Successfully installed formula: $pkg"
        else
            log "ERROR: Failed to install formula: $pkg"
            return 1
        fi
    elif brew info --cask "$pkg" &>/dev/null; then
        log "Installing cask: $pkg"
        if brew install --cask "$pkg"; then
            log "Successfully installed cask: $pkg"
        else
            log "ERROR: Failed to install cask: $pkg"
            return 1
        fi
    else
        log "WARNING: Package '$pkg' not found as formula or cask."
        return 2
    fi
}

main() {
    if ! command -v brew &>/dev/null; then
        log "ERROR: Homebrew is not installed. Please install Homebrew first."
        exit 1
    fi

    check_brew_list

    log "Starting Homebrew package installation..."
    local failed=0

    while IFS= read -r pkg; do
        # Skip empty lines and comments
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
        if ! install_package "$pkg"; then
            log "ERROR: Installation failed for package: $pkg"
            failed=1
        fi
    done < "$BREW_LIST_FILE"

    if [[ $failed -eq 0 ]]; then
        log "All packages installed successfully."
        exit 0
    else
        log "Some packages failed to install. Check the log for details."
        exit 2
    fi
}

main "$@"
