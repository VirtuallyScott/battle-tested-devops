#!/bin/bash

ZAP_IMAGE="ghcr.io/zaproxy/zaproxy:stable"

function usage() {
  echo "Usage: $0 -u <URL> -f <json|html>"
  echo
  echo "Options:"
  echo "  -u    Full URL to scan (e.g. https://example.com)"
  echo "  -f    Output format: json or html"
  echo "  -h    Show this help message"
  exit 1
}

function check_docker_image() {
  if ! docker image inspect "$ZAP_IMAGE" &>/dev/null; then
    echo "Docker image $ZAP_IMAGE not found. Pulling..."
    docker pull "$ZAP_IMAGE" || { echo "Failed to pull Docker image."; exit 1; }
  fi
}

function sanitize_url() {
  local input="$1"
  echo "$input" | sed -E 's|https?://||; s|/|_|g'
}

function run_zap_scan() {
  local target="$1"
  local format="$2"
  local timestamp
  local filename
  local sanitized_url

  timestamp=$(date +"%m%d%Y_%H%M%S")
  sanitized_url=$(sanitize_url "$target")
  filename="${timestamp}_${sanitized_url}.${format}"

  echo "Running ZAP full scan on: $target"
  echo "Saving report as: $filename"

  local output_flag
  if [[ "$format" == "json" ]]; then
    output_flag="-J"
  else
    output_flag="-r"
  fi

  docker run --rm -v "$(pwd):/zap/wrk/:rw" -t "$ZAP_IMAGE" zap-full-scan.py \
    -t "$target" \
    "$output_flag" "$filename" \
    -j -I -m 10 -T 60
}

# Parse arguments
while getopts "u:f:h" opt; do
  case $opt in
    u) TARGET_URL="$OPTARG" ;;
    f) OUTPUT_FORMAT="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Prompt if not passed
if [[ -z "$TARGET_URL" ]]; then
  read -rp "Enter the full URL to scan: " TARGET_URL
fi

if [[ -z "$OUTPUT_FORMAT" ]]; then
  read -rp "Enter output format (json or html): " OUTPUT_FORMAT
fi

# Validate URL
if [[ ! "$TARGET_URL" =~ ^https?:// ]]; then
  echo "Error: URL must start with http:// or https://"
  exit 1
fi

# Validate format
if [[ "$OUTPUT_FORMAT" != "json" && "$OUTPUT_FORMAT" != "html" ]]; then
  echo "Error: Output format must be either 'json' or 'html'"
  exit 1
fi

# Execute
check_docker_image
run_zap_scan "$TARGET_URL" "$OUTPUT_FORMAT"
