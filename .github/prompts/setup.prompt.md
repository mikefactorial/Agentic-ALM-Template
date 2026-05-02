---
mode: agent
description: Bootstrap and configure a new repo created from Agentic-ALM-Template. Checks prerequisites, initializes .platform, installs the ALM plugin, then hands off to the setup-client-repo skill.
---

This repo was created from the Agentic-ALM-Template and needs first-time configuration.

Follow these steps in order:

## Step 1: Initialize .platform

Check if the submodule is ready:

```powershell
Test-Path ".platform/.github/workflows/scripts"
```

If `False` or empty, run:

```powershell
.\Initialize-Repo.ps1
```

Do not continue until `.platform` is populated.

## Step 2: Verify Required Tools

```powershell
$missing = @()
if (-not (Get-Command pac    -ErrorAction SilentlyContinue)) { $missing += 'pac (Power Platform CLI) — https://aka.ms/PowerAppsCLI' }
if (-not (Get-Command gh     -ErrorAction SilentlyContinue)) { $missing += 'gh (GitHub CLI) — https://cli.github.com' }
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { $missing += 'dotnet (.NET SDK) — https://dot.net' }
if ($missing) { Write-Warning "Missing tools:"; $missing | ForEach-Object { Write-Host "  $_" } }
else { Write-Host "All required tools found." -ForegroundColor Green }
```

Also check `gh auth status`. If not authenticated, run `gh auth login`.

## Step 3: Install the ALM Skills Plugin

Tell the user to type the following directly in the Copilot Chat input box and press Enter:

```
/plugin install github:mikefactorial/Agentic-ALM-Workflows
```

> **Note:** This is a Copilot Chat command, not a terminal command. Do not run it in the terminal.

Wait for the user to confirm it ran before continuing.

## Step 4: Run Setup

Once the plugin is installed, say:

> "Set up this repo"

The `setup-client-repo` skill will guide you through filling in `environment-config.json`, creating GitHub environments and variables, configuring OIDC credentials, and setting up branch protection.
