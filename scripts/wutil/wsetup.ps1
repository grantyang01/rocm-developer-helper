# Import existing helper modules
. "$PSScriptRoot\vm_helper.ps1"
. "$PSScriptRoot\wsl_helper.ps1"
. "$PSScriptRoot\ssh_helper.ps1"
. "$PSScriptRoot\choco_helper.ps1"
. "$PSScriptRoot\devsetup_helper.ps1"
. "$PSScriptRoot\hipsdk_helper.ps1"
. "$PSScriptRoot\gi_helper.ps1"
. "$PSScriptRoot\shisa_helper.ps1"

function Initialize-WindowsDevEnvironment {

    # Check if running as administrator
    if (!(Test-Administrator)) {
        Write-Error "This script requires administrator privileges. Please run PowerShell as Administrator."
        return $false
    }

    # Read configuration
    $configPath = Join-Path $PSScriptRoot "config.yaml"
    $config = Read-Yaml -Path $configPath
    if (!$config) {
        Write-Error "Failed to read configuration from $configPath"
        return $false
    }
    
    # Install virtualization features if enabled
    if ($config.virtualization.enable) {
        Write-Host "Setting up virtualization features..." -ForegroundColor Cyan
        $vmRestartRequired = $false
        $success = Install-VirtualizationFeatures -RestartRequired ([ref]$vmRestartRequired)
        if (!$success) {
            Write-Error "Failed to setup virtualization features."
            return $false
        }
    }
    
    # Install WSL features if enabled
    if ($config.wsl.enable) {
        Write-Host "Setting up WSL features..." -ForegroundColor Cyan
        $wslRestartRequired = $false
        $success = Install-WslFeatures -RestartRequired ([ref]$wslRestartRequired)
        if (!$success) {
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
        if (!$success) {
            Write-Error "Failed to install WSL distribution."
            return $false
        }
    }
    
    # Install SSH server if enabled
    if ($config.ssh.enable) {
        Write-Host "Installing SSH server..." -ForegroundColor Cyan
        $success = Install-OpensshServer
        if (!$success) {
            Write-Error "Failed to install SSH server."
            return $false
        }
    }
    
    # Install Chocolatey if enabled
    if ($config.chocolatey.enable) {
        Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
        $success = Install-Chocolatey
        if (!$success) {
            Write-Error "Failed to install Chocolatey."
            return $false
        }
    }

    # Install development tools if enabled
    if ($config.devtools.enable) {
        Write-Host "Installing development tools..." -ForegroundColor Cyan
        $success = Install-DevelopmentTools
        if (!$success) {
            Write-Error "Failed to install Chocolatey."
            return $false
        }
    }

    # Install HIP SDK if enabled, shisa dependency
    if ($config.hipsdk.enable) {
        Write-Host "Installing HIP SDK..." -ForegroundColor Cyan
        $success = InstallHipSdk
        if (-not $success) {
            Write-Error "Failed to install HIP SDK."
            return $false
        }
    }
    
    # Install SHISA tools if enabled
    if ($config.shisa.enable) {
        Write-Host "Installing SHISA tools..." -ForegroundColor Cyan
        $success = Install-ShisaTools
        if (!$success) {
            Write-Error "Failed to install SHISA tools."
            return $false
        }

        # Set SHISA environment variables
        Write-Host "Setting SHISA environment variables..." -ForegroundColor Cyan
        $success = Set-ShisaEnvVars
        if (!$success) {
            Write-Error "Failed to set SHISA environment variables."
            return $false
        }

        # Run SHISA setup script
        Write-Host "Running SHISA setup script..." -ForegroundColor Cyan
        Invoke-ShisaSetup
        if ($LASTEXITCODE -ne 0) {
            Write-Error "SHISA setup failed."
            return $false
        }
    }
    
    # Build GPU Interface from source if enabled (after SHISA setup to overwrite pre-built binaries)
    if ($config.gpu_interface.enable) {
        $success = Install-GpuInterface
        if (-not $success) {
            Write-Warning "GPU Interface build failed, using pre-built binaries from SHISA setup."
        }
    }

    return $true
}

Install-GpuInterface
#Initialize-WindowsDevEnvironment
