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

function configure_ollama {
  # Set default Ollama API base URL if not already set
  if [[ -z "${OLLAMA_API_BASE:-}" ]]; then
    export OLLAMA_API_BASE=http://127.0.0.1:11434
  fi

  # Set context window size (default 8k tokens)
  if [[ -z "${OLLAMA_CONTEXT_LENGTH:-}" ]]; then
    export OLLAMA_CONTEXT_LENGTH=8192
  fi
}

function run_aider {
  echo "Running Aider with model: $chosen_model"
  echo "Using Ollama API: $OLLAMA_API_BASE"
  echo "Context window size: $OLLAMA_CONTEXT_LENGTH tokens"
  
  # Start Ollama server with configured context length
  OLLAMA_CONTEXT_LENGTH=$OLLAMA_CONTEXT_LENGTH ollama serve >/dev/null 2>&1 &
  local ollama_pid=$!
  
  # Run aider with the selected model
  aider --model "ollama_chat/${chosen_model}"
  
  # Clean up Ollama process
  kill $ollama_pid 2>/dev/null
}

# Main Execution Flow
check_dependencies
configure_ollama
list_models
pick_model
run_aider
