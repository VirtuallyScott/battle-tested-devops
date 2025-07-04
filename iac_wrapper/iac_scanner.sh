#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------
# IaC Scanner Script: Trivy + Checkov (JSON/SARIF/HTML)
# ---------------------------------------------

echo "[DEBUG] Current directory: $(pwd)"

print_help() {
  echo "Usage: $0 -t [trivy|checkov|both] -o [json|sarif|html|csv]"
  echo ""
  echo "Arguments:"
  echo "  -t    Tool to use (trivy, checkov, both)"
  echo "  -o    Output format (json, sarif, html, csv)"
  echo "  --help  Show this help message"
  exit 1
}

check_dependencies() {
  local missing=0
  for tool in trivy checkov snyk-to-html; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      echo "[!] Error: $tool not found in PATH"
      missing=1
    else
      echo "[DEBUG] Found $tool: $(command -v "$tool")"
    fi
  done
  
  if [ $missing -ne 0 ]; then
    echo "[!] One or more required tools are missing. Please install them."
    return 1
  fi
  
  # If all tools are available, execute the scans
  echo "[DEBUG] All dependencies found, proceeding with scans"
  execute_scans
  return $?
}

execute_scans() {
  local any_errors=0
  
  echo "[DEBUG] About to check tool conditions: tool='$TOOL'"
  
  if [[ "$TOOL" == "trivy" || "$TOOL" == "both" ]]; then
    echo "[DEBUG] Condition matched for Trivy - about to call run_trivy"
    echo "[DEBUG] Parameters: actual_format='$ACTUAL_FORMAT', scan_dir='$SCAN_DIR', output='$OUTPUT'"
    if ! run_trivy "$ACTUAL_FORMAT" "$SCAN_DIR" "$OUTPUT"; then
      echo "[!] Trivy scan encountered errors"
      any_errors=1
    fi
    echo "[DEBUG] Trivy scan function returned"
  else
    echo "[DEBUG] Skipping Trivy scan (tool='$TOOL')"
  fi

  if [[ "$TOOL" == "checkov" || "$TOOL" == "both" ]]; then
    echo "[DEBUG] Condition matched for Checkov - about to call run_checkov"
    echo "[DEBUG] Parameters: actual_format='$ACTUAL_FORMAT', scan_dir='$SCAN_DIR', output='$OUTPUT'"
    if ! run_checkov "$ACTUAL_FORMAT" "$SCAN_DIR" "$OUTPUT"; then
      echo "[!] Checkov scan encountered errors"
      any_errors=1
    fi
    echo "[DEBUG] Checkov scan function returned"
  else
    echo "[DEBUG] Skipping Checkov scan (tool='$TOOL')"
  fi
  
  echo "[DEBUG] Finished all scan attempts"
  return $any_errors
}

convert_sarif_to_html() {
  local tool_name=$1
  local scan_dir=$2
  local sarif_file=$3
  local html_file=$4

  echo "[DEBUG] Converting $sarif_file to $html_file"
  if ! snyk-to-html -i "$sarif_file" -o "$html_file"; then
    echo "[!] HTML conversion failed for $tool_name"
    return 1
  fi

  echo "[DEBUG] Running sed commands to update HTML titles"
  # Update title and mentions in HTML file (platform-agnostic sed)
  local tool_display_name="${tool_name^} Scan"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|>Snyk Report<|>${tool_name^} Report for ${scan_dir}<|" "$html_file"
    sed -i '' "s|Snyk Report|${tool_name^} Report for ${scan_dir}|g" "$html_file"
    sed -i '' "s|snyk|${tool_display_name}|gi" "$html_file"
    sed -i '' "s|Snyk|${tool_display_name}|g" "$html_file"
  else
    sed -i "s|>Snyk Report<|>${tool_name^} Report for ${scan_dir}<|" "$html_file"
    sed -i "s|Snyk Report|${tool_name^} Report for ${scan_dir}|g" "$html_file"
    sed -i "s|snyk|${tool_display_name}|gi" "$html_file"
    sed -i "s|Snyk|${tool_display_name}|g" "$html_file"
  fi

  echo "[+] HTML report generated: $html_file"
}

run_trivy() {
  local format=$1
  local scan_dir=$2
  local output_format=$3
  local epoch
  epoch=$(date +%s)
  local output_basename="./scans/${epoch}__trivy_${scan_dir}"

  echo "[*] Running Trivy IaC scan on directory: $(pwd)"
  
  if ! trivy config . --format "$format" --output "${output_basename}.${format}" --quiet 2>/dev/null; then
    echo "[!] Trivy scan failed"
    return 1
  fi

  if [[ ! -f "${output_basename}.${format}" ]]; then
    echo "[!] Trivy did not generate output file: ${output_basename}.${format}"
    return 1
  fi

  if [[ "$output_format" == "html" ]]; then
    convert_sarif_to_html "trivy" "$scan_dir" "${output_basename}.${format}" "${output_basename}.html"
  else
    echo "[+] Trivy scan completed. Results saved to: ${output_basename}.${format}"
  fi
}

run_checkov() {
  local format=$1
  local scan_dir=$2
  local output_format=$3
  local epoch
  epoch=$(date +%s)
  local output_basename="./scans/${epoch}__checkov_${scan_dir}"

  echo "[*] Running Checkov scan on directory: $(pwd)"

  # For HTML output, we need SARIF format first
  local checkov_format="$format"
  if [[ "$output_format" == "html" ]]; then
    checkov_format="sarif"
  fi

  # Run Checkov with output-file-path to ./scans directory
  if ! checkov -d . --output "$checkov_format" --output-file-path ./scans --quiet --soft-fail; then
    echo "[!] Checkov scan failed"
    return 1
  fi

  # Determine the expected output file based on format
  local expected_file=""
  if [[ "$checkov_format" == "sarif" ]]; then
    expected_file="./scans/results_sarif.sarif"
  elif [[ "$checkov_format" == "json" ]]; then
    expected_file="./scans/results_json.json"
  elif [[ "$checkov_format" == "csv" ]]; then
    expected_file="./scans/results_csv.csv"
  else
    expected_file="./scans/results.${checkov_format}"
  fi

  # Check if Checkov created the expected output file
  if [[ ! -f "$expected_file" ]]; then
    echo "[!] Checkov did not generate expected file: $expected_file"
    return 1
  fi

  # Move the results file to our naming convention
  mv "$expected_file" "${output_basename}.${checkov_format}"
  echo "[DEBUG] Moved $expected_file to ${output_basename}.${checkov_format}"

  if [[ "$output_format" == "html" ]]; then
    convert_sarif_to_html "checkov" "$scan_dir" "${output_basename}.${checkov_format}" "${output_basename}.html"
  else
    echo "[+] Checkov scan completed. Results saved to: ${output_basename}.${checkov_format}"
  fi
}

main() {
  local tool=""
  local output=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t)
        tool=$2
        shift 2
        ;;
      -o)
        output=$2
        shift 2
        ;;
      --help)
        print_help
        ;;
      *)
        echo "[!] Unknown argument: $1"
        print_help
        ;;
    esac
  done

  if [[ -z "${tool}" || -z "${output}" ]]; then
    print_help
  fi

  # Convert to lowercase
  tool=$(echo "$tool" | tr '[:upper:]' '[:lower:]')
  output=$(echo "$output" | tr '[:upper:]' '[:lower:]')

  # Validate inputs
  if [[ "$tool" != "trivy" && "$tool" != "checkov" && "$tool" != "both" ]]; then
    echo "[!] Invalid tool: $tool. Must be one of: trivy, checkov, both"
    exit 1
  fi

  if [[ "$output" != "json" && "$output" != "sarif" && "$output" != "html" && "$output" != "csv" ]]; then
    echo "[!] Invalid output: $output. Must be one of: json, sarif, html, csv"
    exit 1
  fi

  # Set format for tools (use sarif for html conversion)
  local actual_format="$output"
  if [[ "$output" == "html" ]]; then
    actual_format="sarif"
  fi

  local scan_dir
  scan_dir=$(basename "$(pwd)")

  echo "[*] Starting IaC scan with tool(s): $tool, output format: $output"
  mkdir -p ./scans

  # Set global variables for use in check_dependencies and execute_scans
  export TOOL="$tool"
  export OUTPUT="$output"
  export ACTUAL_FORMAT="$actual_format"
  export SCAN_DIR="$scan_dir"

  # Check dependencies and execute scans
  if ! check_dependencies; then
    echo "[!] Scan failed"
    exit 1
  fi

  echo "[+] All scans completed successfully. Results saved to ./scans directory"
}

# Call main function with all arguments
main "$@"
