# Setup Guide — New Client Repository

This repository was created from the [Agentic-ALM-Template](https://github.com/mikefactorial/Agentic-ALM-Template).
Follow the steps below to configure it for your project.

---

## Step 1: Replace Placeholders

Search for `{{...}}` placeholders throughout the repo and replace them:

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{{CLIENT_NAME}}` | Human-readable client/product name | `Acme Corp Platform` |
| `{{PRODUCT_DESCRIPTION}}` | One-line product description | `Power Platform solution for Acme Corp` |
| `{{PUBLISHER}}` | Dataverse publisher name | `AcmeCorp` |
| `{{SOLUTION_NAME}}` | Solution name (PascalCase) | `AcmePlatform` |
| `{{SOLUTION_PREFIX}}` | Solution prefix (lowercase, 3–5 chars) | `acm` |
| `{{SOLUTION_ROLE}}` | Role description | `Core platform solution` |
| `{{GITHUB_ORG}}` | GitHub organization | `AcmeCorp` |
| `{{REPO_NAME}}` | GitHub repo name | `AcmeCorp-Platform` |
| `{{ENV_PREFIX}}` | Environment name prefix | `acme` |
| `{{TENANT_SLUG}}` | Short tenant identifier used in env URLs | `acme` |
| `{{PACKAGE_TAG}}` | Release tag suffix appended after the version number | `AcmePlatform` |

Files to update:
- `.github/copilot-instructions.md`
- `.github/workflows/*.yml` (replace `{{GITHUB_ORG}}` placeholder in `uses:` lines)
- `deployments/settings/environment-config.json`
- `src/README.md`

> The `deployments/package/` folder uses no client-specific placeholders and requires no renaming.

---

## Step 2: Configure the Package Deployer Project

Open `deployments/package/Deployer/PlatformPackage.csproj`. Find the `<!-- SETUP: Add one ProjectReference per solution -->` comment block and add an `<ItemGroup>` with one entry per solution that belongs in this package. `ImportOrder` controls import sequence — lower numbers first (core/base solution must have the lowest).

```xml
<ItemGroup>
  <ProjectReference Include="../../../src/solutions/acm_AcmePlatform/acm_AcmePlatform.cdsproj"
                    ReferenceOutputAssembly="false" ImportOrder="1" ImportMode="async" />
</ItemGroup>
```

That's it — no renaming required. The project uses a generic `PlatformPackage` name that works for any client.

---

## Step 3: Configure environment-config.json

Edit `deployments/settings/environment-config.json` to match your actual:
- Solution names and prefixes
- Environment slugs and URLs (dev, test, prod)
- Package groups (which solutions deploy together)

---

## Step 4: Set Up GitHub Secrets and Variables

### Repository Secrets

| Secret | Description |
|--------|-------------|
| `APP_ID` | GitHub App ID (used for cross-repo checkout) |
| `APP_PRIVATE_KEY` | GitHub App private key |

### Environment Variables (per GitHub Environment)

Each deployment target environment needs these variables set in **GitHub Environments**
(Settings → Environments → create one per `slug` in `environment-config.json`):

| Variable | Description |
|----------|-------------|
| `DATAVERSE_URL` | Dataverse environment URL |
| `DATAVERSE_CLIENT_ID` | Service principal / app registration client ID |
| `AZURE_TENANT_ID` | Azure Active Directory tenant ID |

### Repository-Level Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DEPLOYMENT_ENVIRONMENTS` | Comma-separated default deploy targets for `workflow_run` trigger | `acme-test` |
| `PR_VALIDATION_DEV_ENV` | Dev environment slug for PR validation builds | `acme-dev` |

---

## Step 5: Configure OIDC Federated Credentials

For each environment's service principal, create a federated credential for GitHub Actions:

```bash
# Audience: api://AzureADTokenExchange
# Subject:  repo:{org}/{repo}:environment:{env-slug}
```

Test OIDC auth using the `test-oidc-auth.yml` workflow.

---

## Step 6: Set Up GitHub App for Cross-Repo Checkout

The workflows use a GitHub App token (via `actions/create-github-app-token@v1`) to
check out `Agentic-ALM-Workflows`. The App needs:
- `contents: read` on `Agentic-ALM-Workflows`

Install the App on both this repo and `Agentic-ALM-Workflows`.

## Step 7: Branch Protection

Configure branch protection rules in GitHub:
- `main`: require PR from `develop` or `hotfix/*` only (enforced by `check-source-branch.yml`)
- `develop`: require PR reviews, no direct pushes for contributors

---

## Step 8: Initialize Submodules

This repo has one submodule:

| Submodule | Repo | Purpose |
|-----------|------|---------|
| `.platform` | `Agentic-ALM-Workflows` | PowerShell scripts for skills and CI |

Initialize it with the included setup script:

```powershell
.\Initialize-Submodules.ps1
```

After init, `.platform/.github/workflows/scripts/` will contain all scripts used by local skills and GitHub Actions callable workflows.

To update scripts to the latest version:
```powershell
git submodule update --remote .platform
# Or via GitHub Actions: sync-platform-assets.yml → scripts
```

## Step 9: Keeping Platform Assets Updated

Use the `sync-platform-assets.yml` workflow to pull the latest skills, instructions,
or both from `Agentic-ALM-Workflows`:

```
Workflow: sync-platform-assets.yml
Inputs:
  asset_group: all | alm-skills | instructions
  platform_ref: main (or a specific tag)
  create_pr: true
```

This opens a PR with the updated assets for review before merging.
