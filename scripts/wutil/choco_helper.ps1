. "$PSScriptRoot\tools.ps1"
function Install-Chocolatey {
    
    try {
        Write-Host "Checking Chocolatey installation..." -ForegroundColor Green

        # Check if Chocolatey is already installed
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Chocolatey is already installed!" -ForegroundColor Yellow
            return $true
        }

        Write-Host "Installing Chocolatey..." -ForegroundColor Green

        # Set execution policy for this process
        Write-Host "Setting execution policy..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force

        # Enable TLS 1.2 for secure downloads
        Write-Host "Configuring security protocol..." -ForegroundColor Yellow
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

        # Download and execute Chocolatey installation script
        Write-Host "Downloading and installing Chocolatey..." -ForegroundColor Yellow
        $installScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
        Invoke-Expression $installScript

        Write-Host "Chocolatey installation completed!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to install Chocolatey: $($_.Exception.Message)"
        return $false
    }
}

# Install Chocolatey
# Install-Chocolatey

