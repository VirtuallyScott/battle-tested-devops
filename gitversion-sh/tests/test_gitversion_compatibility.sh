#!/usr/bin/env bash

set -euo pipefail

# GitVersion Compatibility Tests
# Tests to ensure the bash implementation behaves like GitTools/GitVersion

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITVERSION_SCRIPT="${SCRIPT_DIR}/../gitversion.sh"
TEST_DIR="$SCRIPT_DIR/tmp/gitversion_compatibility_test"

echo "=== GitVersion Compatibility Tests ==="

# Setup test environment
setup_test_env() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    # Initialize git repo for testing
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    echo "Initial commit" > README.md
    git add README.md
    git commit -m "Initial commit" -q
}

# Cleanup test environment
cleanup_test_env() {
    cd "$SCRIPT_DIR"
    rm -rf "$TEST_DIR"
}

# Test semantic versioning commit message patterns
test_semver_commit_patterns() {
    echo "Test: Semantic versioning commit message patterns"
    
    setup_test_env
    
    # Test patch increment (default)
    echo "fix: bug fix" > fix.txt
    git add fix.txt
    git commit -m "fix: resolve issue" -q
    
    local version
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^0\.0\.1 ]]; then
        echo "✓ Patch increment works"
    else
        echo "✗ Patch increment failed. Got: $version"
        return 1
    fi
    
    # Test minor increment with feat:
    echo "feature code" > feature.txt
    git add feature.txt
    git commit -m "feat: add new feature" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^0\.1\.0 ]]; then
        echo "✓ Minor increment with 'feat:' works"
    else
        echo "✗ Minor increment failed. Got: $version"
        return 1
    fi
    
    # Test major increment with BREAKING CHANGE
    echo "breaking change" > breaking.txt
    git add breaking.txt
    git commit -m "feat: add feature

BREAKING CHANGE: This breaks compatibility" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^1\.0\.0 ]]; then
        echo "✓ Major increment with 'BREAKING CHANGE' works"
    else
        echo "✗ Major increment failed. Got: $version"
        return 1
    fi
    
    # Test +semver: tags
    echo "semver test" > semver.txt
    git add semver.txt
    git commit -m "fix: another fix +semver: minor" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^1\.1\.0 ]]; then
        echo "✓ +semver: minor tag works"
    else
        echo "✗ +semver: minor tag failed. Got: $version"
        return 1
    fi
    
    cleanup_test_env
}

# Test branch strategies
test_branch_strategies() {
    echo "Test: Branch strategies (GitFlow, GitHub Flow)"
    
    setup_test_env
    
    # Test main branch
    local version
    version=$("$GITVERSION_SCRIPT" --branch main --output text)
    if [[ "$version" =~ ^0\.0\.1 ]]; then
        echo "✓ Main branch versioning works"
    else
        echo "✗ Main branch versioning failed. Got: $version"
        return 1
    fi
    
    # Test develop branch (should have alpha pre-release)
    version=$("$GITVERSION_SCRIPT" --branch develop --output text)
    if [[ "$version" =~ alpha ]]; then
        echo "✓ Develop branch has alpha pre-release"
    else
        echo "✗ Develop branch pre-release failed. Got: $version"
        return 1
    fi
    
    # Test feature branch
    version=$("$GITVERSION_SCRIPT" --branch feature/test-feature --output text)
    if [[ "$version" =~ test-feature ]]; then
        echo "✓ Feature branch includes feature name"
    else
        echo "✗ Feature branch naming failed. Got: $version"
        return 1
    fi
    
    # Test GitHub Flow workflow
    version=$("$GITVERSION_SCRIPT" --workflow githubflow --branch feature/test --output text)
    if [[ "$version" =~ test ]]; then
        echo "✓ GitHub Flow workflow works"
    else
        echo "✗ GitHub Flow workflow failed. Got: $version"
        return 1
    fi
    
    cleanup_test_env
}

# Test output formats compatibility
test_output_formats() {
    echo "Test: Output formats compatibility with GitVersion"
    
    setup_test_env
    
    # Test JSON output structure
    local json_output
    json_output=$("$GITVERSION_SCRIPT" --output json)
    
    # Check required GitVersion JSON fields
    local required_fields=(
        "Major" "Minor" "Patch" "SemVer" "AssemblySemVer" 
        "AssemblySemFileVer" "FullSemVer" "InformationalVersion"
        "BranchName" "Sha" "ShortSha" "CommitsSinceVersionSource"
    )
    
    for field in "${required_fields[@]}"; do
        if echo "$json_output" | grep -q "\"$field\""; then
            echo "✓ JSON contains required field: $field"
        else
            echo "✗ JSON missing required field: $field"
            return 1
        fi
    done
    
    # Test AssemblySemVer format (should be X.Y.Z.0)
    local assembly_ver
    assembly_ver=$("$GITVERSION_SCRIPT" --output AssemblySemVer)
    if [[ "$assembly_ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.0$ ]]; then
        echo "✓ AssemblySemVer format is correct"
    else
        echo "✗ AssemblySemVer format incorrect. Got: $assembly_ver"
        return 1
    fi
    
    # Test AssemblySemFileVer format (should be X.Y.Z.0)
    local assembly_file_ver
    assembly_file_ver=$("$GITVERSION_SCRIPT" --output AssemblySemFileVer)
    if [[ "$assembly_file_ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.0$ ]]; then
        echo "✓ AssemblySemFileVer format is correct"
    else
        echo "✗ AssemblySemFileVer format incorrect. Got: $assembly_file_ver"
        return 1
    fi
    
    cleanup_test_env
}

# Test force increment options
test_force_increments() {
    echo "Test: Force increment options"
    
    setup_test_env
    
    # Create a tag first
    git tag -a "v1.0.0" -m "Version 1.0.0"
    
    # Test --major
    local version
    version=$("$GITVERSION_SCRIPT" --major --output text)
    if [[ "$version" =~ ^2\.0\.0 ]]; then
        echo "✓ --major force increment works"
    else
        echo "✗ --major force increment failed. Got: $version"
        return 1
    fi
    
    # Test --minor
    version=$("$GITVERSION_SCRIPT" --minor --output text)
    if [[ "$version" =~ ^1\.1\.0 ]]; then
        echo "✓ --minor force increment works"
    else
        echo "✗ --minor force increment failed. Got: $version"
        return 1
    fi
    
    # Test --patch
    version=$("$GITVERSION_SCRIPT" --patch --output text)
    if [[ "$version" =~ ^1\.0\.1 ]]; then
        echo "✓ --patch force increment works"
    else
        echo "✗ --patch force increment failed. Got: $version"
        return 1
    fi
    
    cleanup_test_env
}

# Test version calculation with tags
test_version_with_tags() {
    echo "Test: Version calculation with existing tags"
    
    setup_test_env
    
    # Test starting from no tags
    local version
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^0\.0\.1 ]]; then
        echo "✓ Version calculation without tags works"
    else
        echo "✗ Version calculation without tags failed. Got: $version"
        return 1
    fi
    
    # Add a semantic version tag
    git tag -a "v1.2.3" -m "Version 1.2.3"
    
    # Add commits after tag
    echo "post-tag commit" > post.txt
    git add post.txt
    git commit -m "fix: post-tag fix" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^1\.2\.4 ]]; then
        echo "✓ Version increments from existing tag"
    else
        echo "✗ Version increment from tag failed. Got: $version"
        return 1
    fi
    
    cleanup_test_env
}

# Test pre-release versioning
test_prerelease_versioning() {
    echo "Test: Pre-release versioning on development branches"
    
    setup_test_env
    
    # Create develop branch
    git checkout -b develop -q
    echo "develop change" > develop.txt
    git add develop.txt
    git commit -m "feat: develop feature" -q
    
    local version
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ alpha ]]; then
        echo "✓ Develop branch produces alpha pre-release"
    else
        echo "✗ Develop branch pre-release failed. Got: $version"
        return 1
    fi
    
    # Test release branch
    git checkout -b release/v1.0.0 -q
    echo "release change" > release.txt
    git add release.txt
    git commit -m "chore: prepare release" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ beta ]]; then
        echo "✓ Release branch produces beta pre-release"
    else
        echo "✗ Release branch pre-release failed. Got: $version"
        return 1
    fi
    
    cleanup_test_env
}

# Run all compatibility tests
run_all_tests() {
    local test_functions=(
        test_semver_commit_patterns
        test_branch_strategies
        test_output_formats
        test_force_increments
        test_version_with_tags
        test_prerelease_versioning
    )
    
    local failed_tests=0
    
    for test_func in "${test_functions[@]}"; do
        echo
        if ! "$test_func"; then
            ((failed_tests++))
            echo "✗ $test_func FAILED"
        else
            echo "✓ $test_func PASSED"
        fi
    done
    
    echo
    echo "=== GitVersion Compatibility Test Summary ==="
    if [[ $failed_tests -eq 0 ]]; then
        echo "✓ All compatibility tests passed!"
        return 0
    else
        echo "✗ $failed_tests test(s) failed"
        return 1
    fi
}

# Execute tests if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
fi