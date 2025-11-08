. "$PSScriptRoot\tools.ps1"

# Enable Windows virtualization features
function Install-VirtualizationFeatures {
    param (
        [Parameter(Mandatory = $true)]
        [ref]$RestartRequired
    )
    
    Write-Host "Enabling Windows virtualization features..." -ForegroundColor Green
    $RestartRequired.Value = $false
    try {
        # Track if any features were actually installed (requiring restart)
        $hypervInstalled = $false
        $containersInstalled = $false
        $vmInstalled = $false
        
        # Enable Hyper-V feature
        $hypervSuccess = Enable-Feature -FeatureName "Microsoft-Hyper-V-All" -WasInstalled ([ref]$hypervInstalled)
        if (-not $hypervSuccess) {
            Write-Error "Failed to enable Hyper-V feature"
            return $false
        }
    } catch {
        Write-Error "Failed to enable Hyper-V feature: $($_.Exception.Message)"
        return $false
    }

    try {
        # Enable Containers feature
        $containersSuccess = Enable-Feature -FeatureName "Containers" -WasInstalled ([ref]$containersInstalled)
        if (-not $containersSuccess) {
            Write-Error "Failed to enable Containers feature"
            return $false
        }
    } catch {
        Write-Error "Failed to enable Containers feature: $($_.Exception.Message)"
        return $false
    }

    try {
        # Enable Virtual Machine Platform
        $vmSuccess = Enable-Feature -FeatureName "VirtualMachinePlatform" -WasInstalled ([ref]$vmInstalled)
        if (-not $vmSuccess) {
            Write-Error "Failed to enable Virtual Machine Platform"
            return $false
        }
    } catch {
        Write-Error "Failed to enable Virtual Machine Platform: $($_.Exception.Message)"
        return $false
    }
    
    Write-Host "Virtualization features enabled successfully!" -ForegroundColor Green
    
    # Set RestartRequired if any features were actually installed
    if ($hypervInstalled -or $containersInstalled -or $vmInstalled) {
        $RestartRequired.Value = $true
        Write-Host "IMPORTANT: Virtualization features were installed. A system restart is required to complete setup." -ForegroundColor Yellow
    } else {
        Write-Host "All virtualization features were already enabled - no restart required." -ForegroundColor Green
    }
    
    return $true
}

# Usage example:
# $restartRequired = $false
# $success = Install-VirtualizationFeatures -RestartRequired ([ref]$restartRequired)
# if ($success -and $restartRequired) { Restart-Computer -Force }

