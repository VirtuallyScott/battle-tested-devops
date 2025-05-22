#!/bin/bash
# bump-version.sh - Safely increment version numbers without triggering CI/CD

set -euo pipefail

# Check if we're in a CI environment to prevent accidental bumps
if [ -n "${CI:-}" ]; then
  echo "Error: Running in CI environment - version bumps should happen locally first"
  exit 1
fi

# Get current version
CURRENT_VERSION=$(./get-version.sh)

# Determine bump type from argument
BUMP_TYPE=${1:-patch}
VALID_BUMP_TYPES="major minor patch"

if [[ ! " $VALID_BUMP_TYPES " =~ " $BUMP_TYPE " ]]; then
  echo "Error: Invalid bump type '$BUMP_TYPE'. Must be one of: $VALID_BUMP_TYPES"
  exit 1
fi

# Create bump commit message that won't trigger another CI build
BUMP_MSG="chore: bump version $BUMP_TYPE [skip ci]"

# Perform the bump using GitVersion's commit message approach
git commit --allow-empty -m "$BUMP_MSG" -m "+semver: $BUMP_TYPE"

# Get new version
NEW_VERSION=$(./get-version.sh)

echo "Version bumped from $CURRENT_VERSION to $NEW_VERSION"
