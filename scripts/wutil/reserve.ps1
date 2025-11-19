#!/usr/bin/env pwsh
# Simple Conductor machine reservation tool
# Reserves all systems configured in config.local.yaml
# Automatically splits reservations > 24 hours into consecutive 24h chunks
#
# Usage:
#   reserve.ps1 "2025-11-30 11:00 AM" "2025-12-01 11:00 AM"
#   reserve.ps1 "2025-11-20 2:00 PM" "7d"                    # 7 days from start
#   reserve.ps1 "2025-12-01 14:00" "48h"                     # 48 hours from start
#
# Date format examples:
#   "2025-11-30 11:00 AM"  (recommended)
#   "11/30/2025 2:30 PM"
#   "2025-11-30 14:00"     (24-hour format)
#
# Duration format examples:
#   "7d"    - 7 days
#   "12h"   - 12 hours
#   "2.5d"  - 2.5 days (60 hours)

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$StartDate,
    
    [Parameter(Mandatory=$true, Position=1)]
    [string]$EndDate
)

# Import helpers
. "$PSScriptRoot\tools.ps1"
. "$PSScriptRoot\conductor_helper.ps1"

# Load configuration
$config = Read-Yaml -Path "$PSScriptRoot\config.yaml"
$env:ATS_SECRET = $config.conductor.api_key
$env:AMD_EMAIL = $config.devtools.git.git_email

# Parse and validate start date
try {
    $startLocal = [DateTime]::Parse($StartDate)
}
catch {
    Write-Error "Invalid start date format: '$StartDate'"
    Write-Host "`nCorrect format examples:" -ForegroundColor Yellow
    Write-Host "  2025-11-30 11:00 AM" -ForegroundColor White
    Write-Host "  2025-12-01 2:30 PM" -ForegroundColor White
    Write-Host "  11/30/2025 9:00 AM" -ForegroundColor White
    Write-Host "  2025-11-30 14:00" -ForegroundColor White
    exit 1
}

# Parse end date (either absolute date or duration)
$endLocal = $null

# Check if it's a duration format (e.g., "7d", "12h", "2.5d")
if ($EndDate -match '^(\d+\.?\d*)([dh])$') {
    $value = [double]$Matches[1]
    $unit = $Matches[2]
    
    if ($unit -eq 'd') {
        # Days
        $endLocal = $startLocal.AddDays($value)
        Write-Host "Duration: $value days (until $($endLocal.ToString('yyyy-MM-dd hh:mm tt')))" -ForegroundColor Cyan
    }
    elseif ($unit -eq 'h') {
        # Hours
        $endLocal = $startLocal.AddHours($value)
        Write-Host "Duration: $value hours (until $($endLocal.ToString('yyyy-MM-dd hh:mm tt')))" -ForegroundColor Cyan
    }
}
else {
    # Try parsing as absolute date
    try {
        $endLocal = [DateTime]::Parse($EndDate)
    }
    catch {
        Write-Error "Invalid end date/duration format: '$EndDate'"
        Write-Host "`nAbsolute date examples:" -ForegroundColor Yellow
        Write-Host "  2025-12-05 5:00 PM" -ForegroundColor White
        Write-Host "  2025-12-01 18:30" -ForegroundColor White
        Write-Host "  12/05/2025 6:00 PM" -ForegroundColor White
        Write-Host "`nDuration examples:" -ForegroundColor Yellow
        Write-Host "  7d     - 7 days" -ForegroundColor White
        Write-Host "  12h    - 12 hours" -ForegroundColor White
        Write-Host "  2.5d   - 2.5 days (60 hours)" -ForegroundColor White
        exit 1
    }
}

# Validate date range
if ($endLocal -le $startLocal) {
    Write-Error "End date must be after start date"
    Write-Host "  Start: $($startLocal.ToString('yyyy-MM-dd hh:mm tt'))" -ForegroundColor Yellow
    Write-Host "  End:   $($endLocal.ToString('yyyy-MM-dd hh:mm tt'))" -ForegroundColor Yellow
    exit 1
}

# Get systems from config
$reservationConfig = $config.conductor.reservation
$systems = $reservationConfig.systems

if (-not $systems -or $systems.Count -eq 0) {
    Write-Error "No systems configured in config.local.yaml under conductor.reservation.systems"
    exit 1
}

Write-Host "`n=== Reserving $($systems.Count) System(s) ===" -ForegroundColor Cyan
foreach ($system in $systems) {
    Write-Host "`n>>> System: $system <<<" -ForegroundColor Magenta
}

# Create reservations for all systems
$overallSuccess = $true
foreach ($system in $systems) {
    $params = @{
        SystemName = $system
        StartLocal = $startLocal
        EndLocal = $endLocal
        Config = $reservationConfig
    }
    
    $success = New-ConductorReservation @params
    
    if (-not $success) {
        $overallSuccess = $false
    }
}

# Overall summary
Write-Host "`n=== Overall Result ===" -ForegroundColor Cyan
if ($overallSuccess) {
    Write-Host "All systems reserved successfully!" -ForegroundColor Green
} else {
    Write-Host "Some reservations failed. Check output above." -ForegroundColor Yellow
}
