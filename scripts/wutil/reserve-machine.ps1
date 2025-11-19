#!/usr/bin/env pwsh
# Simple machine reservation tool for Conductor
#
# Usage:
#   reserve-machine.ps1 -SystemName "hostname"           # Check availability
#   reserve-machine.ps1 -SystemName "hostname" -Reserve  # Create reservation

param(
    [Parameter(Mandatory=$true)]
    [string]$SystemName,
    
    [Parameter(Mandatory=$false)]
    [switch]$Reserve,
    
    [Parameter(Mandatory=$false)]
    [int]$Days = 3,
    
    [Parameter(Mandatory=$false)]
    [string]$StartDate,
    
    [Parameter(Mandatory=$false)]
    [string]$Title = "SHISA Development"
)

# Import tools to read config
. "$PSScriptRoot\tools.ps1"

# Setup environment variables from config
try {
    $config = Read-Yaml -Path "$PSScriptRoot\config.yaml"
    if (-not $config -or -not $config.conductor) {
        Write-Error "Conductor configuration not found in config.yaml"
        exit 1
    }
    
    $apiKey = $config.conductor.api_key
    if (-not $apiKey) {
        Write-Error "Conductor API key not configured in config.local.yaml"
        exit 1
    }
    
    $email = $config.devtools.git.git_email
    if (-not $email) {
        $email = "grant.yang@amd.com"
    }
    
    $env:ATS_SECRET = $apiKey
    $env:AMD_EMAIL = $email
}
catch {
    Write-Error "Failed to load configuration: $_"
    exit 1
}

Write-Host "`n=== Conductor Machine Reservation Tool ===" -ForegroundColor Cyan
Write-Host "System: $SystemName" -ForegroundColor Green

# Step 1: Find the system
Write-Host "`nSearching for system '$SystemName'..." -ForegroundColor Cyan
$systemList = conductor list system --num 500 --json-output 2>$null | ConvertFrom-Json

if (-not $systemList) {
    Write-Error "Failed to retrieve system list"
    exit 1
}

$system = $systemList | Where-Object { $_.name -like "*$SystemName*" -or $_.hostname -like "*$SystemName*" } | Select-Object -First 1

if (-not $system) {
    Write-Error "System '$SystemName' not found"
    Write-Host "`nTip: List all systems with: conductor list system --num 50" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found system:" -ForegroundColor Green
Write-Host "  ID: $($system.id)" -ForegroundColor White
Write-Host "  Name: $($system.name)" -ForegroundColor White
Write-Host "  Hostname: $($system.hostname)" -ForegroundColor White
Write-Host "  Pool: $($system.pool.name)" -ForegroundColor White

# Step 2: Check current reservations
Write-Host "`nChecking reservations..." -ForegroundColor Cyan
$allReservations = conductor list reservation --num 100 --json-output 2>$null | ConvertFrom-Json

if ($allReservations) {
    $systemReservations = $allReservations | Where-Object { $_.system.id -eq $system.id }
    
    if ($systemReservations) {
        Write-Host "Current/Upcoming Reservations:" -ForegroundColor Yellow
        foreach ($res in $systemReservations) {
            $start = [DateTime]::Parse($res.start_date)
            $end = [DateTime]::Parse($res.end_date)
            $now = Get-Date
            
            $status = if ($now -ge $start -and $now -le $end) { "ACTIVE" } 
                     elseif ($now -lt $start) { "UPCOMING" }
                     else { "PAST" }
            
            if ($status -ne "PAST") {
                Write-Host "  [$status] $($res.title)" -ForegroundColor $(if ($status -eq "ACTIVE") { "Red" } else { "Yellow" })
                Write-Host "    User: $($res.user.user_name)" -ForegroundColor Gray
                Write-Host "    Start: $($start.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
                Write-Host "    End: $($end.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
            }
        }
    }
    else {
        Write-Host "No active or upcoming reservations - System is available!" -ForegroundColor Green
    }
}

# Step 3: Create reservation if requested
if ($Reserve) {
    Write-Host "`nCreating reservation..." -ForegroundColor Cyan
    
    # Calculate dates
    if (-not $StartDate) {
        $start = Get-Date
    }
    else {
        $start = [DateTime]::Parse($StartDate)
    }
    
    $end = $start.AddDays($Days)
    
    $startStr = $start.ToString("yyyy-MM-ddTHH:mm:ss")
    $endStr = $end.ToString("yyyy-MM-ddTHH:mm:ss")
    
    Write-Host "Reservation details:" -ForegroundColor Cyan
    Write-Host "  Title: $Title" -ForegroundColor White
    Write-Host "  Start: $startStr" -ForegroundColor White
    Write-Host "  End: $endStr" -ForegroundColor White
    Write-Host "  Duration: $Days days" -ForegroundColor White
    
    $response = Read-Host "`nConfirm reservation? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "Reservation cancelled" -ForegroundColor Yellow
        exit 0
    }
    
    try {
        $result = conductor reservation create `
            --title $Title `
            --project "SHISA" `
            --milestone "Development" `
            -S $system.id `
            --priority 5 `
            --user "gryang" `
            --start-date $startStr `
            --end-date $endStr `
            --batch-opt-out 1 `
            --description "SHISA development work on $SystemName" `
            --allocation-team "Graphics" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`nReservation created successfully!" -ForegroundColor Green
        }
        else {
            Write-Error "Failed to create reservation: $result"
        }
    }
    catch {
        Write-Error "Error creating reservation: $_"
    }
}
else {
    Write-Host "`nTo reserve this machine, run:" -ForegroundColor Cyan
    Write-Host "  reserve-machine.ps1 -SystemName '$SystemName' -Reserve -Days $Days" -ForegroundColor White
}

Write-Host ""

