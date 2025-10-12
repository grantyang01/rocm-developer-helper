function Check-Property {
    param (
        [string]$PropertyName
    )

    if (-not $PropertyName) {
        Write-Error "PropertyName parameter is required."
        return
    }

    $propertyValue = (Get-ComputerInfo -Property $PropertyName).$PropertyName

    if ($propertyValue -eq $true) {
        Write-Output "$PropertyName is ENABLED."
    }
    elseif ($propertyValue -eq $false) {
        Write-Output "$PropertyName is DISABLED."
    }
    else {
        Write-Output "$PropertyName is not found or unavailable."
    }
}

# Example usage:
# Check-Property -PropertyName "HyperVRequirementVirtualizationFirmwareEnabled"

function Install-Git {
    try {
        Write-Output "Installing Git..."
        winget install --id Git.Git -e --source winget -h -q
        # Verify Git installation
        $gitVersion = git --version
        if ($gitVersion) {
            Write-Output "Git installed successfully: $gitVersion"
        } else {
            throw "Git installation verification failed."
        }
    }
    catch {
        Write-Error "Failed to install Git. Error details: $_"
    }
}

function Install-GitLFS {
    try {
        Write-Output "Installing Git LFS..."
        winget install --id Git.LFS -e --source winget -h -q
        # Verify Git LFS installation
        $gitLfsVersion = git lfs version
        if ($gitLfsVersion) {
            Write-Output "Git LFS installed successfully: $gitLfsVersion"
            Write-Output "Initializing Git LFS..."
            git lfs install
        } else {
            throw "Git LFS installation verification failed."
        }
    }
    catch {
        Write-Error "Failed to install Git LFS. Error details: $_"
    }
}

# Example usage:
# Install-Git
# Install-GitLFS

# Write-Output "Git and Git LFS installation process completed."
