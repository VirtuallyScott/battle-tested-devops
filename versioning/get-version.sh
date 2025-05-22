#!/bin/bash

# get-version.sh - Returns a semantic version from GitVersion or fallback to git tags

if command -v gitversion >/dev/null 2>&1; then
  gitversion | jq -r '.SemVer'
elif git describe --tags >/dev/null 2>&1; then
  git describe --tags
else
  echo "0.0.0-unknown"
fi
