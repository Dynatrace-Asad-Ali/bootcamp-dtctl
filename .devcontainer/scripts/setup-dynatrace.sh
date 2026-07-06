#!/usr/bin/env bash
# Runs on every codespace start (postStartCommand).
# Installs dtctl, configures Dynatrace contexts from Codespace secrets,
# and writes MCP server configs for Claude Code and VS Code.
#
# Tenant secrets (set at github.com/<org>/<repo>/settings/secrets/codespaces):
#
#   DT_1_NAME   label for first tenant, e.g. "prod"
#   DT_1_URL    tenant URL, e.g. "https://abc123.apps.dynatrace.com"
#   DT_1_TOKEN  API platform token
#
#   DT_2_NAME / DT_2_URL / DT_2_TOKEN  (optional second tenant)
#   DT_3_NAME / DT_3_URL / DT_3_TOKEN  (optional third tenant)
#
#   DT_ACTIVE   which context MCP connects to (defaults to DT_1_NAME)

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIGURED=0

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

# ── Configure dtctl contexts ──────────────────────────────────────────────────
header "Dynatrace contexts"

configure_context() {
  local name="$1" url="$2" token="$3"
  [[ -z "$name" || -z "$url" || -z "$token" ]] && return 0

  local cred_ref="${name}-token"
  dtctl config set-context "$name" --environment "$url" --token-ref "$cred_ref" 2>/dev/null
  dtctl config set-credentials "$cred_ref" --token "$token" 2>/dev/null
  ok "Context: $name  →  $url"
  CONFIGURED=$((CONFIGURED + 1))
}

configure_context "${DT_1_NAME:-}" "${DT_1_URL:-}" "${DT_1_TOKEN:-}"
configure_context "${DT_2_NAME:-}" "${DT_2_URL:-}" "${DT_2_TOKEN:-}"
configure_context "${DT_3_NAME:-}" "${DT_3_URL:-}" "${DT_3_TOKEN:-}"

if [[ "$CONFIGURED" -eq 0 ]]; then
  warn "No DT_*_NAME/URL/TOKEN secrets found — skipping context setup."
  warn "Add Codespace secrets: DT_1_NAME, DT_1_URL, DT_1_TOKEN"
  warn "See: github.com/<your-org>/<repo>/settings/secrets/codespaces"
  exit 0
fi

# ── Switch active context ─────────────────────────────────────────────────────
ACTIVE="${DT_ACTIVE:-${DT_1_NAME:-}}"
if [[ -n "$ACTIVE" ]]; then
  dtctl ctx "$ACTIVE" 2>/dev/null && ok "Active context: $ACTIVE"
fi

# ── Resolve URL + token for the active context ────────────────────────────────
ACTIVE_URL=""
ACTIVE_TOKEN=""
for i in 1 2 3; do
  n_var="DT_${i}_NAME"
  u_var="DT_${i}_URL"
  t_var="DT_${i}_TOKEN"
  if [[ "${!n_var:-}" == "$ACTIVE" ]]; then
    ACTIVE_URL="${!u_var:-}"
    ACTIVE_TOKEN="${!t_var:-}"
    break
  fi
done

# ── Write MCP configs ─────────────────────────────────────────────────────────
header "MCP server"

if [[ -z "$ACTIVE_URL" || -z "$ACTIVE_TOKEN" ]]; then
  warn "Could not resolve URL/token for active context '$ACTIVE' — skipping MCP config."
  exit 0
fi

MCP_URL="${ACTIVE_URL%/}/platform-reserved/mcp-gateway/v0.1/servers/dynatrace-mcp/mcp"

# Claude Code — settings.local.json is gitignored and loaded automatically
mkdir -p "${REPO_ROOT}/.claude"
cat > "${REPO_ROOT}/.claude/settings.local.json" <<EOF
{
  "mcpServers": {
    "dynatrace": {
      "url": "${MCP_URL}",
      "headers": {
        "Authorization": "Bearer ${ACTIVE_TOKEN}"
      }
    }
  }
}
EOF
ok "Claude Code MCP  →  ${MCP_URL}"

# VS Code — .vscode/mcp.json is gitignored
mkdir -p "${REPO_ROOT}/.vscode"
cat > "${REPO_ROOT}/.vscode/mcp.json" <<EOF
{
  "servers": {
    "dynatrace": {
      "url": "${MCP_URL}",
      "headers": {
        "Authorization": "Bearer ${ACTIVE_TOKEN}"
      }
    }
  }
}
EOF
ok "VS Code MCP       →  ${MCP_URL}"

# ── Verify connection ─────────────────────────────────────────────────────────
header "Connection check"
dtctl doctor 2>&1 || warn "dtctl doctor reported issues — check token scopes"

echo ""
echo "Setup complete. Active tenant: ${ACTIVE} (${ACTIVE_URL})"
echo "To switch tenants: update DT_ACTIVE secret and rebuild the codespace"
