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
    
    echo "$branch_name"
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
    
    log "Adding RELEASE_NOTES.md to git"
    git add RELEASE_NOTES.md
    
    log "Committing release notes"
    git commit -m "docs: add release notes for v${version} [skip ci]"
    
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
    commit_and_push "$version" "$branch_name"
    tag_release "$version" "$full_version"
    
    success "Release v${version} created successfully!"
    log "Release branch: $branch_name"
    log "Tag: v${version}"
    log "Next steps:"
    log "  1. Review the release notes in RELEASE_NOTES.md"
    log "  2. Create a pull request to merge $branch_name into main"
    log "  3. After merge, create a GitHub release from tag v${version}"
}

# Run main function with all arguments
main "$@"