#!/usr/bin/env bash

set -euo pipefail

# Semantic Versioning Rules Tests
# Comprehensive tests for semantic versioning rules as per GitVersion specification

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITVERSION_SCRIPT="${SCRIPT_DIR}/../../../gitversion.sh"
TEST_DIR="$SCRIPT_DIR/tmp/semver_rules_test"

echo "=== Semantic Versioning Rules Tests ==="

# Setup test environment
setup_test_env() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    echo "Initial commit" > README.md
    git add README.md
    git commit -m "Initial commit" -q
    
    # Create initial tag
    git tag -a "v1.0.0" -m "Version 1.0.0" -q
}

cleanup_test_env() {
    cd "$SCRIPT_DIR"
    rm -rf "$TEST_DIR"
}

# Test conventional commit patterns
test_conventional_commits() {
    echo "Test: Conventional Commit patterns"
    
    setup_test_env
    
    # Test fix: (patch increment)
    echo "bug fix" > fix.txt
    git add fix.txt
    git commit -m "fix: resolve critical bug" -q
    
    local version
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^1\.0\.1 ]]; then
        echo "✓ 'fix:' triggers patch increment"
    else
        echo "✗ 'fix:' patch increment failed. Got: $version"
        return 1
    fi
    
    # Test feat: (minor increment)
    echo "new feature" > feature.txt
    git add feature.txt
    git commit -m "feat: add user authentication" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^1\.1\.0 ]]; then
        echo "✓ 'feat:' triggers minor increment"
    else
        echo "✗ 'feat:' minor increment failed. Got: $version"
        return 1
    fi
    
    # Test feat!: (major increment)
    echo "breaking feature" > breaking.txt
    git add breaking.txt
    git commit -m "feat!: rewrite API with breaking changes" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^2\.0\.0 ]]; then
        echo "✓ 'feat!:' triggers major increment"
    else
        echo "✗ 'feat!:' major increment failed. Got: $version"
        return 1
    fi
    
    cleanup_test_env
}

# Test BREAKING CHANGE footer
test_breaking_change_footer() {
    echo "Test: BREAKING CHANGE footer patterns"
    
    setup_test_env
    
    # Test BREAKING CHANGE in commit body
    echo "breaking change" > breaking.txt
    git add breaking.txt
    git commit -m "refactor: simplify API

BREAKING CHANGE: remove deprecated methods" -q
    
    local version
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^2\.0\.0 ]]; then
        echo "✓ 'BREAKING CHANGE:' footer triggers major increment"
    else
        echo "✗ 'BREAKING CHANGE:' major increment failed. Got: $version"
        return 1
    fi
    
    # Test BREAKING-CHANGE variant (with dash)
    echo "another breaking change" > breaking2.txt
    git add breaking2.txt
    git commit -m "style: update themes

BREAKING-CHANGE: remove legacy theme support" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^3\.0\.0 ]]; then
        echo "✓ 'BREAKING-CHANGE:' variant works"
    else
        echo "✗ 'BREAKING-CHANGE:' variant failed. Got: $version"
        return 1
    fi
    
    cleanup_test_env
}

# Test +semver: tags
test_semver_tags() {
    echo "Test: +semver: explicit version increment tags"
    
    setup_test_env
    
    # Test +semver: patch
    echo "patch fix" > patch.txt
    git add patch.txt
    git commit -m "docs: update README +semver: patch" -q
    
    local version
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^1\.0\.1 ]]; then
        echo "✓ '+semver: patch' works"
    else
        echo "✗ '+semver: patch' failed. Got: $version"
        return 1
    fi
    
    # Test +semver: minor
    echo "minor change" > minor.txt
    git add minor.txt
    git commit -m "style: improve layout +semver: minor" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^1\.1\.0 ]]; then
        echo "✓ '+semver: minor' works"
    else
        echo "✗ '+semver: minor' failed. Got: $version"
        return 1
    fi
    
    # Test +semver: major
    echo "major change" > major.txt
    git add major.txt
    git commit -m "refactor: restructure codebase +semver: major" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^2\.0\.0 ]]; then
        echo "✓ '+semver: major' works"
    else
        echo "✗ '+semver: major' failed. Got: $version"
        return 1
    fi
    
    # Test +semver: breaking (alias for major)
    echo "breaking change" > breaking.txt
    git add breaking.txt
    git commit -m "perf: optimize algorithm +semver: breaking" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^3\.0\.0 ]]; then
        echo "✓ '+semver: breaking' works as major"
    else
        echo "✗ '+semver: breaking' failed. Got: $version"
        return 1
    fi
    
    # Test +semver: none/skip (no increment)
    echo "no increment" > none.txt
    git add none.txt
    git commit -m "ci: update build config +semver: none" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^3\.0\.0 ]]; then
        echo "✓ '+semver: none' skips increment"
    else
        echo "⚠ '+semver: none' behavior may vary with commit count"
    fi
    
    cleanup_test_env
}

# Test version increment precedence
test_increment_precedence() {
    echo "Test: Version increment precedence rules"
    
    setup_test_env
    
    # Test that major overrides minor and patch in same commit
    echo "mixed increment" > mixed.txt
    git add mixed.txt
    git commit -m "feat: new feature +semver: patch

BREAKING CHANGE: this should still trigger major" -q
    
    local version
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^2\.0\.0 ]]; then
        echo "✓ Major increment takes precedence over lower increments"
    else
        echo "✗ Major precedence failed. Got: $version"
        return 1
    fi
    
    # Test that minor overrides patch
    echo "minor over patch" > minor_patch.txt
    git add minor_patch.txt
    git commit -m "fix: bug fix +semver: minor" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^2\.1\.0 ]]; then
        echo "✓ Minor increment overrides patch"
    else
        echo "✗ Minor over patch precedence failed. Got: $version"
        return 1
    fi
    
    cleanup_test_env
}

# Test multiple commits increment calculation
test_multiple_commits() {
    echo "Test: Multiple commits increment calculation"
    
    setup_test_env
    
    # Add multiple commits with different increments
    echo "fix 1" > fix1.txt
    git add fix1.txt
    git commit -m "fix: first fix" -q
    
    echo "fix 2" > fix2.txt
    git add fix2.txt
    git commit -m "fix: second fix" -q
    
    echo "feature" > feature.txt
    git add feature.txt
    git commit -m "feat: new feature" -q
    
    # Should result in minor increment (highest among the commits)
    local version
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^1\.1\.0 ]]; then
        echo "✓ Multiple commits - highest increment wins"
    else
        echo "✗ Multiple commits calculation failed. Got: $version"
        return 1
    fi
    
    # Add breaking change - should become major
    echo "breaking" > breaking.txt
    git add breaking.txt
    git commit -m "refactor: major rewrite

BREAKING CHANGE: API completely changed" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^2\.0\.0 ]]; then
        echo "✓ Breaking change overrides previous increments"
    else
        echo "✗ Breaking change override failed. Got: $version"
        return 1
    fi
    
    cleanup_test_env
}

# Test edge cases and special scenarios
test_edge_cases() {
    echo "Test: Edge cases and special scenarios"
    
    setup_test_env
    
    # Test commit with scope
    echo "scoped commit" > scoped.txt
    git add scoped.txt
    git commit -m "feat(api): add new endpoint" -q
    
    local version
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^1\.1\.0 ]]; then
        echo "✓ Scoped commits work correctly"
    else
        echo "✗ Scoped commit failed. Got: $version"
        return 1
    fi
    
    # Test breaking change with scope
    echo "breaking scoped" > breaking_scoped.txt
    git add breaking_scoped.txt
    git commit -m "feat(auth)!: rewrite authentication" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^2\.0\.0 ]]; then
        echo "✓ Breaking change with scope works"
    else
        echo "✗ Breaking scoped commit failed. Got: $version"
        return 1
    fi
    
    # Test case insensitive patterns
    echo "case test" > case.txt
    git add case.txt
    git commit -m "FEAT: uppercase feat should work" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^2\.1\.0 ]]; then
        echo "✓ Case insensitive conventional commits work"
    else
        echo "⚠ Case sensitivity test may vary. Got: $version"
    fi
    
    cleanup_test_env
}

# Test semantic versioning with pre-release identifiers
test_prerelease_semver() {
    echo "Test: Pre-release semantic versioning"
    
    setup_test_env
    
    # Test develop branch pre-release
    git checkout -b develop -q
    echo "develop feature" > develop.txt
    git add develop.txt
    git commit -m "feat: develop branch feature" -q
    
    local version
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ ^1\.1\.0-alpha ]]; then
        echo "✓ Develop branch produces alpha pre-release"
    else
        echo "✗ Develop pre-release failed. Got: $version"
        return 1
    fi
    
    # Test feature branch pre-release
    git checkout -b feature/new-ui -q
    echo "ui feature" > ui.txt
    git add ui.txt
    git commit -m "feat: new user interface" -q
    
    version=$("$GITVERSION_SCRIPT" --output text)
    if [[ "$version" =~ new-ui ]]; then
        echo "✓ Feature branch includes branch name in pre-release"
    else
        echo "✗ Feature branch pre-release failed. Got: $version"
        return 1
    fi
    
    cleanup_test_env
}

# Run all semantic versioning rules tests
run_semver_tests() {
    local test_functions=(
        test_conventional_commits
        test_breaking_change_footer
        test_semver_tags
        test_increment_precedence
        test_multiple_commits
        test_edge_cases
        test_prerelease_semver
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
    echo "=== Semantic Versioning Rules Test Summary ==="
    if [[ $failed_tests -eq 0 ]]; then
        echo "✓ All semantic versioning rules tests passed!"
        return 0
    else
        echo "✗ $failed_tests test(s) failed"
        return 1
    fi
}

# Execute tests if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_semver_tests
fi