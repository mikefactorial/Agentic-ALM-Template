# Platform — Agent Instructions

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

**One-time local setup:**
```powershell
.\Initialize-Submodules.ps1
```

**Update scripts to latest:**
```powershell
git submodule update --remote .platform
# Or via GitHub Actions: sync-platform-assets.yml → scripts
```

All skill script references use `.platform/.github/workflows/scripts/`. If `.platform` is empty, run the init command above.

---

## Agent Skills (Plugin)

ALM skills (start-feature, scaffold-plugin, deploy-solution, etc.) ship as an installable plugin from `Agentic-ALM-Workflows`. Skills cover the full inner and outer loop.

**Install for GitHub Copilot:**
```
/plugin install github:mikefactorial/Agentic-ALM-Workflows
```

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
2. Create feature solution in preview env → set as preferred solution
3. Develop & iterate in preview
4. Sync feature solution to feature branch
5. Build + deploy feature solution to preview-test
6. Test in preview-test environment
7. After validation: transport feature solution from preview → dev
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

- **Inner loop** (preview + dev per solution area): `innerLoopEnvironments[]`
- **Deployment targets** (preview-test, test, prod): `environments[]`
- **Per-solution-area mapping**: `solutionAreas[x].previewEnv` → preview slug; `solutionAreas[x].devEnv` → dev slug

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
# Read the preview URL from innerLoopEnvironments[] in environment-config.json
pac auth create --interactive --environment {previewEnvUrl}
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
10. **Always sync before deploying to preview-test** — never assume a feature is code-first only
