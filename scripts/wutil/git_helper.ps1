. "$PSScriptRoot\tools.ps1"

function Configure-Git {
    try {
        # Read configuration from YAML
        $config = Read-Yaml -Path "$PSScriptRoot\config.yaml"
        if (-not $config) {
            Write-Error "Failed to load Git configuration from: $PSScriptRoot\config.yaml"
            return $false
        }
        
        # Get Git config values
        $UserName = $config.devtools.git.user_name
        $GitEmail = $config.devtools.git.git_email
        
        if (-not $UserName -or -not $GitEmail) {
            Write-Error "Configuration file must contain devtools.git.user_name and devtools.git.git_email"
            return $false
        }
        
        Write-Host "Configuring Git..." -ForegroundColor Cyan
        Write-Host "  User: $UserName"
        Write-Host "  Email: $GitEmail"
        
        # Configure Git global settings
        git config --global user.name $UserName
        git config --global user.email $GitEmail
        
        Write-Host "Git configured successfully!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to configure Git: $($_.Exception.Message)"
        return $false
    }
}
