<#
.SYNOPSIS
    Initialize or update a repository created from Agentic-ALM-Template.

.DESCRIPTION
    Run any time to get the repo in sync. Idempotent — safe to re-run.
    Performs in order:
      1. Initializes or updates the .platform git submodule to the latest main
         (scripts + plugin files live here)
      2. Prints plugin install/update instructions for GitHub Copilot and Claude Code

    First run: initializes .platform and walks you through repo setup via the agent.
    Subsequent runs: updates .platform to latest and refreshes the plugin.

.EXAMPLE
    .\Initialize-Repo.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot

# ── Step 1: Initialize or update .platform submodule ─────────────────────────
Write-Host ""
Write-Host "Step 1: Syncing .platform submodule to latest..." -ForegroundColor Cyan

git -C $repoRoot submodule update --init --remote --filter=blob:none

if ($LASTEXITCODE -ne 0) {
    Write-Error "git submodule update failed (exit $LASTEXITCODE)"
    exit $LASTEXITCODE
}

$platformHead = git -C (Join-Path $repoRoot ".platform") rev-parse --short HEAD
Write-Host "  .platform -> $platformHead (Agentic-ALM-Workflows)" -ForegroundColor Green

# ── Step 2: Plugin install / update instructions ──────────────────────────────
Write-Host ""
Write-Host "Step 2: Install or update the ALM skills plugin" -ForegroundColor Cyan
Write-Host ""
Write-Host "  GitHub Copilot (VS Code):" -ForegroundColor Yellow
Write-Host "    VS Code should show a notification — click Install."
Write-Host "    Or: Extensions sidebar (Ctrl+Shift+X) → search '@agentPlugins power-platform-alm' → Install"
Write-Host "    Or: Command Palette (Ctrl+Shift+P) → 'Chat: Install Plugin From Source'"
Write-Host "        Enter: https://github.com/mikefactorial/Agentic-ALM-Workflows"
Write-Host ""
Write-Host "  Claude Code (reads from .platform directly — no reinstall needed):" -ForegroundColor Yellow
Write-Host "    claude --plugin-dir .platform/.github/plugins/power-platform-alm"
Write-Host ""

# ── Step 3: First-time setup prompt ───────────────────────────────────────────
$envConfig = Join-Path $repoRoot "deployments/settings/environment-config.json"
$needsSetup = (Get-Content $envConfig -Raw) -match '\{\{[A-Z_]+\}\}'

if ($needsSetup) {
    Write-Host "Step 3: This repo needs first-time setup" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  After installing the plugin, say this to the agent:" -ForegroundColor Yellow
    Write-Host "    ""Set up this repo — it was just created from the Agentic-ALM-Template."""
    Write-Host ""
    Write-Host "  The setup-client-repo skill will guide you through:" -ForegroundColor DarkGray
    Write-Host "    - environment-config.json" -ForegroundColor DarkGray
    Write-Host "    - Package Deployer project wiring" -ForegroundColor DarkGray
    Write-Host "    - GitHub Environments, secrets, and variables" -ForegroundColor DarkGray
    Write-Host "    - OIDC federated credentials" -ForegroundColor DarkGray
    Write-Host "    - Branch protection rules" -ForegroundColor DarkGray
} else {
    Write-Host "Step 3: Repo already configured — .platform updated to latest" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
