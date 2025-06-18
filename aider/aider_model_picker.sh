#!/usr/bin/env bash

set -euo pipefail

function error_exit {
  echo "Error: $1" >&2
  exit 1
}

function check_dependencies {
  command -v ollama >/dev/null 2>&1 || error_exit "ollama is not installed or not in PATH"
  command -v aider >/dev/null 2>&1 || error_exit "aider is not installed or not in PATH"
}

function list_models {
  echo "Fetching available Ollama models..."

  if [[ -n "${ZSH_VERSION:-}" ]]; then
    models=("${(@f)$(ollama ls | awk 'NR>1 {print $1}')}")
  else
    mapfile -t models < <(ollama ls | awk 'NR>1 {print $1}')
  fi

  if [ ${#models[@]} -eq 0 ]; then
    error_exit "No models found from 'ollama ls'"
  fi
}

function pick_model {
  echo "Available Models:"
  select model in "${models[@]}"; do
    if [[ -n "$model" ]]; then
      chosen_model="$model"
      break
    else
      echo "Invalid selection. Try again."
    fi
  done
}

function run_aider {
  echo "Running Aider with model: $chosen_model"
  aider --model "ollama_chat/${chosen_model}"
}

# Main Execution Flow
check_dependencies
list_models
pick_model
run_aider
