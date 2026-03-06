#!/usr/bin/env bash
# deploy.sh – clone juno nvim config and launch Neovim

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERR]${RESET}   $*" >&2; exit 1; }

NVIM_CONFIG_DIR="${HOME}/.config/nvim"
REPO_URL="${1:-https://github.com/thijsrijkers/juno}"

# ── 1. Check dependencies ─────────────────────────────────────────────
info "Checking dependencies…"
for cmd in git nvim; do
  if ! command -v "${cmd}" &>/dev/null; then
    error "'${cmd}' is not installed. Please install it and re-run."
  fi
done
success "git and nvim are available."

if ! command -v rg &>/dev/null; then
  warn "ripgrep (rg) not found – Telescope live_grep won't work."
  warn "Install it: https://github.com/BurntSushi/ripgrep#installation"
fi

# ── 2. Backup existing config ─────────────────────────────────────────
if [[ -d "${NVIM_CONFIG_DIR}" ]]; then
  BACKUP="${NVIM_CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
  warn "Existing config found, backing up to ${BACKUP}"
  mv "${NVIM_CONFIG_DIR}" "${BACKUP}"
fi

# ── 3. Clone ──────────────────────────────────────────────────────────
info "Cloning ${REPO_URL} → ${NVIM_CONFIG_DIR} …"
git clone --depth=1 "${REPO_URL}" "${NVIM_CONFIG_DIR}"
success "Cloned successfully."

# ── 4. Install plugins headlessly so telescope is present ─────────────
info "Installing plugins (this may take a moment)…"
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
success "Plugins installed."

# ── 5. Patch telescope ft_to_lang compatibility ───────────────────────
TELESCOPE_FILE="${HOME}/.local/share/nvim/lazy/telescope.nvim/lua/telescope/builtin/__files.lua"

if [[ -f "${TELESCOPE_FILE}" ]]; then
  info "Patching telescope ft_to_lang compatibility…"
  sed -i 's/filetype = ts_parsers\.ft_to_lang(filetype)/filetype = (ts_parsers.ft_to_lang or function(ft) return ft end)(filetype)/g' "${TELESCOPE_FILE}"
  success "Telescope patched."
else
  warn "Telescope file not found, skipping patch."
fi

# ── 6. Launch ─────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}✓ Juno deployed!${RESET}"
echo ""

cd "${NVIM_CONFIG_DIR}"
exec nvim .