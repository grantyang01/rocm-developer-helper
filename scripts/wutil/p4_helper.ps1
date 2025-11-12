#!/usr/bin/env pwsh

. "$PSScriptRoot\tools.ps1"

function Set-P4Config {
    $yamlPath = "$PSScriptRoot\config.yaml"
    $config = Read-Yaml -Path $yamlPath
    
    if (-not $config) {
        return $false
    }
    
    if (-not $config.devtools.p4) {
        Write-Warning "P4 configuration not found in config.yaml"
        return $true
    }

    $p4Config = $config.devtools.p4
    
    Write-Host "Configuring Perforce (P4) settings..." -ForegroundColor Cyan
    
    if ($p4Config.port) {
        Write-Host "  Setting P4PORT: $($p4Config.port)" -ForegroundColor Gray
        p4 set P4PORT=$($p4Config.port)
    }
    
    if ($p4Config.user) {
        Write-Host "  Setting P4USER: $($p4Config.user)" -ForegroundColor Gray
        p4 set P4USER=$($p4Config.user)
    }
    
    if ($p4Config.client) {
        Write-Host "  Setting P4CLIENT: $($p4Config.client)" -ForegroundColor Gray
        p4 set P4CLIENT=$($p4Config.client)
    }

    # Verify connection (if on network)
    Write-Host "Verifying P4 connection..." -ForegroundColor Cyan
    p4 info 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "P4 configuration successful!" -ForegroundColor Green
        return $true
    } else {
        Write-Warning "P4 configured but connection test failed. You may need to be on VPN."
        Write-Host "P4 settings have been saved and will work when connected to the network." -ForegroundColor Yellow
        return $true
    }
}

