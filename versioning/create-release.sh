#!/usr/bin/env bash
# create-release.sh - Automated release creation using GitVersion
# 
# This script:
# 1. Gets the current version from GitVersion
# 2. Creates or switches to a release branch 
# 3. Creates RELEASE_NOTES.md
# 4. Commits and pushes changes
# 5. Tags the release

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Not in a git repository"
        exit 1
    fi
}

# Check if gitversion is available
check_gitversion() {
    if ! command -v gitversion >/dev/null 2>&1; then
        error "gitversion command not found. Please install GitVersion or use the shell version."
        exit 1
    fi
}

# Get clean semver from GitVersion AssemblySemVer output
get_version() {
    local assembly_version
    assembly_version=$(gitversion -o AssemblySemVer)
    
    # Remove the trailing .0 and any % characters
    local clean_version
    clean_version=$(echo "$assembly_version" | sed 's/\.0$//' | tr -d '%')
    
    echo "$clean_version"
}

# Get full semver for tagging
get_full_version() {
    local full_version
    full_version=$(gitversion | tr -d '%')
    echo "$full_version"
}

# Create or switch to release branch
create_release_branch() {
    local version="$1"
    local branch_name="release/v${version}"
    
    log "Checking if release branch exists: $branch_name"
    
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        warn "Release branch $branch_name already exists. Switching to it."
        git checkout "$branch_name"
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
        warn "Remote release branch $branch_name exists. Checking it out."
        git checkout -b "$branch_name" "origin/$branch_name"
    else
        log "Creating new release branch: $branch_name"
        git checkout -b "$branch_name"
    fi
    
    printf "%s" "$branch_name"
}

# Create security manifests (checksums and signatures)
create_security_manifests() {
    local version="$1"
    local checksums_file="SHA256SUMS"
    local signatures_file="SHA256SUMS.sig"
    
    log "Creating security manifests for version $version"
    
    # Create SHA256 checksums for important files
    log "Generating SHA256 checksums..."
    
    # Find all executable scripts and important files
    find . -type f \( \
        -name "*.sh" -o \
        -name "*.py" -o \
        -name "*.go" -o \
        -name "*.json" -o \
        -name "*.yml" -o \
        -name "*.yaml" -o \
        -name "Makefile" -o \
        -name "Dockerfile" -o \
        -name "*.md" \
    \) ! -path "./.git/*" ! -path "./build/*" ! -path "./scans/*" | \
    sort | \
    xargs sha256sum > "$checksums_file"
    
    # Add the release notes to checksums
    if [[ -f "RELEASE_NOTES.md" ]]; then
        sha256sum RELEASE_NOTES.md >> "$checksums_file"
    fi
    
    log "Created $checksums_file with $(wc -l < "$checksums_file") file checksums"
    
    # Attempt to create GPG signature if GPG is available and configured
    if command -v gpg >/dev/null 2>&1; then
        local gpg_key_id
        gpg_key_id=$(git config --get user.signingkey 2>/dev/null || echo "")
        
        if [[ -n "$gpg_key_id" ]]; then
            log "Creating GPG signature with key: $gpg_key_id"
            if gpg --detach-sign --armor --output "$signatures_file" "$checksums_file" 2>/dev/null; then
                success "Created GPG signature: $signatures_file"
            else
                warn "Failed to create GPG signature. Continuing without signature."
            fi
        else
            warn "No GPG signing key configured. Skipping signature creation."
            warn "To enable signing: git config user.signingkey <your-key-id>"
        fi
    else
        warn "GPG not available. Skipping signature creation."
    fi
    
    # Create verification instructions
    cat > "VERIFY.md" << EOF
# Security Verification

This release includes integrity verification files to ensure the authenticity and integrity of the code.

## Files

- \`SHA256SUMS\` - SHA256 checksums for all important files
$(if [[ -f "$signatures_file" ]]; then echo "- \`SHA256SUMS.sig\` - GPG signature of the checksums file"; fi)
- \`VERIFY.md\` - This verification guide

## Verification Steps

### 1. Verify File Integrity

\`\`\`bash
# Download the release files
curl -L -O https://github.com/VirtuallyScott/battle-tested-devops/releases/download/v${version}/SHA256SUMS

# Verify checksums of downloaded files
sha256sum -c SHA256SUMS

# Or verify specific files
sha256sum gitversion-sh/gitversion.sh
grep "gitversion-sh/gitversion.sh" SHA256SUMS
\`\`\`

$(if [[ -f "$signatures_file" ]]; then cat << 'GPGEOF'
### 2. Verify GPG Signature

```bash
# Download the signature file
curl -L -O https://github.com/VirtuallyScott/battle-tested-devops/releases/download/v${version}/SHA256SUMS.sig

# Import the public key (first time only)
curl -L https://github.com/VirtuallyScott.gpg | gpg --import

# Verify the signature
gpg --verify SHA256SUMS.sig SHA256SUMS
```

### 3. Verify GPG Key Fingerprint

Ensure the GPG key fingerprint matches the expected value:

```bash
gpg --fingerprint
```

Expected fingerprint: [To be added - run 'gpg --fingerprint' to get your key fingerprint]
GPGEOF
fi)

## Security Best Practices

1. **Always verify checksums** before using downloaded files
2. **Check GPG signatures** if available to ensure authenticity
3. **Use HTTPS** when downloading release files
4. **Verify the source** - only download from official GitHub releases
5. **Keep verification files** for audit trails

## Reporting Security Issues

If you discover a security vulnerability or integrity issue, please report it privately to:
- GitHub Security Advisories: https://github.com/VirtuallyScott/battle-tested-devops/security/advisories
- Email: [security contact to be added]

## Automated Verification

You can automate verification in your CI/CD pipelines:

\`\`\`bash
#!/bin/bash
# verify-release.sh - Automated release verification

set -euo pipefail

VERSION="\${1:-latest}"
BASE_URL="https://github.com/VirtuallyScott/battle-tested-devops/releases/download/v\${VERSION}"

# Download checksums
curl -L -O "\${BASE_URL}/SHA256SUMS"

# Download signature if available
if curl -L -f -O "\${BASE_URL}/SHA256SUMS.sig"; then
    echo "Verifying GPG signature..."
    gpg --verify SHA256SUMS.sig SHA256SUMS || {
        echo "GPG verification failed!"
        exit 1
    }
fi

# Verify checksums
echo "Verifying file integrity..."
sha256sum -c SHA256SUMS || {
    echo "Checksum verification failed!"
    exit 1
}

echo "Release verification successful!"
\`\`\`
EOF

    success "Created security verification files"
}

# Create RELEASE_NOTES.md
create_release_notes() {
    local version="$1"
    local full_version="$2"
    local release_notes_file="RELEASE_NOTES.md"
    
    log "Creating $release_notes_file for version $version"
    
    # Get the current date
    local release_date
    release_date=$(date '+%Y-%m-%d')
    
    # Get recent commits for changelog (since last tag or last 10 commits)
    local last_tag
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    local commit_range
    if [[ -n "$last_tag" ]]; then
        commit_range="${last_tag}..HEAD"
    else
        commit_range="HEAD~10..HEAD"
    fi
    
    # Generate release notes
    cat > "$release_notes_file" << EOF
# Release Notes - v${version}

**Release Date:** ${release_date}
**Full Version:** ${full_version}

## What's Changed

$(git log --pretty=format:"- %s (%h)" --no-merges "$commit_range" 2>/dev/null || echo "- Initial release")

## Security & Integrity

This release includes integrity verification:

- **SHA256 Checksums**: \`SHA256SUMS\` file contains checksums for all important files
- **GPG Signature**: \`SHA256SUMS.sig\` provides cryptographic verification (if available)
- **Verification Guide**: \`VERIFY.md\` contains detailed verification instructions

### Quick Verification

\`\`\`bash
# Download and verify checksums
curl -L -O https://github.com/VirtuallyScott/battle-tested-devops/releases/download/v${version}/SHA256SUMS
sha256sum -c SHA256SUMS

# Verify GPG signature (if available)
curl -L -O https://github.com/VirtuallyScott/battle-tested-devops/releases/download/v${version}/SHA256SUMS.sig
gpg --verify SHA256SUMS.sig SHA256SUMS
\`\`\`

## Installation

\`\`\`bash
# Download the latest release
curl -L -o gitversion https://github.com/VirtuallyScott/battle-tested-devops/releases/download/v${version}/gitversion-\$(uname -s | tr '[:upper:]' '[:lower:]')-\$(uname -m)
chmod +x gitversion
sudo mv gitversion /usr/local/bin/
\`\`\`

## Verification

\`\`\`bash
gitversion --version
# Should output: v${version}
\`\`\`

---

For detailed documentation, see the [README](README.md).
For issues or questions, please visit the [GitHub repository](https://github.com/VirtuallyScott/battle-tested-devops).
EOF

    success "Created $release_notes_file"
}

# Commit and push changes
commit_and_push() {
    local version="$1"
    local branch_name="$2"
    
    log "Adding release files to git"
    git add RELEASE_NOTES.md SHA256SUMS VERIFY.md
    
    # Add signature file if it exists
    if [[ -f "SHA256SUMS.sig" ]]; then
        git add SHA256SUMS.sig
        log "Added GPG signature to commit"
    fi
    
    log "Committing release files"
    git commit -m "docs: add release v${version} with security manifests [skip ci]

- Release notes with changelog and security information
- SHA256 checksums for integrity verification
- Verification instructions and best practices
$(if [[ -f "SHA256SUMS.sig" ]]; then echo "- GPG signature for authenticity verification"; fi)"
    
    log "Pushing release branch to origin"
    git push -u origin "$branch_name"
    
    success "Committed and pushed changes to $branch_name"
}

# Tag the release
tag_release() {
    local version="$1"
    local full_version="$2"
    local tag_name="v${version}"
    
    log "Creating tag: $tag_name"
    
    # Create annotated tag with full version info
    git tag -a "$tag_name" -m "Release v${version}

Full version: ${full_version}
Release date: $(date '+%Y-%m-%d %H:%M:%S %Z')

See RELEASE_NOTES.md for detailed changelog."

    log "Pushing tag to origin"
    git push origin "$tag_name"
    
    success "Tagged release as $tag_name"
}

# Main function
main() {
    local dry_run=false
    local force=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            -h|--help)
                cat << EOF
Usage: $0 [OPTIONS]

Create an automated release using GitVersion.

OPTIONS:
    --dry-run    Show what would be done without making changes
    --force      Force creation even if working directory is not clean
    -h, --help   Show this help message

EXAMPLES:
    $0                    # Create release from current version
    $0 --dry-run         # Preview what would happen
    $0 --force           # Force creation with uncommitted changes
EOF
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    log "Starting automated release creation..."
    
    # Pre-flight checks
    check_git_repo
    check_gitversion
    
    # Check for uncommitted changes
    if [[ -n $(git status --porcelain) ]] && [[ "$force" == false ]]; then
        error "Working directory has uncommitted changes. Use --force to override or commit changes first."
        git status --short
        exit 1
    fi
    
    # Get version information
    local version
    version=$(get_version)
    local full_version
    full_version=$(get_full_version)
    
    log "Detected version: $version (full: $full_version)"
    
    if [[ "$dry_run" == true ]]; then
        log "DRY RUN MODE - No changes will be made"
        log "Would create release branch: release/v${version}"
        log "Would create RELEASE_NOTES.md"
        log "Would commit and push changes"
        log "Would create tag: v${version}"
        exit 0
    fi
    
    # Confirm with user
    read -p "Create release v${version}? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Release creation cancelled"
        exit 0
    fi
    
    # Execute release process
    local branch_name
    branch_name=$(create_release_branch "$version")
    
    create_release_notes "$version" "$full_version"
    create_security_manifests "$version"
    commit_and_push "$version" "$branch_name"
    tag_release "$version" "$full_version"
    
    success "Release v${version} created successfully!"
    log "Release branch: $branch_name"
    log "Tag: v${version}"
    log ""
    log "Security files created:"
    log "  - SHA256SUMS (checksums for all files)"
    if [[ -f "SHA256SUMS.sig" ]]; then
        log "  - SHA256SUMS.sig (GPG signature)"
    fi
    log "  - VERIFY.md (verification instructions)"
    log ""
    log "Next steps:"
    log "  1. Review the release notes in RELEASE_NOTES.md"
    log "  2. Verify the security manifests are correct"
    log "  3. Create a pull request to merge $branch_name into main"
    log "  4. After merge, create a GitHub release from tag v${version}"
    log "  5. Upload SHA256SUMS and SHA256SUMS.sig to the GitHub release"
}

# Run main function with all arguments
main "$@"