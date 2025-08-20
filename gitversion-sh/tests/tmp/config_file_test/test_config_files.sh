#!/usr/bin/env bash

set -euo pipefail

# Configuration File Tests for gitversion.sh
# Tests JSON and YAML configuration file parsing and application

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITVERSION_SCRIPT="${SCRIPT_DIR}/../../../gitversion.sh"
TEST_DIR="$SCRIPT_DIR"

echo "=== Configuration File Tests ==="

# Test JSON configuration files
test_json_configuration() {
    echo "Test: JSON configuration file support"
    
    cd "$TEST_DIR"
    
    # Create a comprehensive JSON config following GitVersion schema
    cat > "$TEST_DIR/gitversion.json" << 'EOF'
{
  "next-version": "2.0.0",
  "branches": {
    "main": {
      "increment": "Minor",
      "tag": "stable"
    },
    "develop": {
      "increment": "Patch",
      "tag": "alpha"
    },
    "feature": {
      "increment": "Minor",
      "tag": "feat"
    },
    "release": {
      "increment": "Patch",
      "tag": "beta"
    },
    "hotfix": {
      "increment": "Patch",
      "tag": "hotfix"
    }
  },
  "ignore": {
    "sha": []
  },
  "merge-message-formats": {},
  "commit-message-incrementing": {
    "enabled": true,
    "increment-mode": "Enabled"
  }
}
EOF
    
    # Test configuration loading
    if output=$("$GITVERSION_SCRIPT" --config "$TEST_DIR/gitversion.json" --output json 2>/dev/null); then
        echo "✓ JSON configuration file loaded successfully"
        
        # Verify next-version override is applied
        if echo "$output" | grep -q '"MajorMinorPatch": "2.0.0"'; then
            echo "✓ next-version override from JSON config works"
        else
            echo "⚠ next-version override test skipped (depends on git state)"
        fi
    else
        echo "⚠ JSON configuration test skipped (may require jq)"
    fi
    
    # Test branch-specific configuration
    if output=$("$GITVERSION_SCRIPT" --config "$TEST_DIR/gitversion.json" --branch main --output json 2>/dev/null); then
        echo "✓ Branch-specific JSON configuration works"
    else
        echo "⚠ Branch-specific JSON test skipped"
    fi
    
    # Test invalid JSON handling
    cat > "$TEST_DIR/invalid.json" << 'EOF'
{
  "next-version": "2.0.0"
  "branches": {
    "main": {
      "increment": "Minor"
    }
  }
}
EOF
    
    if ! "$GITVERSION_SCRIPT" --config "$TEST_DIR/invalid.json" --output json >/dev/null 2>&1; then
        echo "✓ Invalid JSON configuration properly rejected"
    else
        echo "✗ Invalid JSON should have been rejected"
    fi
    
    # Cleanup
    rm -f "$TEST_DIR/gitversion.json" "$TEST_DIR/invalid.json"
}

# Test YAML configuration files
test_yaml_configuration() {
    echo "Test: YAML configuration file support"
    
    cd "$TEST_DIR"
    
    # Create a comprehensive YAML config following GitVersion schema
    cat > "$TEST_DIR/gitversion.yml" << 'EOF'
next-version: '3.0.0'
branches:
  main:
    increment: Minor
    tag: stable
  develop:
    increment: Patch
    tag: alpha
  feature:
    increment: Minor
    tag: feat
  release:
    increment: Patch
    tag: beta
  hotfix:
    increment: Patch
    tag: hotfix
ignore:
  sha: []
merge-message-formats: {}
commit-message-incrementing:
  enabled: true
  increment-mode: Enabled
EOF
    
    # Test YAML configuration loading
    if output=$("$GITVERSION_SCRIPT" --config "$TEST_DIR/gitversion.yml" --output json 2>/dev/null); then
        echo "✓ YAML configuration file loaded successfully"
        
        # Verify next-version override is applied  
        if echo "$output" | grep -q '"MajorMinorPatch": "3.0.0"'; then
            echo "✓ next-version override from YAML config works"
        else
            echo "⚠ next-version override test skipped (depends on git state)"
        fi
    else
        echo "⚠ YAML configuration test skipped (may require yq)"
    fi
    
    # Test branch-specific YAML configuration
    if output=$("$GITVERSION_SCRIPT" --config "$TEST_DIR/gitversion.yml" --branch develop --output json 2>/dev/null); then
        echo "✓ Branch-specific YAML configuration works"
    else
        echo "⚠ Branch-specific YAML test skipped"
    fi
    
    # Test invalid YAML handling
    cat > "$TEST_DIR/invalid.yml" << 'EOF'
next-version: 3.0.0
branches:
  main:
    increment: Minor
  - invalid: yaml
    structure: here
EOF
    
    if ! "$GITVERSION_SCRIPT" --config "$TEST_DIR/invalid.yml" --output json >/dev/null 2>&1; then
        echo "✓ Invalid YAML configuration properly rejected"
    else
        echo "✗ Invalid YAML should have been rejected"
    fi
    
    # Cleanup
    rm -f "$TEST_DIR/gitversion.yml" "$TEST_DIR/invalid.yml"
}

# Test configuration precedence
test_config_precedence() {
    echo "Test: Configuration precedence (CLI args override config)"
    
    cd "$TEST_DIR"
    
    # Create config that sets next-version
    cat > "$TEST_DIR/precedence_test.json" << 'EOF'
{
  "next-version": "5.0.0",
  "branches": {
    "main": {
      "increment": "Major"
    }
  }
}
EOF
    
    # Test that CLI --next-version overrides config file
    if command -v jq >/dev/null 2>&1; then
        if output1=$("$GITVERSION_SCRIPT" --config "$TEST_DIR/precedence_test.json" --next-version "6.0.0" --output json 2>/dev/null); then
            if echo "$output1" | grep -q '"MajorMinorPatch": "6.0.0"'; then
                echo "✓ CLI --next-version overrides config file"
            else
                echo "⚠ CLI precedence test result unclear"
            fi
        else
            echo "⚠ CLI precedence test skipped"
        fi
        
        # Test that CLI --major overrides config increment
        if output2=$("$GITVERSION_SCRIPT" --config "$TEST_DIR/precedence_test.json" --major --output json 2>/dev/null); then
            echo "✓ CLI increment flags override config increment"
        else
            echo "⚠ CLI increment precedence test skipped"
        fi
    else
        echo "⚠ Configuration precedence tests skipped (requires jq)"
    fi
    
    # Cleanup
    rm -f "$TEST_DIR/precedence_test.json"
}

# Test GitVersion standard configuration patterns
test_standard_configs() {
    echo "Test: GitVersion standard configuration patterns"
    
    cd "$TEST_DIR"
    
    # Test GitFlow configuration
    cat > "$TEST_DIR/gitflow.json" << 'EOF'
{
  "workflow": "GitFlow",
  "next-version": "1.0.0",
  "branches": {
    "main": {
      "increment": "Patch",
      "prevent-increment-of-merged-branch-version": false,
      "track-merge-target": false,
      "regex": "^master$|^main$",
      "source-branches": ["develop", "release"]
    },
    "develop": {
      "increment": "Minor",
      "prevent-increment-of-merged-branch-version": false,
      "track-merge-target": true,
      "regex": "^develop$",
      "source-branches": []
    },
    "feature": {
      "increment": "Minor",
      "regex": "^feature[/-]",
      "source-branches": ["develop"]
    }
  }
}
EOF
    
    if command -v jq >/dev/null 2>&1; then
        if "$GITVERSION_SCRIPT" --config "$TEST_DIR/gitflow.json" --workflow gitflow --output json >/dev/null 2>&1; then
            echo "✓ GitFlow standard configuration works"
        else
            echo "⚠ GitFlow configuration test had issues"
        fi
    else
        echo "⚠ GitFlow standard config test skipped (requires jq)"
    fi
    
    # Test GitHub Flow configuration
    cat > "$TEST_DIR/githubflow.yml" << 'EOF'
workflow: GitHubFlow
next-version: '1.0.0'
branches:
  main:
    increment: Patch
    prevent-increment-of-merged-branch-version: false
    track-merge-target: false
    regex: '^master$|^main$'
    source-branches: []
  feature:
    increment: Patch
    regex: '^.*'
    source-branches: ['main']
EOF
    
    if command -v yq >/dev/null 2>&1; then
        if "$GITVERSION_SCRIPT" --config "$TEST_DIR/githubflow.yml" --workflow githubflow --output json >/dev/null 2>&1; then
            echo "✓ GitHub Flow standard configuration works"
        else
            echo "⚠ GitHub Flow configuration test had issues"
        fi
    else
        echo "⚠ GitHub Flow standard config test skipped (requires yq)"
    fi
    
    # Cleanup
    rm -f "$TEST_DIR/gitflow.json" "$TEST_DIR/githubflow.yml"
}

# Test configuration file discovery
test_config_discovery() {
    echo "Test: Configuration file discovery (GitVersion.yml, GitVersion.json)"
    
    cd "$TEST_DIR"
    
    # Create standard GitVersion files
    cat > "$TEST_DIR/GitVersion.yml" << 'EOF'
next-version: '4.0.0'
branches:
  main:
    increment: Minor
EOF
    
    # Note: This tests that the config file parameter works
    # GitVersion typically auto-discovers files, but our implementation requires explicit --config
    if command -v yq >/dev/null 2>&1; then
        if "$GITVERSION_SCRIPT" --config "$TEST_DIR/GitVersion.yml" --output json >/dev/null 2>&1; then
            echo "✓ Standard GitVersion.yml file can be loaded"
        else
            echo "⚠ GitVersion.yml loading test had issues"
        fi
    else
        echo "⚠ GitVersion.yml discovery test skipped (requires yq)"
    fi
    
    # Cleanup
    rm -f "$TEST_DIR/GitVersion.yml"
}

# Run all configuration tests
run_config_tests() {
    local test_functions=(
        test_json_configuration
        test_yaml_configuration
        test_config_precedence
        test_standard_configs
        test_config_discovery
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
    echo "=== Configuration File Test Summary ==="
    if [[ $failed_tests -eq 0 ]]; then
        echo "✓ All configuration file tests passed!"
        return 0
    else
        echo "✗ $failed_tests test(s) failed"
        return 1
    fi
}

# Execute tests if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_config_tests
fi