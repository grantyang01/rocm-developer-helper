function Install-OpensshServer {
    Write-Host "Checking OpenSSH availability..." -ForegroundColor Green
    $availableCapabilities = Get-WindowsCapability -Online | Where-Object { $_.Name -like "OpenSSH*" }
    $availableCapabilities
    
    Write-Host "`nChecking currently installed OpenSSH components..." -ForegroundColor Green
    Get-WindowsCapability -Online | Where-Object { $_.State -eq "Installed" } | Select-Object Name, State
    
    Write-Host "`nInstalling OpenSSH Server..." -ForegroundColor Green
    
    # Get the latest OpenSSH Server capability name dynamically
    $sshServerCapability = $availableCapabilities | Where-Object { $_.Name -like "OpenSSH.Server*" } | Select-Object -First 1
    
    if (-not $sshServerCapability) {
        Write-Error "OpenSSH Server capability not found"
        return
    }
    
    Write-Host "Found OpenSSH Server capability: $($sshServerCapability.Name)" -ForegroundColor Cyan
    
    try {
        Add-WindowsCapability -Online -Name $sshServerCapability.Name
        Write-Host "OpenSSH Server installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install OpenSSH Server: $_"
        return
    }
    
    Write-Host "`nStarting SSH service..." -ForegroundColor Green
    Start-Service sshd
    
    Write-Host "Setting SSH service to start automatically..." -ForegroundColor Green
    Set-Service -Name sshd -StartupType 'Automatic'
    
    Write-Host "`nVerifying SSH service is running..." -ForegroundColor Green
    Get-Service sshd
    
    Write-Host "`nAdding firewall rule for SSH (port 22)..." -ForegroundColor Green
    try {
        New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
        Write-Host "Firewall rule added successfully." -ForegroundColor Green
    }
    catch {
        Write-Warning "Firewall rule may already exist or failed to create: $_"
    }
    
    Write-Host "`nFinal verification - Installed OpenSSH components:" -ForegroundColor Green
    Get-WindowsCapability -Online | Where-Object { $_.State -eq "Installed" } | Select-Object Name, State
    
    Write-Host "`nTesting local SSH connection..." -ForegroundColor Green
    Write-Host "Run 'ssh localhost' to test the connection." -ForegroundColor Yellow
}

<#
    # After enabling script execution to manually setup OpenSSH server(in remote machine):
    1. copy folder .ssh to C:\Users\<your-username>\.ssh, or manually set it up from scratch.
    2. copy .ssh\authorized_keys to C:\ProgramData\ssh\administrators_authorized_keys
#>
