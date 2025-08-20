#!/usr/bin/env bash

set -euo pipefail

# GitVersion Test Runner
# Runs all test suites for gitversion.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITVERSION_SCRIPT="${SCRIPT_DIR}/../gitversion.sh"

echo "=== GitVersion Comprehensive Test Suite ==="
echo "Testing script: $GITVERSION_SCRIPT"
echo

# Check if gitversion.sh exists
if [[ ! -f "$GITVERSION_SCRIPT" ]]; then
    echo "ERROR: gitversion.sh not found at $GITVERSION_SCRIPT"
    exit 1
fi

# Make sure it's executable
chmod +x "$GITVERSION_SCRIPT"

# Track test results
declare -a test_results=()
total_tests=0
passed_tests=0

run_test_suite() {
    local test_name="$1"
    local test_script="$2"
    
    echo "Running $test_name..."
    ((total_tests++))
    
    if [[ -f "$test_script" ]]; then
        chmod +x "$test_script"
        if bash "$test_script"; then
            echo "✓ $test_name passed"
            test_results+=("✓ $test_name")
            ((passed_tests++))
        else
            echo "✗ $test_name failed"
            test_results+=("✗ $test_name")
        fi
    else
        echo "⚠ $test_name not found at $test_script"
        test_results+=("⚠ $test_name not found")
    fi
    echo
}

# Run all test suites
run_test_suite "JSON Configuration Tests" "$SCRIPT_DIR/tmp/json_config_test/test_json_config.sh"
run_test_suite "Semantic Version Parsing Tests" "$SCRIPT_DIR/tmp/semver_parsing_test/test_semver_parsing.sh"
run_test_suite "GitVersion Compatibility Tests" "$SCRIPT_DIR/test_gitversion_compatibility.sh"
run_test_suite "Configuration File Tests" "$SCRIPT_DIR/tmp/config_file_test/test_config_files.sh"
run_test_suite "Semantic Versioning Rules Tests" "$SCRIPT_DIR/tmp/semver_rules_test/test_semver_rules.sh"

# Print summary
echo "=== Test Suite Summary ==="
echo "Total test suites: $total_tests"
echo "Passed: $passed_tests"
echo "Failed/Missing: $((total_tests - passed_tests))"
echo

echo "Detailed Results:"
for result in "${test_results[@]}"; do
    echo "  $result"
done

echo
if [[ $passed_tests -eq $total_tests ]]; then
    echo "🎉 All test suites completed successfully!"
    exit 0
else
    echo "⚠ Some test suites had issues. Check individual test outputs above."
    exit 1
fi