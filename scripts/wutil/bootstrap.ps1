<#
    # Before running this script:
    # Enable PowerShell script execution by running ONE of these commands as Administrator:
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

    # After running this script:
    # To enable the new PowerShell
    #   1. reopen windows Terminal
    #   2. In windows Terminal settings(ctrl+,)->Strartup->Default profile: [Dropdown ▼]:
    #       choose "PowerShell" instead of "Windows PowerShell"
    #   3. reopen Windows Terminal.

    # Usage examples:
    # .\bootstrap.ps1  # Uses default path c:\work
    # .\bootstrap.ps1 -WorkPath "D:\dev"
    # .\bootstrap.ps1 "D:\projects"
#>

param(
    [string]$InputPath = "c:\work"
)

function Initialize-Bootstrap {
    param(
        [string]$WorkPath
    )
    
    try {
        # install git if not available
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Host "Installing Git..." -ForegroundColor Yellow
            winget install Git.Git
            $env:Path += ";C:\Program Files\Git\cmd"
        }

        # check out bootstrap: rdh
        if (-not (Test-Path "$WorkPath\rdh")) {
            Write-Host "Creating work directory and cloning repository..." -ForegroundColor Yellow
            New-Item -Path $WorkPath -ItemType Directory -Force | Set-Location
            git clone git@me.github.com:grantyang01/rocm-developer-helper.git rdh
        }
        
        # install PowerShell and powershell-yaml module
        Write-Host "Installing latest PowerShell..." -ForegroundColor Yellow
        winget install Microsoft.PowerShell
        
        Write-Host "Installing powershell-yaml module..." -ForegroundColor Yellow
        Install-Module powershell-yaml -Force -Confirm:$false

        Write-Host "Bootstrap completed successfully!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Bootstrap failed: $($_.Exception.Message)"
        return $false
    }
}

Initialize-Bootstrap -WorkPath $InputPath | Out-Null