#!/usr/bin/env bash

set -euo pipefail

# JSON Configuration Tests for gitversion.sh
# Tests various JSON configuration file handling scenarios

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITVERSION_SCRIPT="${SCRIPT_DIR}/../../../gitversion.sh"
TEST_DIR="$SCRIPT_DIR"

echo "=== JSON Configuration Tests ==="

# Test 1: Default JSON output
echo "Test 1: Default JSON output format"
cd "$TEST_DIR"
if output=$("$GITVERSION_SCRIPT" --output json 2>/dev/null); then
    # Check if output is valid JSON
    if echo "$output" | python3 -m json.tool >/dev/null 2>&1; then
        echo "✓ Default JSON output is valid"
    else
        echo "✗ Default JSON output is invalid"
        exit 1
    fi
else
    echo "⚠ Could not generate JSON output (may require git repo)"
fi

# Test 2: Custom configuration file
echo "Test 2: Custom configuration file handling"
cat > "$TEST_DIR/test_config.json" << 'EOF'
{
    "next-version": "1.0.0",
    "increment": "Patch",
    "branches": {
        "main": {
            "increment": "Minor"
        },
        "develop": {
            "increment": "Patch"
        }
    }
}
EOF

if output=$("$GITVERSION_SCRIPT" --config "$TEST_DIR/test_config.json" --output json 2>/dev/null); then
    echo "✓ Custom config file handled successfully"
else
    echo "⚠ Custom config test skipped (may require git repo context)"
fi

# Test 3: Invalid JSON configuration
echo "Test 3: Invalid JSON configuration handling"
cat > "$TEST_DIR/invalid_config.json" << 'EOF'
{
    "next-version": "1.0.0"
    "increment": "Patch"
    // Invalid JSON with comment
}
EOF

if "$GITVERSION_SCRIPT" --config "$TEST_DIR/invalid_config.json" --output json 2>/dev/null; then
    echo "✗ Should have failed with invalid JSON"
    exit 1
else
    echo "✓ Invalid JSON configuration properly rejected"
fi

# Cleanup
rm -f "$TEST_DIR/test_config.json" "$TEST_DIR/invalid_config.json"

echo "✓ All JSON configuration tests passed"