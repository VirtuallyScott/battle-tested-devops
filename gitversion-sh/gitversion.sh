#!/usr/bin/env bash

set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="gitversion"

show_help() {
    cat << EOF
$SCRIPT_NAME v$VERSION - GitVersion shell implementation

USAGE:
    $SCRIPT_NAME [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --version           Show version information
    -o, --output FORMAT     Output format (json|text|AssemblySemVer|AssemblySemFileVer) [default: text]
    -c, --config FILE       Path to configuration file
    -b, --branch BRANCH     Target branch [default: current branch]
    -w, --workflow TYPE     Workflow type (gitflow|githubflow|trunk) [default: gitflow]
    --major                 Force major version increment
    --minor                 Force minor version increment
    --patch                 Force patch version increment
    --next-version VERSION  Override next version

EXAMPLES:
    $SCRIPT_NAME                    # Calculate version for current branch
    $SCRIPT_NAME -o json            # Output as JSON
    $SCRIPT_NAME -o AssemblySemVer  # Output AssemblySemVer only
    $SCRIPT_NAME -o AssemblySemFileVer # Output AssemblySemFileVer only
    $SCRIPT_NAME -b main            # Calculate version for main branch
    $SCRIPT_NAME --major            # Force major increment

EOF
}

show_version() {
    echo "$SCRIPT_NAME v$VERSION"
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_info() {
    echo "[INFO] $*" >&2
}

check_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "Not a git repository"
        exit 1
    fi
}

get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD"
}

get_latest_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo ""
}

get_commit_count_since_tag() {
    local tag="$1"
    if [[ -n "$tag" ]]; then
        git rev-list --count "${tag}..HEAD" 2>/dev/null || echo "0"
    else
        git rev-list --count HEAD 2>/dev/null || echo "0"
    fi
}

parse_semver() {
    local version="$1"
    local pattern='^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-([a-zA-Z0-9.-]+))?(\+([a-zA-Z0-9.+-]+))?$'
    
    if [[ $version =~ $pattern ]]; then
        MAJOR="${BASH_REMATCH[1]}"
        MINOR="${BASH_REMATCH[2]}"
        PATCH="${BASH_REMATCH[3]}"
        PRERELEASE="${BASH_REMATCH[5]:-}"
        BUILD="${BASH_REMATCH[7]:-}"
        return 0
    else
        return 1
    fi
}

get_branch_type() {
    local branch="$1"
    local workflow="$2"
    
    case "$workflow" in
        "gitflow")
            case "$branch" in
                main|master) echo "main" ;;
                develop) echo "develop" ;;
                feature/*) echo "feature" ;;
                release/*) echo "release" ;;
                hotfix/*) echo "hotfix" ;;
                support/*) echo "support" ;;
                *) echo "unknown" ;;
            esac
            ;;
        "githubflow")
            case "$branch" in
                main|master) echo "main" ;;
                *) echo "feature" ;;
            esac
            ;;
        "trunk")
            echo "main"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

detect_version_increment() {
    local tag="$1"
    local commits
    
    if [[ -n "$tag" ]]; then
        commits=$(git log --oneline "${tag}..HEAD" 2>/dev/null || echo "")
    else
        commits=$(git log --oneline HEAD 2>/dev/null || echo "")
    fi
    
    local increment="patch"
    
    while IFS= read -r commit; do
        if [[ -z "$commit" ]]; then
            continue
        fi
        
        if echo "$commit" | grep -qiE '\+semver:\s*(breaking|major)'; then
            increment="major"
            break
        elif echo "$commit" | grep -qiE '\+semver:\s*(feature|minor)'; then
            if [[ "$increment" != "major" ]]; then
                increment="minor"
            fi
        elif echo "$commit" | grep -qiE 'BREAKING\s*CHANGE'; then
            increment="major"
            break
        elif echo "$commit" | grep -qiE '^feat(\(.+\))?!:'; then
            increment="major"
            break
        elif echo "$commit" | grep -qiE '^feat(\(.+\))?:'; then
            if [[ "$increment" != "major" ]]; then
                increment="minor"
            fi
        fi
    done <<< "$commits"
    
    echo "$increment"
}

calculate_version() {
    local branch="$1"
    local workflow="$2"
    local force_increment="$3"
    local next_version="$4"
    
    local latest_tag
    latest_tag=$(get_latest_tag)
    
    local major=0 minor=0 patch=0 prerelease="" build=""
    
    if [[ -n "$latest_tag" ]]; then
        if parse_semver "$latest_tag"; then
            log_debug "Parsed latest tag: $major.$minor.$patch"
        else
            log_debug "Could not parse tag '$latest_tag', starting from 0.0.0"
            major=0 minor=0 patch=0
        fi
    else
        log_debug "No tags found, starting from 0.0.0"
    fi
    
    if [[ -n "$next_version" ]]; then
        if parse_semver "$next_version"; then
            log_debug "Using override version: $major.$minor.$patch"
        else
            log_error "Invalid next-version format: $next_version"
            exit 1
        fi
    fi
    
    local branch_type
    branch_type=$(get_branch_type "$branch" "$workflow")
    
    local increment
    if [[ -n "$force_increment" ]]; then
        increment="$force_increment"
    else
        increment=$(detect_version_increment "$latest_tag")
    fi
    
    log_debug "Branch: $branch (type: $branch_type)"
    log_debug "Detected increment: $increment"
    
    case "$increment" in
        "major")
            ((major++))
            minor=0
            patch=0
            ;;
        "minor")
            ((minor++))
            patch=0
            ;;
        "patch")
            ((patch++))
            ;;
    esac
    
    local commit_count
    commit_count=$(get_commit_count_since_tag "$latest_tag")
    
    local version="$major.$minor.$patch"
    local full_version="$version"
    
    case "$branch_type" in
        "main")
            ;;
        "develop")
            if [[ "$commit_count" -gt 0 ]]; then
                prerelease="alpha.$commit_count"
                full_version="$version-$prerelease"
            fi
            ;;
        "feature")
            if [[ "$commit_count" -gt 0 ]]; then
                local feature_name
                feature_name=$(echo "$branch" | sed 's|.*/||' | sed 's/[^a-zA-Z0-9]/-/g')
                prerelease="$feature_name.$commit_count"
                full_version="$version-$prerelease"
            fi
            ;;
        "release")
            if [[ "$commit_count" -gt 0 ]]; then
                prerelease="beta.$commit_count"
                full_version="$version-$prerelease"
            fi
            ;;
        "hotfix")
            if [[ "$commit_count" -gt 0 ]]; then
                prerelease="hotfix.$commit_count"
                full_version="$version-$prerelease"
            fi
            ;;
        *)
            if [[ "$commit_count" -gt 0 ]]; then
                local safe_branch
                safe_branch=$(echo "$branch" | sed 's/[^a-zA-Z0-9]/-/g')
                prerelease="$safe_branch.$commit_count"
                full_version="$version-$prerelease"
            fi
            ;;
    esac
    
    local sha
    sha=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    build="$commit_count+$sha"
    
    echo "$full_version+$build"
}

output_text() {
    local version="$1"
    echo "$version"
}

output_assembly_semver() {
    local version="$1"
    if parse_semver "$version"; then
        echo "$MAJOR.$MINOR.$PATCH.0"
    else
        log_error "Failed to parse version: $version"
        exit 1
    fi
}

output_assembly_semfilever() {
    local version="$1"
    if parse_semver "$version"; then
        echo "$MAJOR.$MINOR.$PATCH.0"
    else
        log_error "Failed to parse version: $version"
        exit 1
    fi
}

output_json() {
    local version="$1"
    local branch="$2"
    local workflow="$3"
    
    local major minor patch prerelease build
    if parse_semver "$version"; then
        cat << EOF
{
  "Major": $MAJOR,
  "Minor": $MINOR,
  "Patch": $PATCH,
  "PreReleaseTag": "$PRERELEASE",
  "PreReleaseTagWithDash": "$(if [[ -n "$PRERELEASE" ]]; then echo "-$PRERELEASE"; fi)",
  "BuildMetaData": "$BUILD",
  "BuildMetaDataPadded": "$(if [[ -n "$BUILD" ]]; then echo "+$BUILD"; fi)",
  "FullBuildMetaData": "$BUILD",
  "MajorMinorPatch": "$MAJOR.$MINOR.$PATCH",
  "SemVer": "$version",
  "AssemblySemVer": "$MAJOR.$MINOR.$PATCH.0",
  "AssemblySemFileVer": "$MAJOR.$MINOR.$PATCH.0",
  "FullSemVer": "$version",
  "InformationalVersion": "$version",
  "BranchName": "$branch",
  "EscapedBranchName": "$(echo "$branch" | sed 's/[^a-zA-Z0-9]/-/g')",
  "Sha": "$(git rev-parse HEAD 2>/dev/null || echo "unknown")",
  "ShortSha": "$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")",
  "NuGetVersionV2": "$version",
  "NuGetVersion": "$version",
  "VersionSourceSha": "$(git rev-parse HEAD 2>/dev/null || echo "unknown")",
  "CommitsSinceVersionSource": $(get_commit_count_since_tag "$(get_latest_tag)"),
  "CommitDate": "$(git log -1 --format=%ci HEAD 2>/dev/null || echo "unknown")"
}
EOF
    else
        log_error "Failed to parse version: $version"
        exit 1
    fi
}

main() {
    local output_format="text"
    local config_file=""
    local target_branch=""
    local workflow="gitflow"
    local force_increment=""
    local next_version=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -o|--output)
                output_format="$2"
                shift 2
                ;;
            -c|--config)
                config_file="$2"
                shift 2
                ;;
            -b|--branch)
                target_branch="$2"
                shift 2
                ;;
            -w|--workflow)
                workflow="$2"
                shift 2
                ;;
            --major)
                force_increment="major"
                shift
                ;;
            --minor)
                force_increment="minor"
                shift
                ;;
            --patch)
                force_increment="patch"
                shift
                ;;
            --next-version)
                next_version="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    check_git_repo
    
    if [[ -z "$target_branch" ]]; then
        target_branch=$(get_current_branch)
    fi
    
    if [[ -n "$config_file" && -f "$config_file" ]]; then
        log_debug "Loading configuration from: $config_file"
    fi
    
    local version
    version=$(calculate_version "$target_branch" "$workflow" "$force_increment" "$next_version")
    
    case "$output_format" in
        "text")
            output_text "$version"
            ;;
        "json")
            output_json "$version" "$target_branch" "$workflow"
            ;;
        "AssemblySemVer")
            output_assembly_semver "$version"
            ;;
        "AssemblySemFileVer")
            output_assembly_semfilever "$version"
            ;;
        *)
            log_error "Unknown output format: $output_format"
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi