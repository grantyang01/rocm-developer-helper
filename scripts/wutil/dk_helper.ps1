. "$PSScriptRoot\tools.ps1"

# Enable Windows virtualization features
function Install-VirtualizationFeatures {
    Write-Host "Enabling Windows virtualization features..." -ForegroundColor Green
    $errors = @()
    
    try {
        # Enable required Windows features for virtualization
        Write-Host "Enabling Hyper-V feature..." -ForegroundColor Yellow
        if (-not (Enable-Feature -FeatureName "Microsoft-Hyper-V-All")) {
            $errors += "Failed to enable Hyper-V feature"
        }
        
        Write-Host "Enabling Containers feature..." -ForegroundColor Yellow  
        if (-not (Enable-Feature -FeatureName "Containers")) {
            $errors += "Failed to enable Containers feature"
        }
        
        Write-Host "Enabling Virtual Machine Platform..." -ForegroundColor Yellow
        if (-not (Enable-Feature -FeatureName "VirtualMachinePlatform")) {
            $errors += "Failed to enable Virtual Machine Platform"
        }
        
    } catch {
        $errors += "Failed to enable Windows features: $($_.Exception.Message)"
    }
    
    if ($errors.Count -gt 0) {
        Write-Error (
            "Virtualization features setup encountered errors:`n" +
            ($errors -join "`n")
        )
        Write-Host "IMPORTANT: A system restart is required to complete virtualization setup." -ForegroundColor Red
        return $false
    }
    Write-Host "Virtualization features enabled successfully!" -ForegroundColor Green
    Write-Host "IMPORTANT: A system restart is required to complete setup." -ForegroundColor Yellow
    return $true
}

# # Install Docker Desktop using Windows Package Manager
# InstallPackage -PackageId 'Docker.DockerDesktop'
