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

function Is-PackageInstalled {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )
    try {
        $listOutput = winget list --id $PackageId --accept-source-agreements
        if ($listOutput -match "No installed package found matching input criteria.") {
            return $false
        }
        else {
            return $true
        }
    }
    catch {
        Write-Warning "Failed to check package installed status for '$PackageId'. Error: $($_.Exception.Message)"
        return $false
    }
}

function Is-PackageAvailable {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )
    try {
        $searchOutput = winget search $PackageId --accept-source-agreements
        if ($searchOutput -match "Version") {
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        Write-Warning "Error checking package availability for '$PackageId': $($_.Exception.Message)"
        return $false
    }
}

function Install-Package {
    param (
        [Parameter(Mandatory = $true)][string]$PackageId,
        [scriptblock]$VerifyCommand = $null
    )
    try {
        if (Is-PackageInstalled -PackageId $PackageId) {
            Write-Output "Package '$PackageId' is already installed."
            return $true
        }
        if (-not (Is-PackageAvailable -PackageId $PackageId)) {
            Write-Error "Package '$PackageId' is not available remotely."
            return $false
        }
        Write-Output "Installing package '$PackageId'..."
        winget install --id $PackageId -e --source winget -h --accept-source-agreements --accept-package-agreements
        Write-Output "Verifying installation of '$PackageId'..."
        $version = if ($VerifyCommand) { & $VerifyCommand } else { winget list --accept-source-agreements | Out-String }
        if (-not $version) { throw "Verification failed." }
        Write-Output "'$PackageId' installed successfully: $version"
        if ($PackageId -eq 'GitHub.GitLFS') {
            Write-Output "Initializing Git LFS..."
            git lfs install
        }
        return $true
    }
    catch {
        Write-Error "Failed to install package '$PackageId': $($_.Exception.Message)"
        return $false
    }
}

function Uninstall-Package {
    param ([Parameter(Mandatory = $true)][string]$PackageId)
    try {
        if (-not (Is-PackageInstalled -PackageId $PackageId)) {
            Write-Output "Package '$PackageId' is not installed. Skipping uninstall."
            return $true
        }
        Write-Output "Uninstalling package '$PackageId'..."
        winget uninstall --id $PackageId -e --source winget -h --accept-source-agreements
        Write-Output "'$PackageId' uninstalled successfully."
        return $true
    }
    catch {
        Write-Error "Failed to uninstall package '$PackageId': $($_.Exception.Message)"
        return $false
    }
}

# Example usage:

# Install Git
Install-Package -PackageId 'Git.Git' -VerifyCommand { git --version }

# Install Git LFS
Install-Package -PackageId 'GitHub.GitLFS' -VerifyCommand { git lfs version }

# Uninstall Git
Uninstall-Package -PackageId 'Git.Git'

# Uninstall Git LFS
Uninstall-Package -PackageId 'GitHub.GitLFS'
