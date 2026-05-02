# Platform — Agent Instructions

## First-Time Setup (Bootstrap)

**Check this first on every session start.** Read `deployments/settings/environment-config.json` and look for unreplaced `{{PLACEHOLDER}}` values.

If placeholders are present, this repo has not been configured yet. Guide the user through the following bootstrap before doing anything else:

### Step 1 — Initialize `.platform`

Check whether `.platform/.github/workflows/scripts/` contains files:

```powershell
Test-Path ".platform/.github/workflows/scripts"
```

If `False` or empty, run:

```powershell
.\Initialize-Repo.ps1
```

Do not proceed until `.platform` is populated.

### Step 2 — Verify required tools

```powershell
$missing = @()
if (-not (Get-Command pac    -ErrorAction SilentlyContinue)) { $missing += 'pac (Power Platform CLI) — https://aka.ms/PowerAppsCLI' }
if (-not (Get-Command gh     -ErrorAction SilentlyContinue)) { $missing += 'gh (GitHub CLI) — https://cli.github.com' }
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { $missing += 'dotnet (.NET SDK) — https://dot.net' }
if ($missing) { Write-Warning "Missing tools:"; $missing | ForEach-Object { Write-Host "  $_" } }
else { Write-Host "All required tools found." -ForegroundColor Green }
```

Also verify `gh` is authenticated (`gh auth status`). If not, run `gh auth login`.

### Step 3 — Install the ALM skills plugin

The `power-platform-alm` plugin is recommended by this workspace. VS Code should show a notification — if so, click **Install**.

If no notification appears, install manually using one of these methods:

**Option A — Extensions sidebar (recommended):**
1. Open the Extensions view (`Ctrl+Shift+X`)
2. Search for `@agentPlugins power-platform-alm`
3. Select **Install**

**Option B — Command Palette:**
1. Open the Command Palette (`Ctrl+Shift+P`)
2. Run `Chat: Install Plugin From Source`
3. Enter: `https://github.com/mikefactorial/Agentic-ALM-Workflows`

Wait for the user to confirm the plugin is installed before continuing.

### Step 4 — Hand off to the setup skill

Once the plugin is installed, tell the user:

> "The ALM skills plugin is now installed. Say **'set up this repo'** and the setup skill will walk you through the rest — filling in environment-config.json, wiring GitHub environments and secrets, OIDC credentials, and branch protection."

**Do not attempt to ask setup questions yourself before the plugin is installed.** The `setup-client-repo` skill has the full, up-to-date intake flow. Do not bypass it by running setup inline.

---

> **Read `deployments/settings/environment-config.json`** at the start of every session to resolve all project-specific values:
> - `clientName` — human-readable product/client name
> - `solutionAreas[].name` / `.prefix` / `.role` — solution identifiers
> - `publisher` — Dataverse publisher name
> - `githubOrg` + `repoName` — GitHub coordinates
> - `innerLoopEnvironments[]` / `environments[]` — all environment slugs and URLs
>
> Do not assume or hardcode any of these values — always derive them from the config file.

## Repository Overview

Power Platform ALM repository for interconnected Dataverse solutions.

Refer to `solutionAreas[]` in `deployments/settings/environment-config.json` for the full solution inventory (name, prefix, publisher, role). Multi-solution repos will have multiple entries.

**GitHub repo**: Read `githubOrg` / `repoName` from `environment-config.json`.

## Platform Scripts

PowerShell scripts used by skills and local development live in the `.platform` git submodule, which points to `{{GITHUB_ORG}}/Agentic-ALM-Workflows`. This is the same path used by callable workflows in CI.

**Initialize or update to latest:**
```powershell
.\Initialize-Repo.ps1
```

All skill script references use `.platform/.github/workflows/scripts/`. If `.platform` is empty, run the command above.

---

## Agent Skills (Plugin)

ALM skills (start-feature, scaffold-plugin, deploy-solution, etc.) ship as the `power-platform-alm` plugin from `Agentic-ALM-Workflows`. Skills cover the full inner and outer loop.

**Install for GitHub Copilot (VS Code):**
- VS Code will suggest it automatically (workspace recommendation) — click **Install** in the notification
- Or: Extensions view (`Ctrl+Shift+X`) → search `@agentPlugins power-platform-alm` → Install
- Or: Command Palette → `Chat: Install Plugin From Source` → `https://github.com/mikefactorial/Agentic-ALM-Workflows`

**Install for Claude Code (once `.platform` is initialized):**
```bash
claude --plugin-dir .platform/.github/plugins/power-platform-alm
```

After installing, describe any ALM task in plain English — the `alm-overview` router skill picks the right specialist automatically.

---

## Branching Strategy

```
main (production-ready, protected)
 ↑ PR from develop or hotfix/* only (enforced by check-source-branch.yml)
develop (integration branch)
 ↑ PR from feature branches / transport commits
feature branches: <type>/AB<WorkItemNumber>_BriefDescription (branch from develop)
hotfix branches: hotfix/<issue-number> (branch from main, merge to both main + develop)
```

- Feature branches always branch from `develop`
- Feature branch naming: `<type>/AB<WorkItemNumber>_BriefDescription`
  - Types: `feat/`, `fix/`, `chore/`, `refactor/`, `docs/`, `test/`
- Hotfix branches: `hotfix/<issue-number>` from `main`
- Push to `main` triggers automatic release package build

## Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <description> AB#<WorkItemNumber>
```

- **Types**: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `build`, `ci`
- **Scope** (optional): solution name or component area
- **Work item linking**: append `AB#<WorkItemNumber>` to link to Azure DevOps work item

---

## ALM Model: Inner Loop and Outer Loop

### Inner Loop (Daily Development)

```
1. Branch from develop → AB####_Description
2. Create feature solution in dev env → set as preferred solution
3. Develop & iterate in dev
4. Sync feature solution to feature branch
5. Build + deploy feature solution to dev-test
6. Test in dev-test environment
7. After validation: transport feature solution from dev → integration
8. Merge feature branch → develop (PR for code-first changes)
```

### Outer Loop (Build, Release, Deploy)

```
1. PR develop → main
2. Push to main triggers create-release-package.yml
3. Packages built, versioned, settings generated for all environments
4. GitHub Release created with artifacts
5. Manual dispatch deploy-package.yml to deploy to target environments
```

---

## Environment Topology

Read all environment slugs and URLs from `deployments/settings/environment-config.json`:

- **Inner loop** (dev + integration per solution area): `innerLoopEnvironments[]`
- **Deployment targets** (dev-test, test, prod): `environments[]`
- **Per-solution-area mapping**: `solutionAreas[x].devEnv` → dev slug; `solutionAreas[x].integrationEnv` → integration slug

Resolve the URL for any slug by finding the matching entry in `innerLoopEnvironments[]` or `environments[]` and reading `.url`.

---

## Repository Structure

```
src/
  controls/           # PCF controls
  plugins/            # .NET plugin assemblies
  solutions/          # Unpacked Dataverse solution metadata
deployments/
  settings/           # Deployment configuration
    templates/        # Auto-generated settings templates (from sync)
    connection-mappings.json
    environment-variables.json
    environment-config.json
  data/               # Configuration data for post-deploy import
.github/
  workflows/          # GitHub Actions workflow definitions
    scripts/          # PowerShell automation scripts (from PlatformWorkflows)
```

---

## Running Scripts Locally

Scripts are pulled from `Agentic-ALM-Workflows` via the two-checkout pattern in each
callable workflow. For local use, clone Agentic-ALM-Workflows and run scripts directly.

### Prerequisites

```powershell
# Read the dev URL from innerLoopEnvironments[] in environment-config.json
pac auth create --interactive --environment {devEnvUrl}
pac auth list
pac auth select --index <n>
```

---

## Critical Rules

1. **Never edit Solution.xml manually** — always sync from the Dataverse environment
2. **Always set preferred solution** when creating a feature solution in Dataverse
3. **PCF controls are NOT auto-tracked** — must be added to preferred solution manually
4. **Forward slashes** in plugin assembly file paths in solution XML (not backslashes)
5. **Settings templates are auto-generated** during sync — don't edit templates directly
6. **Date-based versioning**: `YYYY.MM.DD.N` (e.g., `2026.04.06.1`), auto-calculated from git tags
7. **Package deploy** (outer loop) vs **solution import** (inner loop) — don't mix them up
8. **Transport must go via GitHub Actions workflow** — branch protection prevents direct pushes
9. **dotnet build for inner loop** — `Build-Solutions.ps1` is outer-loop/CI only
10. **Always sync before deploying to dev-test** — never assume a feature is code-first only
