# Conductor API Helper Functions
# Functions for managing Conductor API integration

# Import required modules
. "$PSScriptRoot\tools.ps1"

function Test-ConductorApiKey {
    try {
        $config = Read-Yaml -Path "$PSScriptRoot\config.yaml"
        if (-not $config -or -not $config.conductor) {
            return $null
        }

        if (-not ($config.conductor.api_key)) {
            return $null
        }

        return $config.conductor.api_key
    }
    catch {
        return $null
    }
}

function Install-ConductorPythonPackages {
    try {
        Write-Host "Installing Conductor Python packages..." -ForegroundColor Cyan
        
        # Install Conductor packages from AMD Artifactory
        Write-Host "  Installing at-scale-python-api and amd-conductor-cli from AMD Artifactory..." -ForegroundColor Gray
        $pip3Cmd = "pip3 install at-scale-python-api amd-conductor-cli " +
                   "--extra-index-url https://mkmartifactory.amd.com/artifactory/api/pypi/hw-orc3pypi-prod-local/simple " +
                   "--trusted-host=mkmartifactory.amd.com"
        
        $result = Invoke-Expression $pip3Cmd 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to install Conductor packages: $result"
            return $false
        }

        # Install additional dependencies
        Write-Host "  Installing additional dependencies (argparse, pendulum, prettytable)..." -ForegroundColor Gray
        $pipCmd = "pip install argparse pendulum prettytable"
        $result = Invoke-Expression $pipCmd 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to install additional dependencies: $result"
            return $false
        }

        Write-Host "  All Python packages installed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to install Conductor Python packages: $_"
        return $false
    }
}

function Install-ConductorApi {
    try {
        Write-Host "`n=== Installing Conductor API ===" -ForegroundColor Cyan

        # Step 1: Validate API key
        $apiKey = Test-ConductorApiKey
        if (-not $apiKey) {
            Write-Error "Conductor API key not configured"
            Write-Host "Please configure conductor.api_key in config.local.yaml" -ForegroundColor Yellow
            return $false
        }

        # Step 2: Install Python packages (Conductor + dependencies)
        $success = Install-ConductorPythonPackages
        if (-not $success) {
            Write-Error "Failed to install Conductor Python packages"
            return $false
        }

        return $true
    }
    catch {
        Write-Error "Failed to install Conductor API: $_"
        return $false
    }
}

function New-ConductorReservation {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SystemName,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$StartLocal,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$EndLocal,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Config
    )
    
    $totalHours = ($EndLocal - $StartLocal).TotalHours
    
    if ($totalHours -le 0) {
        Write-Error "End date must be after start date"
        return $false
    }
    
    # Display request summary
    Write-Host "`n=== Reservation Request ===" -ForegroundColor Cyan
    Write-Host "System:   $SystemName" -ForegroundColor White
    Write-Host "Start:    $($StartLocal.ToString('yyyy-MM-dd hh:mm tt'))" -ForegroundColor White
    Write-Host "End:      $($EndLocal.ToString('yyyy-MM-dd hh:mm tt'))" -ForegroundColor White
    Write-Host "Duration: $([math]::Round($totalHours, 1)) hours ($([math]::Round($totalHours/24, 1)) days)" -ForegroundColor White
    Write-Host "Users:    $($Config.users -join ', ')" -ForegroundColor White
    
    # Split into 24-hour chunks
    $reservations = @()
    $current = $StartLocal
    
    while ($current -lt $EndLocal) {
        $potentialEnd = $current.AddHours(24)
        
        # Use the earlier of: 24 hours from now, or the final end date
        if ($potentialEnd -gt $EndLocal) {
            $end = $EndLocal
        } else {
            $end = $potentialEnd
        }
        
        $reservations += @{ Start = $current; End = $end }
        $current = $end
    }
    
    Write-Host "`nCreating $($reservations.Count) reservation(s)..." -ForegroundColor Yellow
    
    # Create reservations
    $successCount = 0
    for ($i = 0; $i -lt $reservations.Count; $i++) {
        $res = $reservations[$i]
        $num = $i + 1
        
        # Convert to UTC
        $startUtc = $res.Start.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.000Z")
        $endUtc = $res.End.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.000Z")
        $milestoneUtc = $res.End.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.000Z")
        
        Write-Host "`n[$num/$($reservations.Count)] $($res.Start.ToString('MM/dd hh:mm tt')) - $($res.End.ToString('MM/dd hh:mm tt')) ($([math]::Round(($res.End - $res.Start).TotalHours, 1))h)" -ForegroundColor Cyan
        
        # Build command arguments
        $cmdArgs = @(
            "reservation", "create",
            "--title", $Config.title,
            "--project", $Config.project,
            "--milestone", $milestoneUtc,
            "-S", $SystemName,
            "--priority", "5"
        )
        
        # Add users
        foreach ($user in $Config.users) {
            $cmdArgs += @("--user", $user)
        }
        
        # Add remaining args
        $cmdArgs += @(
            "--start-date", $startUtc,
            "--end-date", $endUtc,
            "--batch-opt-out", "1",
            "--description", $Config.description,
            "--allocation-team", $Config.allocation_team
        )
        
        # Execute
        $output = & conductor $cmdArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Success" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "✗ Failed: $output" -ForegroundColor Red
        }
    }
    
    # Summary
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    if ($successCount -eq $reservations.Count) {
        Write-Host "All $successCount reservation(s) created successfully!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Created $successCount of $($reservations.Count) reservations" -ForegroundColor Yellow
        return $false
    }
}