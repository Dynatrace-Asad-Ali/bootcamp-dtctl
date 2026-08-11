#!/usr/bin/env bash
# Runs on every codespace start (postStartCommand).
# Installs dtctl, configures the Dynatrace context from Codespace secrets,
# and writes MCP server configs for Claude Code and VS Code.
#
# Tenant secrets (set at github.com/<org>/<repo>/settings/secrets/codespaces):
#
#   DT_NAME   label for the tenant, e.g. "prod"
#   DT_URL    tenant URL, e.g. "https://abc123.apps.dynatrace.com"
#   DT_TOKEN_FOR_DTCTL  API platform token

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# ── Helpers ───────────────────────────────────────────────────────────────────
info()  { echo "  $*"; }
ok()    { echo "✓ $*"; }
warn()  { echo "⚠ $*"; }
header(){ echo ""; echo "── $* ──────────────────────────────────────────────"; }

# ── Install dtctl ─────────────────────────────────────────────────────────────
header "dtctl"
if ! command -v dtctl &>/dev/null; then
  info "Installing dtctl..."
  curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | sh
  # ~/.local/bin is where the install script drops the binary on Linux
  export PATH="$HOME/.local/bin:$PATH"
fi
ok "dtctl $(dtctl version 2>/dev/null | head -1 || echo "(unknown version)")"

# ── Install dtctl agent skill ─────────────────────────────────────────────────
if [[ ! -d "${REPO_ROOT}/.agents/skills/dtctl" ]]; then
  info "Installing dtctl agent skill..."
  (cd "${REPO_ROOT}" && npx --yes skills add dynatrace-oss/dtctl 2>/dev/null) \
    && ok "dtctl skill installed" \
    || warn "dtctl skill install failed (non-fatal)"
fi

# ── Configure dtctl context ───────────────────────────────────────────────────
header "Dynatrace context"

ACTIVE_NAME="${DT_NAME:-}"
ACTIVE_URL="${DT_URL:-}"
ACTIVE_TOKEN="${DT_TOKEN_FOR_DTCTL:-}"

if [[ -z "$ACTIVE_NAME" || -z "$ACTIVE_URL" || -z "$ACTIVE_TOKEN" ]]; then
  warn "No DT_NAME/URL/TOKEN secrets found — skipping context setup."
  warn "Add Codespace secrets: DT_NAME, DT_URL, DT_TOKEN"
  warn "See: github.com/<your-org>/<repo>/settings/secrets/codespaces"
  exit 0
fi

CRED_REF="${ACTIVE_NAME}-token"
dtctl config set-context "$ACTIVE_NAME" --environment "$ACTIVE_URL" --token-ref "$CRED_REF" 2>/dev/null
dtctl config set-credentials "$CRED_REF" --token "$ACTIVE_TOKEN" 2>/dev/null
ok "Context: $ACTIVE_NAME  →  $ACTIVE_URL"

dtctl ctx "$ACTIVE_NAME" 2>/dev/null && ok "Active context: $ACTIVE_NAME"

# ── Verify connection ─────────────────────────────────────────────────────────
header "Connection check"
dtctl doctor 2>&1 || warn "dtctl doctor reported issues — check token scopes"

echo ""
echo "Setup complete. Active tenant: ${ACTIVE_NAME} (${ACTIVE_URL})"
