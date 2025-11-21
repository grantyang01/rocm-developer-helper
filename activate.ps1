#!/usr/bin/env pwsh
# RDH Environment Activation Script
# Adds RDH scripts directories to User PATH permanently and activates for current session
#
# Usage:
#   . .\activate.ps1

# Get RDH root directory (where this script is located)
$RDH_ROOT = $PSScriptRoot

# Define directories to add to PATH
$wutilDir = Join-Path $RDH_ROOT "scripts\wutil"

# Source tools.ps1 for Add-PathEntry function
. "$wutilDir\tools.ps1"

Add-PathEntry -PathToAdd $wutilDir -Scope 'User'
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + `
            [System.Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "`nRDH environment activated!" -ForegroundColor Green

