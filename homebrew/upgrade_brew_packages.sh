#!/usr/bin/env bash

# Script to upgrade all Homebrew packages and casks
# Performs upgrades with error handling and cleanup
# Logs all operations for troubleshooting

set -euo pipefail

LOG_FILE="${HOME:-/tmp}/upgrade_brew_packages.log"

# Log a message with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Check if Homebrew is installed
check_homebrew() {
    if ! command -v brew &>/dev/null; then
        log "ERROR: Homebrew is not installed. Please install Homebrew first."
        exit 1
    fi
    log "Homebrew is installed and available"
}

# Update Homebrew itself
update_homebrew() {
    log "Updating Homebrew..."
    if brew update; then
        log "Successfully updated Homebrew"
    else
        log "ERROR: Failed to update Homebrew"
        return 1
    fi
}

# Upgrade all formulae
upgrade_formulae() {
    log "Upgrading all Homebrew formulae..."
    local outdated_formulae
    outdated_formulae=$(brew outdated --formula --quiet)
    
    if [[ -z "$outdated_formulae" ]]; then
        log "All formulae are already up to date"
        return 0
    fi
    
    log "Found outdated formulae: $(echo "$outdated_formulae" | tr '\n' ' ')"
    
    if brew upgrade --formula; then
        log "Successfully upgraded all formulae"
    else
        log "ERROR: Failed to upgrade some formulae"
        return 1
    fi
}

# Upgrade all casks
upgrade_casks() {
    log "Upgrading all Homebrew casks..."
    local outdated_casks
    outdated_casks=$(brew outdated --cask --quiet)
    
    if [[ -z "$outdated_casks" ]]; then
        log "All casks are already up to date"
        return 0
    fi
    
    log "Found outdated casks: $(echo "$outdated_casks" | tr '\n' ' ')"
    
    if brew upgrade --cask; then
        log "Successfully upgraded all casks"
    else
        log "ERROR: Failed to upgrade some casks"
        return 1
    fi
}

# Clean up old versions and cache
cleanup_homebrew() {
    log "Cleaning up Homebrew cache and old versions..."
    if brew cleanup; then
        log "Successfully cleaned up Homebrew"
    else
        log "ERROR: Failed to clean up Homebrew"
        return 1
    fi
}

# Display summary of installed packages
show_summary() {
    log "Upgrade summary:"
    local formula_count
    local cask_count
    formula_count=$(brew list --formula | wc -l | tr -d ' ')
    cask_count=$(brew list --cask | wc -l | tr -d ' ')
    
    log "Total formulae installed: $formula_count"
    log "Total casks installed: $cask_count"
    
    # Show any remaining outdated packages
    local outdated_formulae
    local outdated_casks
    outdated_formulae=$(brew outdated --formula --quiet)
    outdated_casks=$(brew outdated --cask --quiet)
    
    if [[ -n "$outdated_formulae" ]]; then
        log "WARNING: Some formulae are still outdated: $(echo "$outdated_formulae" | tr '\n' ' ')"
    fi
    
    if [[ -n "$outdated_casks" ]]; then
        log "WARNING: Some casks are still outdated: $(echo "$outdated_casks" | tr '\n' ' ')"
    fi
    
    if [[ -z "$outdated_formulae" && -z "$outdated_casks" ]]; then
        log "All packages are up to date!"
    fi
}

main() {
    log "Starting Homebrew upgrade process..."
    local failed=0
    
    # Check prerequisites
    check_homebrew
    
    # Update Homebrew itself
    if ! update_homebrew; then
        log "ERROR: Failed to update Homebrew"
        failed=1
    fi
    
    # Upgrade formulae
    if ! upgrade_formulae; then
        log "ERROR: Failed to upgrade formulae"
        failed=1
    fi
    
    # Upgrade casks
    if ! upgrade_casks; then
        log "ERROR: Failed to upgrade casks"
        failed=1
    fi
    
    # Clean up
    if ! cleanup_homebrew; then
        log "ERROR: Failed to clean up Homebrew"
        failed=1
    fi
    
    # Show summary
    show_summary
    
    if [[ $failed -eq 0 ]]; then
        log "Homebrew upgrade completed successfully!"
        exit 0
    else
        log "Homebrew upgrade completed with some errors. Check the log for details."
        exit 2
    fi
}

main "$@"
