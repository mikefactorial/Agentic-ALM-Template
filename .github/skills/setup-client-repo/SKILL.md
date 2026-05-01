---
name: setup-client-repo
description: 'Set up a new client repository from the Agentic-ALM-Template. Use when: onboarding a new client, configuring the template repo for first use, filling in environment-config.json, setting up GitHub environments and secrets, configuring the Package Deployer project, or running through SETUP.md steps.'
---

# Set Up a New Client Repository

Walk through the full first-time configuration of a repository created from `Agentic-ALM-Template`. Setup means filling in `deployments/settings/environment-config.json` (the single source of truth for all project config) and configuring GitHub environments and secrets. No search-and-replace across files is required.

## When to Use

- A new client repository was just created from the template
- `environment-config.json` still contains `{{PLACEHOLDER}}` values
- Running through `SETUP.md` for the first time

## Agent Intake

Before proceeding, gather the following from the user. Ask only for what is missing — do not ask for values that can be inferred:

| # | What to ask | Key | Example |
|---|-------------|-----|---------|
| 1 | Human-readable client/product name | `clientName` | `Acme Corp Platform` |
| 2 | One-line product description | `productDescription` | `Power Platform solution for Acme Corp` |
| 3 | Dataverse publisher name (PascalCase, no spaces) | `publisher` | `AcmeCorp` |
| 4 | Primary solution name (PascalCase, no spaces) | `solutionName` | `AcmePlatform` |
| 5 | Solution prefix (lowercase, 3–5 chars, matches Dataverse publisher prefix) | `solutionPrefix` | `acm` |
| 6 | One-line role description for this solution | `solutionRole` | `Core platform solution` |
| 7 | GitHub organization name | `githubOrg` | `AcmeCorp` |
| 8 | GitHub repository name | `repoName` | `AcmeCorp-Platform` |
| 9 | Environment URL prefix (lowercase slug used in all env names) | `envPrefix` | `acme` |
| 10 | Short tenant slug used in environment URLs | `tenantSlug` | `acme` |
| 11 | Release tag suffix (typically same as `solutionName`) | `packageTag` | `AcmePlatform` |
| 12 | Copyright year | `year` | `2026` |

---

## Procedure

### 1. Fill in `environment-config.json`

Open `deployments/settings/environment-config.json` and replace every `{{PLACEHOLDER}}` value with the client's values gathered above. This is the **only file** that needs editing for the core configuration.

After filling in, it should look like:

```json
{
  "clientName": "Acme Corp Platform",
  "productDescription": "Power Platform solution for Acme Corp",
  "githubOrg": "AcmeCorp",
  "repoName": "AcmeCorp-Platform",
  "publisher": "AcmeCorp",
  "packageTag": "AcmePlatform",
  "solutionAreas": [
    {
      "name": "AcmePlatform",
      "prefix": "acm",
      "role": "Core platform solution",
      "mainSolution": "acm_AcmePlatform",
      "cdsproj": "src/solutions/acm_AcmePlatform/acm_AcmePlatform.cdsproj",
      "pluginsPath": "src/plugins/acm_AcmePlatform",
      "pluginsSln": "src/plugins/acm_AcmePlatform/AcmeCorp.AcmePlatform.Plugins.sln",
      "corePluginRef": null,
      "controlPreBuildPaths": [],
      "previewEnv": "acme-preview",
      "devEnv": "acme-dev"
    }
  ],
  "innerLoopEnvironments": [
    { "slug": "acme-preview", "url": "https://acme-pre-acme.crm.dynamics.com/" },
    { "slug": "acme-dev",     "url": "https://acme-dev-acme.crm.dynamics.com/" }
  ],
  "environments": [
    { "slug": "acme-preview-test", "url": "https://acme-prt-acme.crm.dynamics.com/" },
    { "slug": "acme-test",         "url": "https://acme-tst-acme.crm.dynamics.com/" },
    { "slug": "acme-prod",         "url": "https://acme-prd-acme.crm.dynamics.com/" }
  ],
  "packageGroups": [
    {
      "name": "AcmePlatform",
      "solutions": ["acm_AcmePlatform"],
      "dataSolution": "acm_AcmePlatform",
      "environments": ["acme-preview-test", "acme-test", "acme-prod"]
    }
  ]
}
```

For multi-solution repos, add additional entries to `solutionAreas[]`, `innerLoopEnvironments[]`, and `packageGroups[]`.

---

### 2. Verify No Stray Placeholders

After filling in `environment-config.json`, verify it is the only file with unreplaced tokens (skills, instructions, and workflows read from it at runtime — they contain no placeholders themselves):

```powershell
# Only environment-config.json should appear in results
Select-String -Recurse -Include "*.md","*.json","*.cs","*.csproj","*.sln","*.yml" `
    -Pattern "\{\{[A-Z_]+\}\}" | Select-Object Path, Line | Format-Table -AutoSize
```

---

### 3. Add Solution References to the Package .csproj

Open `deployments/package/Deployer/PlatformPackage.csproj`. Find the `<!-- SETUP: Add one ProjectReference per solution -->` comment and add an `<ItemGroup>` with one `<ProjectReference>` per solution that belongs in this package.

**Single-solution example:**
```xml
<ItemGroup>
  <ProjectReference Include="../../../src/solutions/acm_AcmePlatform/acm_AcmePlatform.cdsproj"
                    ReferenceOutputAssembly="false" ImportOrder="1" ImportMode="async" />
</ItemGroup>
```

**Multi-solution example (core solution first, lowest ImportOrder):**
```xml
<ItemGroup>
  <ProjectReference Include="../../../src/solutions/acm_CoreSolution/acm_CoreSolution.cdsproj"
                    ReferenceOutputAssembly="false" ImportOrder="1" ImportMode="async" />
  <ProjectReference Include="../../../src/solutions/acm_AddOn/acm_AddOn.cdsproj"
                    ReferenceOutputAssembly="false" ImportOrder="2" ImportMode="async" />
</ItemGroup>
```

> The paths are relative from the `.csproj` location (`deployments/package/Deployer/`). Repo root is `../../../`.

No renaming of any files or folders is needed — the package project uses a fixed generic name.

---

### 4. Set Up GitHub Environments

For each slug in `environments[]` in `environment-config.json`, create a GitHub Environment:

1. Go to **Settings → Environments → New environment** in the repository
2. Name it exactly as the slug (e.g. `acme-test`)
3. Add these variables:

| Variable | Value |
|----------|-------|
| `DATAVERSE_URL` | Full Dataverse environment URL (with trailing `/`) |
| `DATAVERSE_CLIENT_ID` | App registration client ID for this environment |

4. Add `AZURE_TENANT_ID` as a **repository-level** variable (same for all environments)
5. Configure approval gates on test and prod tier environments

---

### 5. Configure OIDC Federated Credentials

For each environment's app registration, add a federated credential:

```
Audience: api://AzureADTokenExchange
Subject:  repo:<githubOrg>/<repoName>:environment:<env-slug>
```

Test using `test-oidc-auth.yml` workflow after completing this step.

---

### 6. Set Up Repository Secrets and Variables

**Repository secrets** (Settings → Secrets and variables → Actions → Secrets):

| Secret | Description |
|--------|-------------|
| `APP_ID` | GitHub App ID (for cross-repo checkout of PlatformWorkflows) |
| `APP_PRIVATE_KEY` | GitHub App private key |

**Repository variables** (Settings → Secrets and variables → Actions → Variables):

| Variable | Description | Example |
|----------|-------------|---------|
| `AZURE_TENANT_ID` | Azure AD tenant ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `DEPLOYMENT_ENVIRONMENTS` | Default deploy targets for `workflow_run` trigger | `acme-test` |
| `PR_VALIDATION_DEV_ENV` | Dev env slug for PR validation | `acme-dev` |

---

### 7. Initialize Submodules

```powershell
.\Initialize-Submodules.ps1
# Verify scripts are present
Get-ChildItem ".platform/.github/workflows/scripts/*.ps1" | Select-Object Name
```

This script runs `git submodule update --init --filter=blob:none` for the `.platform` submodule. Do not use `git submodule update --init` alone.

---

### 8. Set Up Branch Protection

In GitHub → Settings → Branches, add rules:

- **`main`**: Require PR, restrict to `develop` or `hotfix/*` source (enforced by `check-source-branch.yml`)
- **`develop`**: Require PR review; no force push; no direct push for non-admins

---

### 9. Initial Commit and Push

Commit all the changes made in the steps above:

```powershell
git add -A
git commit -m "chore: initial client configuration

- Fill in environment-config.json with client values
- Add solution references to deployments/package/Deployer/PlatformPackage.csproj"
git push origin develop
```

> Push to `develop`, not `main`. `main` is protected and only accepts PRs.

---

### 10. Verify Setup

Run a quick sanity check:

```powershell
# 1. Only environment-config.json should have unreplaced values (i.e. none, since we filled it in)
$remaining = Select-String -Recurse -Include "*.md","*.json","*.cs","*.csproj","*.sln","*.yml" `
    -Pattern "\{\{[A-Z_]+\}\}" | Measure-Object
Write-Host "Unreplaced placeholders: $($remaining.Count)"

# 2. Package project builds
dotnet build "deployments/package/PlatformPackage.sln" --configuration Release

# 3. Submodule is present
Test-Path ".platform/.github/workflows/scripts/Build-Package.ps1"
```

---

## Common Issues

| Issue | Fix |
|-------|-----|
| `dotnet build` fails with "could not find part of the path" for solution `.cdsproj` | The `ProjectReference` paths in `PlatformPackage.csproj` are wrong — paths are relative from `deployments/package/Deployer/` |
| Remaining `{{PLACEHOLDER}}` values in `environment-config.json` | Fill in all keys — every `{{...}}` value in the file needs to be replaced with a real value |
| Git submodule empty | Run `.\Initialize-Submodules.ps1` from the repo root |
| OIDC auth fails | Verify the federated credential subject exactly matches `repo:<org>/<repo>:environment:<slug>` (case-sensitive) |
