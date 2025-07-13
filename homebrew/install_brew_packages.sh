#!/usr/bin/env bash

# Script to install Homebrew packages and casks from GitHub repository
# Downloads package lists and installs formulae first, then casks
# Handles errors gracefully and logs all operations

set -euo pipefail

BREW_LIST_URL="https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/refs/heads/main/homebrew/brew_list.txt"
CASK_LIST_URL="https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/refs/heads/main/homebrew/cask_list.txt"
LOG_FILE="${HOME:-/tmp}/install_brew_packages.log"
TEMP_BREW_LIST="/tmp/brew_list.txt"
TEMP_CASK_LIST="/tmp/cask_list.txt"

# Log a message with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Download the brew list file
download_brew_list() {
    log "Downloading brew list from $BREW_LIST_URL"
    if curl -sSf "$BREW_LIST_URL" -o "$TEMP_BREW_LIST"; then
        log "Successfully downloaded brew list"
    else
        log "ERROR: Failed to download brew list from $BREW_LIST_URL"
        exit 1
    fi
}

# Download the cask list file
download_cask_list() {
    log "Downloading cask list from $CASK_LIST_URL"
    if curl -sSf "$CASK_LIST_URL" -o "$TEMP_CASK_LIST"; then
        log "Successfully downloaded cask list"
    else
        log "ERROR: Failed to download cask list from $CASK_LIST_URL"
        exit 1
    fi
}

# Install a single package (formula only)
install_package() {
    local pkg="$1"
    if brew list --formula | grep -qx "$pkg"; then
        log "Formula '$pkg' is already installed."
        return 0
    fi

    if brew info --formula "$pkg" &>/dev/null; then
        log "Installing formula: $pkg"
        if brew install "$pkg"; then
            log "Successfully installed formula: $pkg"
        else
            log "ERROR: Failed to install formula: $pkg"
            return 1
        fi
    else
        log "WARNING: Package '$pkg' not found as formula."
        return 2
    fi
}

# Install a single cask
install_cask() {
    local cask="$1"
    if brew list --cask | grep -qx "$cask"; then
        log "Cask '$cask' is already installed."
        return 0
    fi

    if brew info --cask "$cask" &>/dev/null; then
        log "Installing cask: $cask"
        if brew install --cask "$cask"; then
            log "Successfully installed cask: $cask"
        else
            log "ERROR: Failed to install cask: $cask"
            return 1
        fi
    else
        log "WARNING: Cask '$cask' not found."
        return 2
    fi
}

main() {
    if ! command -v brew &>/dev/null; then
        log "ERROR: Homebrew is not installed. Please install Homebrew first."
        exit 1
    fi

    download_brew_list
    download_cask_list

    log "Starting Homebrew package installation..."
    local failed=0

    # Install packages first
    while IFS= read -r pkg; do
        # Skip empty lines and comments
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
        if ! install_package "$pkg"; then
            log "ERROR: Installation failed for package: $pkg"
            failed=1
        fi
    done < "$TEMP_BREW_LIST"

    log "Starting Homebrew cask installation..."
    
    # Install casks after packages
    while IFS= read -r cask; do
        # Skip empty lines and comments
        [[ -z "$cask" || "$cask" =~ ^# ]] && continue
        if ! install_cask "$cask"; then
            log "ERROR: Installation failed for cask: $cask"
            failed=1
        fi
    done < "$TEMP_CASK_LIST"

    # Clean up temporary files
    rm -f "$TEMP_BREW_LIST" "$TEMP_CASK_LIST"

    if [[ $failed -eq 0 ]]; then
        log "All packages and casks installed successfully."
        exit 0
    else
        log "Some packages or casks failed to install. Check the log for details."
        exit 2
    fi
}

main "$@"
