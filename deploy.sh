#!/usr/bin/env bash
# deploy.sh – clone your nvim config from GitHub and launch Neovim
# Usage: bash deploy.sh [github-repo-url]
# Example: bash deploy.sh https://github.com/youruser/nvim-config

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERR]${RESET}   $*" >&2; exit 1; }

# ── Config ────────────────────────────────────────────────────────────
NVIM_CONFIG_DIR="${HOME}/.config/nvim"
REPO_URL="${1:-}"          # first argument, or empty

# ── 1. Resolve repo URL ───────────────────────────────────────────────
if [[ -z "${REPO_URL}" ]]; then
  echo -e "${BOLD}Enter your GitHub repo URL${RESET}"
  echo    "  e.g. https://github.com/youruser/nvim-config"
  read -rp "→ URL: " REPO_URL
fi

[[ -z "${REPO_URL}" ]] && error "No repo URL provided."

# ── 2. Check dependencies ─────────────────────────────────────────────
info "Checking dependencies…"
for cmd in git nvim; do
  if ! command -v "${cmd}" &>/dev/null; then
    error "'${cmd}' is not installed. Please install it and re-run."
  fi
done
success "git and nvim are available."

# Optional but recommended: ripgrep for Telescope grep
if ! command -v rg &>/dev/null; then
  warn "ripgrep (rg) not found – Telescope live_grep won't work."
  warn "Install it: https://github.com/BurntSushi/ripgrep#installation"
fi

# ── 3. Backup existing config ─────────────────────────────────────────
if [[ -d "${NVIM_CONFIG_DIR}" ]]; then
  BACKUP="${NVIM_CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
  warn "Existing config found at ${NVIM_CONFIG_DIR}"
  warn "Moving it to ${BACKUP}"
  mv "${NVIM_CONFIG_DIR}" "${BACKUP}"
fi

# ── 4. Clone ──────────────────────────────────────────────────────────
info "Cloning ${REPO_URL} → ${NVIM_CONFIG_DIR} …"
git clone --depth=1 "${REPO_URL}" "${NVIM_CONFIG_DIR}"
success "Cloned successfully."

# ── 5. Launch ─────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}✓ Neovim config deployed!${RESET}"
echo -e "  Plugins will auto-install on first launch via ${CYAN}lazy.nvim${RESET}."
echo ""
info "Launching: nvim ${NVIM_CONFIG_DIR}"
echo ""

cd "${NVIM_CONFIG_DIR}"
exec nvim .