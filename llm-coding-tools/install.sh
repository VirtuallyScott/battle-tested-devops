#!/usr/bin/env bash
# install.sh — Bootstrap installer for ai-project-setup
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/main/llm-coding-tools/install.sh | bash
#   wget -qO- https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/main/llm-coding-tools/install.sh | bash

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
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
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die()     { error "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Platform guard — macOS only
# ---------------------------------------------------------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
  die "This installer currently supports macOS only. On Linux, install manually: see ${GITHUB_RAW_BASE}/MULTI_ENGINEER_AI_SETUP.md"
fi

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
_has() { command -v "$1" &>/dev/null; }

if _has curl; then
  FETCH_CMD="curl"
elif _has wget; then
  FETCH_CMD="wget"
else
  die "curl or wget is required. Install with: brew install curl"
fi

# ---------------------------------------------------------------------------
# Download helper
# ---------------------------------------------------------------------------
_download() {
  local url="$1" dest="$2"
  if [[ "${FETCH_CMD}" == "curl" ]]; then
    curl -fsSL --proto '=https' --tlsv1.2 -o "${dest}" "${url}"
  else
    wget -qO "${dest}" "${url}"
  fi
}

# ---------------------------------------------------------------------------
# Main install
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}ai-project-setup installer${NC}"
echo "Installing to: ${INSTALL_PATH}"
echo ""

# Create install dir (XDG: ~/.local/bin)
mkdir -p "${INSTALL_DIR}"

# Download the script
info "Downloading ${SCRIPT_NAME}..."
TMP_FILE="$(mktemp)"
trap 'rm -f "${TMP_FILE}"' EXIT

_download "${SCRIPT_URL}" "${TMP_FILE}"

# Sanity check — must start with a shebang
if ! head -1 "${TMP_FILE}" | grep -q '^#!'; then
  die "Downloaded file does not look like a shell script. Check your network or the source URL."
fi

# Install
install -m 0755 "${TMP_FILE}" "${INSTALL_PATH}"
success "Installed ${INSTALL_PATH}"

# ---------------------------------------------------------------------------
# PATH check — warn if ~/.local/bin is not on PATH
# ---------------------------------------------------------------------------
if ! echo "${PATH}" | tr ':' '\n' | grep -qx "${INSTALL_DIR}"; then
  warn "${INSTALL_DIR} is not on your PATH."
  echo ""
  echo "  Add one of these to your shell profile (~/.zshrc or ~/.bash_profile):"
  echo ""
  echo -e "    ${BOLD}export PATH=\"\${HOME}/.local/bin:\${PATH}\"${NC}"
  echo ""
  echo "  Then reload your shell:"
  echo -e "    ${BOLD}source ~/.zshrc${NC}"
  echo ""
else
  success "${INSTALL_DIR} is already on your PATH"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}${BOLD}Installation complete.${NC}"
echo ""
echo "  Scaffold AI config in a repo:"
echo -e "    ${BOLD}cd /path/to/your-repo && ${SCRIPT_NAME} init${NC}"
echo ""
echo "  Upgrade to the latest version:"
echo -e "    ${BOLD}${SCRIPT_NAME} --upgrade${NC}"
echo ""
echo "  Show help:"
echo -e "    ${BOLD}${SCRIPT_NAME} --help${NC}"
echo ""
