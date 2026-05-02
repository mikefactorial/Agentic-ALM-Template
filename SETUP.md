# Setup Guide — New Client Repository

This repository was created from the [Agentic-ALM-Template](https://github.com/mikefactorial/Agentic-ALM-Template).

## Quick Start

Run the setup script, install the plugin, then let the agent walk you through the rest:

```powershell
.\Initialize-Repo.ps1
```

This initializes the `.platform` submodule and prints plugin install instructions. After installing the plugin, say to the agent:

> "Set up this repo — it was just created from the Agentic-ALM-Template."

The `setup-client-repo` skill handles the rest interactively.

---

## Manual Steps Reference

If you prefer to configure without the agent, the sections below cover each step.

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
- Environment slugs and URLs (integration, test, prod)
- Package groups (which solutions deploy together)

---

## Step 4: Set Up GitHub Secrets and Variables

### Repository Secrets

| Secret | Description |
|--------|-------------|
| *(none required)* | Secrets are set per GitHub Environment — see below |

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
| `PR_VALIDATION_INTEGRATION_ENV` | Integration environment slug for PR validation builds | `acme-integration` |

---

## Step 5: Configure OIDC Federated Credentials

For each environment's service principal, create a federated credential for GitHub Actions:

```bash
# Audience: api://AzureADTokenExchange
# Subject:  repo:{org}/{repo}:environment:{env-slug}
```

Test OIDC auth using the `test-oidc-auth.yml` workflow.

---

## Step 6: Branch Protection

Configure branch protection rules in GitHub:
- `main`: require PR from `develop` or `hotfix/*` only (enforced by `check-source-branch.yml`)
- `develop`: require PR reviews, no direct pushes for contributors

---

## Step 7: Initialize Submodules

This repo has one submodule:

| Submodule | Repo | Purpose |
|-----------|------|---------|
| `.platform` | `Agentic-ALM-Workflows` | PowerShell scripts, plugin skills, and CI |

Initialize with:

```powershell
.\Initialize-Repo.ps1
```

After init, `.platform/.github/workflows/scripts/` contains all scripts used locally and by GitHub Actions.

## Keeping Platform Assets Updated

Run the same script any time to update:

```powershell
.\Initialize-Repo.ps1
```

This updates `.platform` to the latest `Agentic-ALM-Workflows` main, then reminds you to refresh the plugin. Idempotent — safe to re-run.
