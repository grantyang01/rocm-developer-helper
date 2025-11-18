function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    return $isAdmin
}

# Generic function to read YAML file
function Merge-Hashtables {
    param (
        [hashtable]$Base,
        [hashtable]$Override
    )
    
    $result = $Base.Clone()
    
    foreach ($key in $Override.Keys) {
        if ($result.ContainsKey($key) -and $result[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
            # Recursively merge nested hashtables
            $result[$key] = Merge-Hashtables -Base $result[$key] -Override $Override[$key]
        } else {
            # Override value
            $result[$key] = $Override[$key]
        }
    }
    
    return $result
}

function Read-Yaml {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        if (-not (Test-Path $Path)) {
            Write-Error "YAML file not found: $Path"
            return $null
        }
        
        # Import powershell-yaml module if available, otherwise parse manually
        if (Get-Module -ListAvailable -Name powershell-yaml) {
            Import-Module powershell-yaml
            $yamlData = Get-Content $Path | ConvertFrom-Yaml
        } else {
            # Simple YAML parsing for basic key-value pairs
            $yamlData = @{}
            $section = $null
            
            Get-Content $Path | ForEach-Object {
                $line = $_.Trim()
                if ($line -match '^(\w+):$') {
                    $section = $matches[1]
                    $yamlData[$section] = @{}
                } elseif ($line -match '^\s*(\w+):\s*"?([^"]*)"?$') {
                    if ($section) {
                        $yamlData[$section][$matches[1]] = $matches[2]
                    }
                }
            }
        }
        
        # Check for local override file and merge if it exists
        $localPath = $Path -replace '\.yaml$', '.local.yaml'
        if (Test-Path $localPath) {
            if (Get-Module -ListAvailable -Name powershell-yaml) {
                $localData = Get-Content $localPath | ConvertFrom-Yaml
                $yamlData = Merge-Hashtables -Base $yamlData -Override $localData
            } else {
                Write-Warning "config.local.yaml found but requires powershell-yaml module for proper merging"
            }
        }
        
        return $yamlData
    } catch {
        Write-Error "Failed to read configuration file: $($_.Exception.Message)"
        return $null
    }
}

# Enables a Windows feature (only if not already enabled)
function Enable-Feature {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FeatureName,
        [Parameter(Mandatory = $true)]
        [ref]$WasInstalled
    )
    
    # Initialize WasInstalled to false
    $WasInstalled.Value = $false
    if (-not (Test-Administrator)) {
        Write-Error "Enable-Feature requires elevation. Please run PowerShell as Administrator."
        return $false
    }
    
    try {
        # Check if feature is already enabled
        $featureState = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction Stop
        
        if ($featureState.State -eq "Enabled") {
            Write-Host "$FeatureName feature is already enabled." -ForegroundColor Yellow
            return $true
        }
        
        Write-Host "Enabling $FeatureName feature..." -ForegroundColor Green
        Enable-WindowsOptionalFeature -Online -FeatureName $FeatureName -NoRestart -ErrorAction Stop
        Write-Host "$FeatureName feature enabled successfully." -ForegroundColor Green
        $WasInstalled.Value = $true
        return $true
    }
    catch {
        Write-Error "Failed to enable feature '$FeatureName': $($_.Exception.Message)"
        return $false
    }
}
function CheckProperty {
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

function Get-EnvVar {
    param (
        [Parameter(Mandatory = $true)][string]$Name,
        [ValidateSet('User', 'Machine')][string]$Scope = 'Machine'
    )
    return [Environment]::GetEnvironmentVariable($Name, $Scope)
}

function Set-EnvVar {
    param (
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Value,
        [ValidateSet('User', 'Machine')][string]$Scope = 'Machine'
    )
    # Set persistent environment variable
    [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
    # Set for current session
    Set-Item -Path "Env:$Name" -Value $Value
    Write-Output "Environment variable '$Name' set to '$Value' for $Scope scope and current session."
}

function Add-PathEntry {
    param (
        [Parameter(Mandatory = $true)][string]$PathToAdd,
        [ValidateSet('User', 'Machine')][string]$Scope = 'Machine'
    )
    $currentPath = Get-EnvVar -Name 'Path' -Scope $Scope
    $pathArray = $currentPath -split ';'
    if ($pathArray -contains $PathToAdd) {
        $newPath = ($pathArray | Where-Object { $_ -ne $PathToAdd }) + $PathToAdd -join ';'
        Write-Output "[Add-PathEntry] Path entry already exists. Overwriting..."
        Write-Output "Old PATH: $currentPath"
        Write-Output "New PATH: $newPath"
        Set-EnvVar -Name 'Path' -Value $newPath -Scope $Scope
        Write-Output "Path '$PathToAdd' overwritten in $Scope PATH."
        return $true
    }
    $newPath = ($pathArray + $PathToAdd) -join ';'
    Set-EnvVar -Name 'Path' -Value $newPath -Scope $Scope
    Write-Output "Path '$PathToAdd' added to $Scope PATH."
    return $true
}

function Remove-PathEntry {
    param (
        [Parameter(Mandatory = $true)][string]$PathToRemove,
        [ValidateSet('User', 'Machine')][string]$Scope = 'Machine'
    )
    $currentPath = Get-EnvVar -Name 'Path' -Scope $Scope
    $pathArray = $currentPath -split ';'
    if (-not ($pathArray -contains $PathToRemove)) {
        Write-Output "Path '$PathToRemove' not found in $Scope PATH."
        return $false
    }
    $newPath = ($pathArray | Where-Object { $_ -ne $PathToRemove }) -join ';'
    Set-EnvVar -Name 'Path' -Value $newPath -Scope $Scope
    Write-Output "Path '$PathToRemove' removed from $Scope PATH."
    return $true
}

# List current PATH value for User or Machine scope
function Get-PathEntries {
    param (
        [ValidateSet('User', 'Machine')][string]$Scope = 'Machine'
    )
    $currentPath = Get-EnvVar -Name 'Path' -Scope $Scope
    Write-Output "Current $Scope PATH:"
    $currentPath -split ';'
}

function IsPackageInstalled {
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

function IsPackageAvailable {
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

function Get-LatestPackageVersion {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PackageIdPattern,
        
        [Parameter(Mandatory = $false)]
        [string]$VersionRegex = ""
    )
    
    try {
        Write-Verbose "Searching for packages matching pattern: $PackageIdPattern"
        $searchOutput = winget search --id $PackageIdPattern --accept-source-agreements 2>&1
        
        if (-not $searchOutput) {
            Write-Error "No packages found matching pattern: $PackageIdPattern"
            return $null
        }
        
        # If no custom regex provided, create default pattern to match version segments
        if ([string]::IsNullOrEmpty($VersionRegex)) {
            $VersionRegex = [regex]::Escape($PackageIdPattern) + '(\.\d+)+'
        }
        
        # Extract all matching package IDs
        $packageVersions = $searchOutput | Select-String -Pattern $VersionRegex -AllMatches | 
                          ForEach-Object { $_.Matches.Value } | Sort-Object -Unique
        
        if (-not $packageVersions) {
            Write-Error "No package versions found matching regex: $VersionRegex"
            return $null
        }
        
        # Parse version segments and find the highest
        # Supports multi-segment versions like X.Y.Z (e.g., 3.14.0, 4.0.1)
        $latestPackage = $packageVersions | ForEach-Object {
            $packageId = $_
            # Extract all numeric segments after the base pattern
            $versionPart = $_ -replace "^$([regex]::Escape($PackageIdPattern))\.", ""
            $versionSegments = $versionPart -split '\.' | ForEach-Object { 
                if ($_ -match '^\d+$') { [int]$_ } else { 0 }
            }
            
            [PSCustomObject]@{
                PackageId = $packageId
                Major = if ($versionSegments.Count -gt 0) { $versionSegments[0] } else { 0 }
                Minor = if ($versionSegments.Count -gt 1) { $versionSegments[1] } else { 0 }
                Patch = if ($versionSegments.Count -gt 2) { $versionSegments[2] } else { 0 }
                Build = if ($versionSegments.Count -gt 3) { $versionSegments[3] } else { 0 }
            }
        } | Sort-Object Major, Minor, Patch, Build -Descending | Select-Object -First 1
        
        if ($latestPackage) {
            Write-Verbose "Found latest package: $($latestPackage.PackageId) (Version: $($latestPackage.Major).$($latestPackage.Minor).$($latestPackage.Patch).$($latestPackage.Build))"
            return $latestPackage.PackageId
        } else {
            Write-Error "Could not determine latest package version"
            return $null
        }
    }
    catch {
        Write-Error "Error finding latest package version: $($_.Exception.Message)"
        return $null
    }
}

function Get-InstalledPackageVersion {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PackageIdPattern
    )
    
    try {
        Write-Verbose "Searching for installed packages matching pattern: $PackageIdPattern"
        $listOutput = winget list --accept-source-agreements 2>&1 | Select-String -Pattern $PackageIdPattern -AllMatches
        
        if ($listOutput) {
            $installedPackage = $listOutput.Matches.Value | Select-Object -First 1
            if ($installedPackage) {
                Write-Verbose "Found installed package: $installedPackage"
                return $installedPackage
            }
        }
        
        Write-Verbose "No installed package found matching pattern: $PackageIdPattern"
        return $null
    }
    catch {
        Write-Error "Error finding installed package: $($_.Exception.Message)"
        return $null
    }
}

function InstallPackage {
    param (
        [Parameter(Mandatory = $true)][string]$PackageId,
        [scriptblock]$VerifyCommand = $null,
        [string]$CustomOptions = "",
        [string]$OverrideOptions = ""
    )
    try {
        if (IsPackageInstalled -PackageId $PackageId) {
            Write-Output "Package '$PackageId' is already installed."
            return $true
        }
        if (-not (IsPackageAvailable -PackageId $PackageId)) {
            Write-Error "Package '$PackageId' is not available remotely."
            return $false
        }
        Write-Output "Installing package '$PackageId'..."
        
        $customArg = if ($CustomOptions -ne "") { "--custom $CustomOptions" } else { "" }
        $overrideArg = if ($OverrideOptions -ne "") { "--override `"$OverrideOptions`"" } else { "" }

        $installCommand = "winget install --id $PackageId -e --source winget -h --accept-source-agreements --accept-package-agreements $customArg $overrideArg"
        Invoke-Expression $installCommand
        
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

function UninstallPackage {
    param ([Parameter(Mandatory = $true)][string]$PackageId)
    try {
        if (-not (IsPackageInstalled -PackageId $PackageId)) {
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

function Update-AllPackages {
    param (
        [switch]$CheckOnly,
        [switch]$Silent = $true
    )
    
    try {
        if ($CheckOnly) {
            Write-Output "Checking for available package updates..."
            winget upgrade --accept-source-agreements
        } else {
            Write-Output "Updating all installed packages..."
            if ($Silent) {
                winget upgrade --all --accept-source-agreements --accept-package-agreements --silent
            } else {
                winget upgrade --all --accept-source-agreements --accept-package-agreements
            }
            Write-Output "All packages updated successfully."
        }
        return $true
    }
    catch {
        Write-Error "Failed to update packages: $($_.Exception.Message)"
        return $false
    }
}

function Update-Package {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        [switch]$Silent = $true
    )
    
    try {
        Write-Output "Updating package '$PackageId'..."
        if ($Silent) {
            winget upgrade --id $PackageId --accept-source-agreements --accept-package-agreements --silent
        } else {
            winget upgrade --id $PackageId --accept-source-agreements --accept-package-agreements
        }
        Write-Output "Package '$PackageId' updated successfully."
        return $true
    }
    catch {
        Write-Error "Failed to update package '$PackageId': $($_.Exception.Message)"
        return $false
    }
}