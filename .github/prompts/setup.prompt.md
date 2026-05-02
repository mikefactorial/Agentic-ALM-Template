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

## Step 3: Install or Update the ALM Skills Plugin

The `power-platform-alm` plugin is recommended by this workspace. VS Code should show a notification — click **Install** if it appears.

If the plugin is already installed, it may be out of date. Run this command first to force-refresh all installed plugins to their latest versions:

**Command Palette (`Ctrl+Shift+P`) → `Chat: Update Plugins (Force)`**

If no notification appears and the plugin is not yet installed:

**Option A — Extensions sidebar:**
1. Open Extensions (`Ctrl+Shift+X`)
2. Search `@agentPlugins power-platform-alm`
3. Click Install

**Option B — Command Palette:**
1. `Ctrl+Shift+P` → `Chat: Install Plugin From Source`
2. Enter `https://github.com/mikefactorial/Agentic-ALM-Workflows`

Wait for the user to confirm the plugin is installed (or updated) before continuing.

## Step 4: Run Setup

Once the plugin is installed, say:

> "Set up this repo"

The `setup-client-repo` skill will guide you through filling in `environment-config.json`, creating GitHub environments and variables, configuring OIDC credentials, and setting up branch protection.
