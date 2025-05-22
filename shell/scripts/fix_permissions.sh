#!/bin/sh

# Unified permissions fixing script for secure directories and files
# Compatible with older shells (sh/Bash 3.x)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

fix_permissions() {
    local errors=0
    
    # Process directories
    for dir_perm in \
        "$HOME/.ssh:700" \
        "$HOME/.env:700" \
        "$HOME/.secure_env:700"
    do
        dir="${dir_perm%:*}"
        perm="${dir_perm#*:}"
        
        if [ ! -d "$dir" ]; then
            echo "${YELLOW}Directory $dir does not exist - skipping${NC}"
            continue
        fi
        
        current_perm=$(stat -f "%A" "$dir" 2>/dev/null || echo "000")
        if [ "$current_perm" != "$perm" ]; then
            log "Setting $dir permissions to $perm"
            if ! chmod "$perm" "$dir"; then
                echo "${RED}Failed to set permissions on $dir${NC}"
                errors=$((errors + 1))
            fi
        fi
    done
    
    # Process files
    for file_perm in \
        "$HOME/.ssh/id_rsa:600" \
        "$HOME/.ssh/id_rsa.pub:644" \
        "$HOME/.ssh/authorized_keys:600" \
        "$HOME/.ssh/config:600" \
        "$HOME/.secure_env/secrets.sh:600" \
        "$HOME/.secure_env/exports.sh:644" \
        "$HOME/.env/.env:600"
    do
        file="${file_perm%:*}"
        perm="${file_perm#*:}"
        
        if [ ! -f "$file" ]; then
            echo "${YELLOW}File $file does not exist - skipping${NC}"
            continue
        fi
        
        current_perm=$(stat -f "%A" "$file" 2>/dev/null || echo "000")
        if [ "$current_perm" != "$perm" ]; then
            log "Setting $file permissions to $perm"
            if ! chmod "$perm" "$file"; then
                echo "${RED}Failed to set permissions on $file${NC}"
                errors=$((errors + 1))
            fi
        fi
    done
    
    return $errors
}

main() {
    log "Starting permission fixes..."
    
    if fix_permissions; then
        echo "${GREEN}All permissions verified and corrected successfully${NC}"
    else
        echo "${RED}Completed with some errors (see above)${NC}"
        exit 1
    fi
}

main
