. "$PSScriptRoot\tools.ps1"

# Install Evince in WSL (private helper function)
function Install-Evince {
    try {
        Write-Host "Installing Evince in WSL..."
        wsl sudo apt update
        wsl sudo apt install evince -y
        Write-Host "Evince installed successfully!"
        return $true
    } catch {
        Write-Error "Failed to install Evince: $($_.Exception.Message)"
        return $false
    }
    return $true
}

function Install-WslFeatures {
    try {
        # Ensure WSL feature is enabled
        Enable-Feature -FeatureName "Microsoft-Windows-Subsystem-Linux"
    } catch {
        Write-Error "Failed to enable WSL feature: $($_.Exception.Message)"
        return $false
    }

    try {
        # Ensure Virtual Machine Platform feature is enabled
        Enable-Feature -FeatureName "VirtualMachinePlatform"
    } catch {
        Write-Error "Failed to enable Virtual Machine Platform: $($_.Exception.Message)"
        return $false
    }
    
    Write-Host "WSL features enabled successfully." -ForegroundColor Green
    Write-Host "IMPORTANT: A system restart is required to complete WSL setup." -ForegroundColor Yellow
    return $true
}

function Install-Wsl {
    param (
        [string]$ConfigPath = "$PSScriptRoot\wsl_config.yaml"
    )
    
    # Read configuration from YAML file
    $config = Read-Yaml -Path $ConfigPath
    if (-not $config) {
        Write-Error "Failed to load WSL configuration from: $ConfigPath"
        return $false
    }
    
    # Get values from config file (required)
    $DistroName = $config.wsl.distro_name
    $UserName = $config.wsl.user_name
    $GitEmail = $config.wsl.git_email
    
    if (-not $DistroName -or -not $UserName -or -not $GitEmail) {
        Write-Error "Configuration file must contain wsl.distro_name, wsl.user_name, and wsl.git_email"
        return $false
    }
    
    Write-Host "WSL Configuration loaded:"
    Write-Host "  Distro: $DistroName"
    Write-Host "  User: $UserName"
    Write-Host "  Git Email: $GitEmail"

    try {
        # Install WSL2 kernel update
        Write-Host "Installing WSL2 kernel update..."
        wsl --update
    } catch {
        Write-Error "Failed to update WSL2 kernel: $($_.Exception.Message)"
        return $false
    }

    try {
        # Set WSL2 as default
        Write-Host "Setting WSL2 as default version..."
        wsl --set-default-version 2
    } catch {
        Write-Error "Failed to set WSL2 as default: $($_.Exception.Message)"
        return $false
    }

    try {
        # Install specified distro
        Write-Host "Installing $DistroName..."
        wsl --install -d $DistroName --no-launch
        
        # Wait for installation to complete
        Write-Host "Waiting for distro installation to complete..."
        Start-Sleep -Seconds 10
        
        # Create and configure user with all Add-User functionality
        Write-Host "Creating user '$UserName' in WSL $DistroName and enabling passwordless sudo..."
        
        # Create user with home directory and bash shell
        wsl -d $DistroName -u root -- bash -c "useradd -m -s /bin/bash $UserName"
        
        # Set password (same as username for simplicity)
        wsl -d $DistroName -u root -- bash -c "echo '${UserName}:${UserName}' | chpasswd"
        
        # Add user to sudo group
        wsl -d $DistroName -u root -- bash -c "usermod -aG sudo $UserName"
        
        # Configure passwordless sudo for the user
        $sudoersLine = "$UserName ALL=(ALL) NOPASSWD:ALL"
        wsl -d $DistroName -u root -- bash -c "echo '$sudoersLine' > /etc/sudoers.d/$UserName && chmod 440 /etc/sudoers.d/$UserName"
        
        # Add source command to ~/.bashrc
        wsl -d $DistroName -u root -- bash -c "echo 'source /mnt/c/work/rdh/activate' >> /home/$UserName/.bashrc"
        
        # Copy SSH keys from Windows user to WSL user
        Write-Host "Copying SSH keys from Windows user to WSL user..."
        $windowsSSHPath = "/mnt/c/Users/$env:USERNAME/.ssh"
        wsl -d $DistroName -u root -- bash -c "if [ -d '$windowsSSHPath' ]; then mkdir -p /home/$UserName/.ssh && cp -r $windowsSSHPath/* /home/$UserName/.ssh/ && chown -R $UserName`:$UserName /home/$UserName/.ssh && chmod 700 /home/$UserName/.ssh && chmod 600 /home/$UserName/.ssh/* && echo 'SSH keys copied and permissions set to 600 for all files'; else echo 'No SSH keys found in Windows user directory'; fi"
        
        # Configure Git user name and email
        Write-Host "Configuring Git user settings..."
        wsl -d $DistroName -u $UserName -- bash -c "git config --global user.name '$UserName' && git config --global user.email '$GitEmail' && echo 'Git configured with user: $UserName <$GitEmail>'"
        
        # Set the default user for future launches
        wsl -d $DistroName -u root -- bash -c "echo '[user]' >> /etc/wsl.conf && echo 'default=$UserName' >> /etc/wsl.conf"
        
        # Restart the distro to apply wsl.conf changes
        wsl --terminate $DistroName
        
        Write-Host "$DistroName installed and user '$UserName' created with passwordless sudo access and ~/.bashrc updated."
    } catch {
        Write-Error "Failed to install $DistroName and configure user: $($_.Exception.Message)"
        return $false
    }

    # Install Evince after user creation
    try {
        Install-Evince
    } catch {
        Write-Error "Failed to install Evince: $($_.Exception.Message)"
        return $false
    }

    Write-Host "WSL with $DistroName installation complete."
    return $true
}

# Usage examples:
# pre-requirement: run as administrator
# Install-WslFeatures

# Install-Wsl                                    # Uses wsl_config.yaml
# Install-Wsl -ConfigPath "custom_config.yaml"  # Use different config file
