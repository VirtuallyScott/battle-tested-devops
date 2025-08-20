#!/usr/bin/env bash

set -euo pipefail

# GitVersion Test Runner
# Runs all test suites for gitversion.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITVERSION_SCRIPT="${SCRIPT_DIR}/../gitversion.sh"

echo "=== GitVersion Test Suite ==="
echo "Testing script: $GITVERSION_SCRIPT"
echo

# Check if gitversion.sh exists
if [[ ! -f "$GITVERSION_SCRIPT" ]]; then
    echo "ERROR: gitversion.sh not found at $GITVERSION_SCRIPT"
    exit 1
fi

# Make sure it's executable
chmod +x "$GITVERSION_SCRIPT"

# Run JSON configuration tests
echo "Running JSON configuration tests..."
if [[ -f "$SCRIPT_DIR/tmp/json_config_test/test_json_config.sh" ]]; then
    bash "$SCRIPT_DIR/tmp/json_config_test/test_json_config.sh"
    echo "✓ JSON configuration tests passed"
else
    echo "⚠ JSON configuration tests not found"
fi

echo

# Run semantic version parsing tests
echo "Running semantic version parsing tests..."
if [[ -f "$SCRIPT_DIR/tmp/semver_parsing_test/test_semver_parsing.sh" ]]; then
    bash "$SCRIPT_DIR/tmp/semver_parsing_test/test_semver_parsing.sh"
    echo "✓ Semantic version parsing tests passed"
else
    echo "⚠ Semantic version parsing tests not found"
fi

echo
echo "=== All tests completed ==="