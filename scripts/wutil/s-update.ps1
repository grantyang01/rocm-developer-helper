#!/usr/bin/env pwsh
# SHISA Update Script
# Syncs SHISA from Perforce, builds, and packages source
#
# Usage:
#   s-update.ps1               # Full: source + binaries (for non-P4 Linux)
#   s-update.ps1 -BinariesOnly # Just binaries (for Linux with P4 workspace)

param(
    [switch]$BinariesOnly
)

. "$PSScriptRoot\shisa_helper.ps1"
. "$PSScriptRoot\update_shisa_src.ps1"

$originalDir = Get-Location
try {
    # Read SHISA root from config
    $config = Read-Yaml -Path "$PSScriptRoot\config.yaml"
    if (-not $config -or -not $config.SHISA -or -not $config.SHISA.SHISA) {
        throw "Failed to read SHISA path from config.yaml"
    }
    $shisaRoot = $config.SHISA.SHISA
    
    # Change to SHISA root directory
    Push-Location $shisaRoot
    
    # Sync SHISA source code from Perforce
    Write-Host "Syncing SHISA from Perforce..." -ForegroundColor Cyan
    & p4 sync ...
    
    # Invoke local SHISA setup to build the code
    Write-Host "Building SHISA..." -ForegroundColor Cyan
    Invoke-ShisaSetup
    
    # Get SHISA code and binaries from the build directory
    Write-Host "Getting SHISA code and binaries..." -ForegroundColor Cyan
    Get-ShisaSrc -BinariesOnly:$BinariesOnly
}
finally {
    Set-Location $originalDir
}