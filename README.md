# New Seller Bootcamp

Dynatrace observability workspace with AI agent skills and MCP server integration.

## Codespace Setup

When you open this repo in a GitHub Codespace, dtctl and the Dynatrace MCP server are configured automatically on start. You control which tenant(s) connect by setting **Codespace secrets** in GitHub — no code changes needed to switch environments.

### 1. Add Codespace secrets

Go to **github.com → your profile → Settings → Codespaces → Secrets** (for personal secrets) or **repo → Settings → Secrets and variables → Codespaces** (for repo-scoped secrets).

| Secret | Required | Example | Description |
|---|---|---|---|
| `DT_1_NAME` | Yes | `prod` | Label for your first tenant |
| `DT_1_URL` | Yes | `https://abc123.apps.dynatrace.com` | Tenant URL |
| `DT_1_TOKEN` | Yes | `dt0s16.XXX...` | Platform API token |
| `DT_2_NAME` | No | `staging` | Second tenant label |
| `DT_2_URL` | No | `https://def456.apps.dynatrace.com` | Second tenant URL |
| `DT_2_TOKEN` | No | `dt0s16.YYY...` | Second tenant token |
| `DT_3_NAME` | No | `dev` | Third tenant label |
| `DT_3_URL` | No | `https://ghi789.apps.dynatrace.com` | Third tenant URL |
| `DT_3_TOKEN` | No | `dt0s16.ZZZ...` | Third tenant token |
| `DT_ACTIVE` | No | `staging` | Which tenant MCP connects to (defaults to `DT_1_NAME`) |

### 2. Create or rebuild the codespace

The setup script runs automatically on every start:
- Installs `dtctl` (if not present)
- Registers all provided contexts with dtctl
- Writes `.claude/settings.local.json` and `.vscode/mcp.json` for the active tenant
- Runs `dtctl doctor` to verify the connection

### Switching tenants

Update `DT_ACTIVE` in your Codespace secrets to point to a different context name, then either:
- Rebuild the codespace, **or**
- Run `bash .devcontainer/scripts/setup-dynatrace.sh` in the terminal

### Token scopes

Your Dynatrace API token needs at minimum:
- `mcp-gateway:servers:invoke`
- `mcp-gateway:servers:read`

For dtctl operations add the scopes relevant to what you need (workflows, dashboards, DQL, etc.). See the [dtctl token scopes docs](https://dynatrace-oss.github.io/dtctl/docs/token-scopes/).

## Included Agent Skills

| Skill | Source |
|---|---|
| `dt-dql-essentials`, `dt-obs-*`, `dt-alerting`, `dt-sec-insights`, `dt-app-*`, `dt-platform-costs`, `dt-migration`, `dt-js-runtime` | [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) |
| `dynatrace-kpi-dashboard-generator` | [SudoSmitty/dynatrace-kpi-dashboard-generator](https://github.com/SudoSmitty/dynatrace-kpi-dashboard-generator) |
| `dtctl` | [dynatrace-oss/dtctl](https://github.com/dynatrace-oss/dtctl) (installed on first start) |

To update skills: `npx skills update`

## Attribution & licensing

This repository is licensed under the [Apache License 2.0](LICENSE).

It redistributes agent skills copied from third-party projects. Their original
copyright and license notices are collected in [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES)
and [NOTICE](NOTICE), and must be retained in any redistribution. Skill provenance
is tracked in [`skills-lock.json`](skills-lock.json).

| Skills | Source | License |
|---|---|---|
| `dt-*` (`dt-dql-essentials`, `dt-obs-*`, `dt-alerting`, `dt-sec-insights`, `dt-app-*`, `dt-platform-costs`, `dt-migration`, `dt-js-runtime`) | [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) | Apache-2.0 |
| `dtctl`, `dtctl-release`, `pr-review` | [dynatrace-oss/dtctl](https://github.com/dynatrace-oss/dtctl) | Apache-2.0 |
| `dynatrace-kpi-dashboard-generator` | [SudoSmitty/dynatrace-kpi-dashboard-generator](https://github.com/SudoSmitty/dynatrace-kpi-dashboard-generator) | No upstream license — included with the author's permission |

> **`dynatrace-kpi-dashboard-generator`** has no license file in its upstream
> repository and is redistributed here with the express permission of its
> author. For a cleaner provenance trail, consider asking the author to add an
> explicit open-source license (e.g. Apache-2.0 or MIT) upstream.
