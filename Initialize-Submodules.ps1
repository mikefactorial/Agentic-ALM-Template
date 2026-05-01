<#
.SYNOPSIS
    Low-level submodule init. Prefer .\Initialize-Repo.ps1 for normal use.

.DESCRIPTION
    Initializes all git submodules with the correct sparse-checkout configuration.
    Use Initialize-Repo.ps1 instead — it handles init, update, and plugin instructions.
    Use this script only when you want submodule init without the full setup flow.

.EXAMPLE
    .\Initialize-Submodules.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot

Write-Host "Initializing submodules..." -ForegroundColor Cyan

# Initialize .platform submodule with partial clone filter (no blobs until needed)
git -C $repoRoot submodule update --init --filter=blob:none

if ($LASTEXITCODE -ne 0) {
    Write-Error "git submodule update failed (exit $LASTEXITCODE)"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Done. Submodule initialized:" -ForegroundColor Green
Write-Host "  .platform  -> $(git -C (Join-Path $repoRoot '.platform') rev-parse --short HEAD) (Agentic-ALM-Workflows)" -ForegroundColor Green
Write-Host ""
