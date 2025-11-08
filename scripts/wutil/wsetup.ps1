# Import existing helper modules
. "$PSScriptRoot\vm_helper.ps1"
. "$PSScriptRoot\wsl_helper.ps1"
. "$PSScriptRoot\choco_helper.ps1"
. "$PSScriptRoot\hipsdk_helper.ps1"
. "$PSScriptRoot\ssh_helper.ps1"
. "$PSScriptRoot\devsetup_helper.ps1"

function Setup-Windows {
    # Read configuration
    $configPath = Join-Path $PSScriptRoot "config.yaml"
    $config = Read-Yaml -Path $configPath
    if (-not $config) {
        Write-Error "Failed to read configuration from $configPath"
        return $false
    }
    
    # Install virtualization features if enabled
    if ($config.virtualization.enable) {
        Write-Host "Setting up virtualization features..." -ForegroundColor Cyan
        $vmRestartRequired = $false
        $success = Install-VirtualizationFeatures -RestartRequired ([ref]$vmRestartRequired)
        if (-not $success) {
            Write-Error "Failed to setup virtualization features."
            return $false
        }
    }
    
    # Install WSL features if enabled
    if ($config.wsl.enable) {
        Write-Host "Setting up WSL features..." -ForegroundColor Cyan
        $wslRestartRequired = $false
        $success = Install-WslFeatures -RestartRequired ([ref]$wslRestartRequired)
        if (-not $success) {
            Write-Error "Failed to setup WSL features."
            return $false
        }
    }
    
    # Check if restart is needed for any component
    if ($vmRestartRequired -or $wslRestartRequired) {
        Write-Host "`nRestart required to complete Windows feature installation." -ForegroundColor Yellow
        $response = Read-Host "Do you want to restart now? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Write-Host "Restarting computer..." -ForegroundColor Red
            Restart-Computer -Force
        } else {
            Write-Error "Setup cannot continue without restart. Please restart and run setup again."
            return $false
        }
    }
    
    # Install WSL distribution if enabled
    if ($config.wsl.enable) {
        Write-Host "Installing WSL distribution..." -ForegroundColor Cyan
        $success = Install-Wsl
        if (-not $success) {
            Write-Error "Failed to install WSL distribution."
            return $false
        }
    }
    
    return $true
}



