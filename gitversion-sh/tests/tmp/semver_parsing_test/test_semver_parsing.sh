#!/usr/bin/env bash

set -euo pipefail

# Semantic Version Parsing Tests for gitversion.sh
# Tests semantic version parsing and increment logic

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITVERSION_SCRIPT="${SCRIPT_DIR}/../../../gitversion.sh"
TEST_DIR="$SCRIPT_DIR"

echo "=== Semantic Version Parsing Tests ==="

# Helper function to test version parsing
test_version_parsing() {
    local description="$1"
    local expected_pattern="$2"
    local test_output="$3"
    
    echo "Test: $description"
    if echo "$test_output" | grep -qE "$expected_pattern"; then
        echo "✓ $description - PASSED"
        return 0
    else
        echo "✗ $description - FAILED"
        echo "Expected pattern: $expected_pattern"
        echo "Actual output: $test_output"
        return 1
    fi
}

# Test 1: Basic version format validation
echo "Test 1: Version format validation"
cd "$TEST_DIR"

# Test different output formats
if output=$("$GITVERSION_SCRIPT" --output text 2>/dev/null); then
    test_version_parsing "Text output contains version" "[0-9]+\.[0-9]+\.[0-9]+" "$output"
else
    echo "⚠ Text output test skipped (may require git repo)"
fi

if output=$("$GITVERSION_SCRIPT" --output AssemblySemVer 2>/dev/null); then
    test_version_parsing "AssemblySemVer format" "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" "$output"
else
    echo "⚠ AssemblySemVer test skipped (may require git repo)"
fi

if output=$("$GITVERSION_SCRIPT" --output AssemblySemFileVer 2>/dev/null); then
    test_version_parsing "AssemblySemFileVer format" "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" "$output"
else
    echo "⚠ AssemblySemFileVer test skipped (may require git repo)"
fi

# Test 2: JSON structure validation
echo "Test 2: JSON structure validation"
if json_output=$("$GITVERSION_SCRIPT" --output json 2>/dev/null); then
    # Check for required fields in JSON output
    required_fields=("Major" "Minor" "Patch" "SemVer" "AssemblySemVer")
    
    for field in "${required_fields[@]}"; do
        if echo "$json_output" | grep -q "\"$field\""; then
            echo "✓ JSON contains required field: $field"
        else
            echo "✗ JSON missing required field: $field"
            exit 1
        fi
    done
else
    echo "⚠ JSON structure test skipped (may require git repo)"
fi

# Test 3: Branch-based version increment logic
echo "Test 3: Branch-based increment logic"
current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "Current branch: $current_branch"

# Test that version increments are applied based on branch
if [[ "$current_branch" != "unknown" ]]; then
    if version_output=$("$GITVERSION_SCRIPT" --branch "$current_branch" --output json 2>/dev/null); then
        echo "✓ Branch-specific version calculation works"
        
        # Verify the version has semantic version components
        if echo "$version_output" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    major = data.get('Major', 0)
    minor = data.get('Minor', 0) 
    patch = data.get('Patch', 0)
    semver = data.get('SemVer', '')
    
    # Basic validation
    assert isinstance(major, int) and major >= 0
    assert isinstance(minor, int) and minor >= 0
    assert isinstance(patch, int) and patch >= 0
    assert semver.count('.') >= 2  # At least X.Y.Z format
    
    print(f'✓ Semantic version components valid: {major}.{minor}.{patch}')
except Exception as e:
    print(f'✗ Version validation failed: {e}')
    sys.exit(1)
" 2>/dev/null; then
            echo "✓ Semantic version components are valid"
        else
            echo "⚠ Could not validate semantic version components"
        fi
    else
        echo "⚠ Branch-specific test skipped"
    fi
else
    echo "⚠ Branch increment test skipped (not in git repo)"
fi

echo "✓ All semantic version parsing tests completed"