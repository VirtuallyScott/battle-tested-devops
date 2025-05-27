#!/usr/bin/env bash

# Script to install Homebrew packages from a GitHub raw URL
# Handles both formulae and casks, with error handling and logging.

set -euo pipefail

# Available roles
ROLES=("DevOps" "QA Engineer" "Cloud Engineer")

# Prompt user to select a role
PS3="Select your role: "
select role in "${ROLES[@]}"; do
    case $role in
        "DevOps"|"QA Engineer"|"Cloud Engineer")
            break
            ;;
        *)
            echo "Invalid selection. Please try again."
            ;;
    esac
done

# Convert role to lowercase with hyphens for filename
formatted_role=$(echo "$role" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
BREW_LIST_URL="https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/refs/heads/develop/homebrew/brewList-${formatted_role}.txt"
LOG_FILE="${HOME:-/tmp}/install_brew_packages.log"
TEMP_BREW_LIST="/tmp/brew_list.txt"

# Log a message with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Download the brew list file
download_brew_list() {
    log "Downloading brew list for $role role from $BREW_LIST_URL"
    if curl -sSf "$BREW_LIST_URL" -o "$TEMP_BREW_LIST"; then
        log "Successfully downloaded brew list"
    else
        log "ERROR: Failed to download brew list from $BREW_LIST_URL"
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

    download_brew_list

    log "Starting Homebrew package installation..."
    local failed=0

    while IFS= read -r pkg; do
        # Skip empty lines and comments
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
        if ! install_package "$pkg"; then
            log "ERROR: Installation failed for package: $pkg"
            failed=1
        fi
    done < "$TEMP_BREW_LIST"

    if [[ $failed -eq 0 ]]; then
        log "All packages installed successfully."
        exit 0
    else
        log "Some packages failed to install. Check the log for details."
        exit 2
    fi
}

main "$@"
