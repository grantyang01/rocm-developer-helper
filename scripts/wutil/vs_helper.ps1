#!/usr/bin/env pwsh
# Visual Studio Helper Functions

. "$PSScriptRoot\tools.ps1"

function Install-VisualStudio {
    param(
        [Parameter(Mandatory=$false)]
        [bool]$UnattendedInstall = $false
    )
    
    try {
        Write-Host "Installing VisualStudio 2022 Community..." -ForegroundColor Cyan
        
        # Read configuration
        $config = Read-Yaml -Path "$PSScriptRoot\config.yaml"
        
        # Build Visual Studio component options from config
        $vsComponents = $config.devtools.visualstudio.components
        $vsOverrideOptions = ($vsComponents | ForEach-Object { "--add $_" }) -join " "
        $vsOverrideOptions += " --includeRecommended --wait"
        
        # Add quiet flag for unattended install
        if ($UnattendedInstall) {
            $vsOverrideOptions += " --quiet"
        }

        InstallPackage -PackageId 'Microsoft.VisualStudio.2022.Community' `
                       -OverrideOptions $vsOverrideOptions

        # Refresh PATH to make dotnet available immediately
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + `
                    [System.Environment]::GetEnvironmentVariable("Path", "User")

        # Add source globally
        Write-Host "Configuring NuGet sources..." -ForegroundColor Cyan
        $existingSources = dotnet nuget list source 2>$null | Out-String
        if ($existingSources -notmatch 'nuget\.org') {
            dotnet nuget add source https://api.nuget.org/v3/index.json --name nuget.org 2>&1
        }
        
        Write-Host "Visual Studio 2022 installation completed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install Visual Studio: $_"
        throw
    }
}

