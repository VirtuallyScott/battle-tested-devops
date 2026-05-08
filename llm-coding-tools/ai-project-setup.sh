#!/usr/bin/env bash
# ai-project-setup — Scaffold multi-engineer AI tool config for any repo
#
# Install:  curl -fsSL https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/main/llm-coding-tools/install.sh | bash
# Usage:    ai-project-setup init
# Upgrade:  ai-project-setup --upgrade
# Docs:     https://github.com/VirtuallyScott/battle-tested-devops/tree/main/llm-coding-tools

set -euo pipefail

# ---------------------------------------------------------------------------
# Metadata
# ---------------------------------------------------------------------------
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="ai-project-setup"
INSTALL_DIR="${HOME}/.local/bin"
INSTALL_PATH="${INSTALL_DIR}/${SCRIPT_NAME}"
GITHUB_RAW_BASE="https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/main/llm-coding-tools"
SCRIPT_URL="${GITHUB_RAW_BASE}/ai-project-setup.sh"

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
skip()    { echo -e "${DIM}[SKIP]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die()     { error "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
_has() { command -v "$1" &>/dev/null; }

_download() {
  local url="$1" dest="$2"
  if _has curl; then
    curl -fsSL --proto '=https' --tlsv1.2 -o "${dest}" "${url}"
  elif _has wget; then
    wget -qO "${dest}" "${url}"
  else
    die "curl or wget required to download files."
  fi
}

# Write a file only if it does not already exist (idempotent).
# Usage: _write_file <path> <<'EOF' ... EOF
_write_file() {
  local path="$1"
  local dir
  dir="$(dirname "${path}")"
  mkdir -p "${dir}"
  if [[ -e "${path}" ]]; then
    skip "${path} (already exists — not overwritten)"
    return
  fi
  cat > "${path}"
  success "${path}"
}

# Append lines to .gitignore only if they are not already present.
_gitignore_add() {
  local entry="$1"
  local gitignore=".gitignore"
  if [[ ! -f "${gitignore}" ]]; then
    touch "${gitignore}"
  fi
  if grep -qxF "${entry}" "${gitignore}" 2>/dev/null; then
    skip ".gitignore already contains: ${entry}"
  else
    echo "${entry}" >> "${gitignore}"
    success ".gitignore ← ${entry}"
  fi
}

# ---------------------------------------------------------------------------
# Usage / help
# ---------------------------------------------------------------------------
_usage() {
  cat <<EOF

${BOLD}${SCRIPT_NAME}${NC} v${SCRIPT_VERSION} — Multi-engineer AI tool config scaffolder

${BOLD}COMMANDS${NC}
  init [--force]    Scaffold AI config files in the current git repo.
                    Uses the current directory name as the project name by default.
                    --force overwrites existing files.

  --upgrade         Download and install the latest version from GitHub.
  --version         Print the current version and exit.
  --help            Show this help message.

${BOLD}EXAMPLES${NC}
  cd ~/src/my-project
  ${SCRIPT_NAME} init

  # Re-run safely — existing files are never overwritten without --force
  ${SCRIPT_NAME} init

  # Overwrite all files with fresh templates
  ${SCRIPT_NAME} init --force

  # Keep the tool up to date
  ${SCRIPT_NAME} --upgrade

${BOLD}INSTALL${NC}
  curl -fsSL ${GITHUB_RAW_BASE}/install.sh | bash

${BOLD}DOCS${NC}
  https://github.com/VirtuallyScott/battle-tested-devops/tree/main/llm-coding-tools

EOF
}

# ---------------------------------------------------------------------------
# Upgrade
# ---------------------------------------------------------------------------
_upgrade() {
  echo ""
  info "Upgrading ${SCRIPT_NAME}..."

  if [[ "$(uname -s)" != "Darwin" ]]; then
    die "Upgrade is supported on macOS only."
  fi

  local tmp
  tmp="$(mktemp)"
  trap 'rm -f "${tmp}"' EXIT

  _download "${SCRIPT_URL}" "${tmp}"

  # Sanity check
  if ! head -1 "${tmp}" | grep -q '^#!'; then
    die "Downloaded file does not look like a shell script. Upgrade aborted."
  fi

  install -m 0755 "${tmp}" "${INSTALL_PATH}"
  success "Upgraded to $(${INSTALL_PATH} --version 2>/dev/null || echo 'latest')"
  echo ""
}

# ---------------------------------------------------------------------------
# Template: CLAUDE.md
# ---------------------------------------------------------------------------
_tpl_claude_md() {
  local name="$1" desc="$2" lang="$3"
  cat <<TMPL
# ${name}

${desc}

## Build / Run

<!-- TODO: fill in your actual commands -->
- Install deps: \`<command>\`
- Run locally:  \`<command>\`
- Run tests:    \`<command>\`
- Lint:         \`<command>\`
- Build:        \`<command>\`

## Structure

<!-- TODO: describe the key directories for this project -->
- \`src/\`   — application source
- \`tests/\` — test suites
- \`docs/\`  — documentation

## Key Conventions

- Primary language / framework: ${lang}
- Full coding rules: \`.claude/rules/project.md\`
- Security rules:    \`.claude/rules/security.md\`

## Rules

All shared rules live in \`.claude/rules/\` — do not duplicate them here.
This file is for orientation and build commands only.
TMPL
}

# ---------------------------------------------------------------------------
# Template: .github/copilot-instructions.md
# ---------------------------------------------------------------------------
_tpl_copilot_instructions() {
  local name="$1" desc="$2" lang="$3"
  cat <<TMPL
# Copilot Instructions — ${name}

## Project Context

${desc}

Primary language / framework: ${lang}

## Conventions

Full rules live in \`.claude/rules/project.md\`. Key points:

<!-- TODO: add 3-5 project-specific conventions -->
- Follow the naming conventions defined in \`.claude/rules/project.md\`
- Keep functions small and focused (< 50 lines)
- Prefer immutable data over mutation

## Security

Full rules live in \`.claude/rules/security.md\`. Key points:

- Never suggest hardcoded secrets — use environment variables
- Validate all user input at system boundaries
- Use parameterised queries — never string-concatenate SQL
- Sanitise all output rendered to HTML

## Style

- Prefer explicit error handling over silent swallowing
- Write self-documenting code; add comments only to explain *why*, not *what*
- New code requires tests — aim for ≥ 80% coverage
TMPL
}

# ---------------------------------------------------------------------------
# Template: .claude/rules/project.md
# ---------------------------------------------------------------------------
_tpl_rules_project() {
  local name="$1" lang="$2"
  cat <<TMPL
# ${name} — Project Conventions

This file is the single source of truth for shared coding conventions.
Both \`CLAUDE.md\` and \`.github/copilot-instructions.md\` reference this file.

## Language / Framework

Primary: ${lang}

## Naming

<!-- TODO: replace with your project's actual conventions -->
- Variables and functions: camelCase (JS/TS) | snake_case (Python/Go/Rust)
- Types, classes, components: PascalCase
- Constants: UPPER_SNAKE_CASE
- Booleans: prefer \`is\`, \`has\`, \`should\`, \`can\` prefixes

## Structure

<!-- TODO: describe expected directory conventions -->
- One responsibility per file
- Group by feature/domain, not by file type
- Max ~400 lines per file; extract modules beyond 800 lines

## Immutability

- Always create new objects; never mutate existing ones
- Avoid in-place array/object modification

## Error Handling

- Handle errors explicitly at every level
- Never silently swallow exceptions
- Provide user-friendly messages in UI-facing code
- Log detailed context on the server side

## Testing

- New functionality requires tests before merging
- Minimum 80% coverage target
- Follow Arrange-Act-Assert structure
- Test names describe the behaviour under test

## Tooling

<!-- TODO: fill in linters, formatters, test runners used in this project -->
- Linter:     \`<tool and config>\`
- Formatter:  \`<tool and config>\`
- Test runner:\`<tool and config>\`
TMPL
}

# ---------------------------------------------------------------------------
# Template: .claude/rules/security.md
# ---------------------------------------------------------------------------
_tpl_rules_security() {
  local name="$1"
  cat <<TMPL
# ${name} — Security Rules

This file is the canonical security ruleset for the project.
All AI tools draw from this file — do not duplicate these rules elsewhere.

## Secrets

- Never hardcode API keys, passwords, tokens, or certificates in source code
- Use environment variables or a secrets manager (e.g. AWS Secrets Manager, Vault)
- Validate that required secrets are present at startup; fail fast if missing
- Rotate any secret that may have been accidentally committed

## Input Validation

- Validate and sanitise all user input at system boundaries
- Use schema-based validation where available
- Fail fast with clear, safe error messages (no stack traces to end users)
- Never trust external data: API responses, user input, file content, headers

## Injection Prevention

- Use parameterised queries or an ORM — never string-concatenate SQL
- Escape all dynamic content rendered to HTML (prevent XSS)
- Avoid shell execution with user-controlled input

## Authentication & Authorisation

- Verify authentication and authorisation on every state-changing request
- Enforce least-privilege access
- Use CSRF protection on state-changing forms
- Rate-limit authentication endpoints

## Transport

- Use HTTPS / TLS 1.2+ for all external communication
- Verify TLS certificates — never disable certificate validation
- Set appropriate security headers (HSTS, X-Content-Type-Options, etc.)

## Logging

- Never log secrets, passwords, tokens, or full credit card numbers
- Log sufficient context for incident investigation without leaking PII
- Error messages shown to users must not reveal implementation details

## Dependencies

- Review new dependencies before adding them
- Pin dependency versions in production
- Audit regularly for known vulnerabilities (\`npm audit\`, \`pip-audit\`, etc.)

## Pre-commit Checklist

- [ ] No hardcoded secrets
- [ ] All user inputs validated
- [ ] SQL injection prevention in place
- [ ] XSS prevention in place
- [ ] Authentication/authorisation verified
- [ ] No sensitive data in logs or error messages
TMPL
}

# ---------------------------------------------------------------------------
# Template: .claude/commands/example.md
# ---------------------------------------------------------------------------
_tpl_commands_example() {
  cat <<TMPL
# example — Shared slash command template

Usage: /example [arguments]

This is a shared slash command available to the whole team in Claude Code.
Rename this file and replace the content below with a real command.

Examples of useful shared commands:
- /run-tests         — run the test suite with coverage
- /lint              — run linters and auto-fix where possible
- /check-security    — run a quick security scan
- /create-pr         — draft a PR description from recent commits

---

<!-- Replace everything below with your actual command content -->
echo "Replace me with a real command"
TMPL
}

# ---------------------------------------------------------------------------
# Template: .claude/personal/.gitkeep
# ---------------------------------------------------------------------------
_tpl_personal_gitkeep() {
  cat <<TMPL
# .claude/personal/

Drop your personal Claude Code preferences here — this directory is gitignored.
Files here are loaded automatically by Claude Code alongside the shared rules.

Example file: preferences.md

  # Personal Preferences
  - Terse responses, no preamble
  - Apply changes directly, skip confirmation
  - Always show a diff before editing

See llm-coding-tools/MULTI_ENGINEER_AI_SETUP.md for the full guide.
TMPL
}

# ---------------------------------------------------------------------------
# Template: .github/PULL_REQUEST_TEMPLATE.md
# ---------------------------------------------------------------------------
_tpl_pr_template() {
  cat <<TMPL
## Summary

<!-- What does this PR do? Why? -->

## Changes

<!-- List the key changes made -->
-
-

## Testing

<!-- How was this tested? -->
- [ ] Unit tests added / updated
- [ ] Integration tests added / updated
- [ ] Manual testing performed

## Security

<!-- Any security implications? -->
- [ ] No secrets introduced
- [ ] Input validation in place where relevant
- [ ] No new dependencies without review

## Checklist

- [ ] Tests pass locally
- [ ] Linting passes
- [ ] Documentation updated (if needed)
- [ ] Breaking changes documented (if any)
TMPL
}

# ---------------------------------------------------------------------------
# Template: .github/ISSUE_TEMPLATE/bug_report.md
# ---------------------------------------------------------------------------
_tpl_bug_report() {
  cat <<TMPL
---
name: Bug report
about: Report a reproducible bug
title: "bug: "
labels: bug
assignees: ''
---

## Describe the bug

<!-- A clear description of what the bug is -->

## Steps to reproduce

1.
2.
3.

## Expected behaviour

<!-- What you expected to happen -->

## Actual behaviour

<!-- What actually happened -->

## Environment

- OS:
- Version / commit:
- Relevant config:

## Additional context

<!-- Logs, screenshots, or anything else useful -->
TMPL
}

# ---------------------------------------------------------------------------
# Template: .github/ISSUE_TEMPLATE/feature_request.md
# ---------------------------------------------------------------------------
_tpl_feature_request() {
  cat <<TMPL
---
name: Feature request
about: Propose a new feature or improvement
title: "feat: "
labels: enhancement
assignees: ''
---

## Problem statement

<!-- What problem does this feature solve? Who is affected? -->

## Proposed solution

<!-- Describe the feature you'd like -->

## Alternatives considered

<!-- Any alternative approaches you considered -->

## Acceptance criteria

- [ ]
- [ ]

## Additional context

<!-- Mockups, references, or anything else useful -->
TMPL
}

# ---------------------------------------------------------------------------
# Init — scaffold the repo
# ---------------------------------------------------------------------------
_init() {
  local force=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force|-f) force=true; shift ;;
      *) die "Unknown option for init: $1. See '${SCRIPT_NAME} --help'" ;;
    esac
  done

  # Must be inside a directory (git repo preferred but not required)
  if [[ ! -d "." ]]; then
    die "Cannot determine current directory."
  fi

  echo ""
  echo -e "${BOLD}ai-project-setup init${NC}"
  echo "Working directory: $(pwd)"
  echo ""

  # Prompt for project metadata
  local default_name
  default_name="$(basename "$(pwd)")"

  read -r -p "Project name [${default_name}]: " project_name
  project_name="${project_name:-${default_name}}"

  read -r -p "One-line project description: " project_desc
  project_desc="${project_desc:-TODO: add project description}"

  read -r -p "Primary language / framework: " project_lang
  project_lang="${project_lang:-TODO: specify language/framework}"

  echo ""
  echo -e "${CYAN}Scaffolding files...${NC}"
  echo ""

  # Override _write_file behaviour when --force
  if [[ "${force}" == true ]]; then
    _write_file() {
      local path="$1"
      local dir
      dir="$(dirname "${path}")"
      mkdir -p "${dir}"
      cat > "${path}"
      success "${path} (force)"
    }
  fi

  # ---- CLAUDE.md -----------------------------------------------------------
  _write_file "CLAUDE.md" < <(_tpl_claude_md "${project_name}" "${project_desc}" "${project_lang}")

  # ---- .github/copilot-instructions.md ------------------------------------
  _write_file ".github/copilot-instructions.md" < <(_tpl_copilot_instructions "${project_name}" "${project_desc}" "${project_lang}")

  # ---- .claude/rules/ -----------------------------------------------------
  _write_file ".claude/rules/project.md"  < <(_tpl_rules_project "${project_name}" "${project_lang}")
  _write_file ".claude/rules/security.md" < <(_tpl_rules_security "${project_name}")

  # ---- .claude/commands/ --------------------------------------------------
  _write_file ".claude/commands/example.md" < <(_tpl_commands_example)

  # ---- .claude/personal/ --------------------------------------------------
  _write_file ".claude/personal/.gitkeep" < <(_tpl_personal_gitkeep)

  # ---- .github/ templates -------------------------------------------------
  _write_file ".github/PULL_REQUEST_TEMPLATE.md"         < <(_tpl_pr_template)
  _write_file ".github/ISSUE_TEMPLATE/bug_report.md"     < <(_tpl_bug_report)
  _write_file ".github/ISSUE_TEMPLATE/feature_request.md" < <(_tpl_feature_request)

  # ---- .gitignore ----------------------------------------------------------
  echo ""
  echo -e "${CYAN}Updating .gitignore...${NC}"
  _gitignore_add "# AI tool personal overrides"
  _gitignore_add ".claude/personal/"
  _gitignore_add ".claude/settings.local.json"

  # ---- Summary -------------------------------------------------------------
  echo ""
  echo -e "${GREEN}${BOLD}Done!${NC} ${project_name} is ready for multi-engineer AI workflows."
  echo ""
  echo "  Next steps:"
  echo "  1. Edit CLAUDE.md — fill in your actual build commands and structure"
  echo "  2. Edit .claude/rules/project.md — add your real conventions"
  echo "  3. Edit .github/copilot-instructions.md — trim the summary to match"
  echo "  4. Commit the generated files (except .claude/personal/)"
  echo ""
  echo "  Each engineer adds their personal preferences to:"
  echo "  .claude/personal/preferences.md  (gitignored, loaded automatically)"
  echo ""
  echo "  Docs: ${GITHUB_RAW_BASE}/MULTI_ENGINEER_AI_SETUP.md"
  echo ""
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
main() {
  case "${1:-}" in
    init)
      shift
      _init "$@"
      ;;
    --upgrade|upgrade)
      _upgrade
      ;;
    --version|-V|version)
      echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
      ;;
    --help|-h|help|"")
      _usage
      ;;
    *)
      error "Unknown command: ${1}"
      _usage
      exit 1
      ;;
  esac
}

main "$@"
