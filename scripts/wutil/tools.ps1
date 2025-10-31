function IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    return $isAdmin
}

# Generic function to read YAML file
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
        
        return $yamlData
    } catch {
        Write-Error "Failed to read configuration file: $($_.Exception.Message)"
        return $null
    }
}

# Enables a Windows feature (unconditionally attempts to enable)
function Enable-Feature {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FeatureName
    )
    if (-not (IsAdmin)) {
        Write-Error "Enable-Feature requires elevation. Please run PowerShell as Administrator."
        return $false
    }
    
    Write-Host "Enabling $FeatureName feature..."
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName $FeatureName -NoRestart -ErrorAction Stop
        Write-Host "$FeatureName feature enabled successfully."
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

# Example usage:
# CheckProperty -PropertyName "HyperVRequirementVirtualizationFirmwareEnabled"

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

# latest power shell, and powershell-yaml
# InstallPackage -PackageId 'Microsoft.PowerShell'
# Install-Module powershell-yaml -Force -Confirm:$false

# UninstallPackage -PackageId 'Microsoft.PowerShell'
# winget search Microsoft.PowerShell

# install python with 
# InstallPackage -PackageId 'Python.Python.3.12'
# pip install PyYAML


# vscode
# InstallPackage -PackageId 'Microsoft.VisualStudioCode'

# cursor

# InstallPackage -PackageId 'Anysphere.Cursor'

# Install Git
# InstallPackage -PackageId 'Git.Git' -CustomOptions "'/o:PathOption=CmdTools'" -VerifyCommand { git --version }
# UninstallPackage -PackageId 'Git.Git'

# Install Git LFS
# InstallPackage -PackageId 'GitHub.GitLFS' -VerifyCommand { git lfs version }
# UninstallPackage -PackageId 'GitHub.GitLFS'

# pdf
# InstallPackage -PackageId SumatraPDF.SumatraPDF
# UninstallPackage -PackageId 'SumatraPDF.SumatraPDF'

<# 
install copilot cli
pre-requirements:
    1. Node.js version 22 or later
    2. npm version 10 or later
#>
# InstallPackage -PackageId 'OpenJS.NodeJS' -VerifyCommand { node -v }
# UninstallPackage -PackageId 'OpenJS.NodeJS'
# npm install -g @github/copilot

# visual studio 2022
<#
component name to id:
https://learn.microsoft.com/en-us/visualstudio/install/workload-and-component-ids?view=vs-2022
https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community?view=vs-2022&preserve-view=true

components required by shisa development:
name                                                                        id
Desktop development with C++                                                Microsoft.VisualStudio.Workload.NativeDesktop
.NET desktop development                                                    Microsoft.VisualStudio.Workload.ManagedDesktop
Visual Studio extension development                                         Microsoft.VisualStudio.Workload.VisualStudioExtension
Windows 11 SDK (10.0.26100.3916)                                            Microsoft.VisualStudio.Component.Windows11SDK.26100
MSVC v142 - VS 2019 C++ x64/x86 build tools (v14.29)                        Microsoft.VisualStudio.ComponentGroup.VC.Tools.142.x86.x64
MSVC v142 - VS 2019 C++ x64/x86 Spectre-mitigated libs (v14.29-16.11)       Microsoft.VisualStudio.Component.VC.14.29.16.11.x86.x64.Spectre
.NET Framework 4.8 targeting pack                                           Microsoft.Net.Component.4.8.TargetingPack
Text Template Transformation                                                Microsoft.VisualStudio.Component.TextTemplating
Modeling SDK                                                                Microsoft.VisualStudio.Component.DslTools

# winget
$vsOverrideOptions = "--add Microsoft.VisualStudio.Workload.NativeDesktop " + `
                     "--add Microsoft.VisualStudio.Workload.ManagedDesktop " + `
                     "--add Microsoft.VisualStudio.Workload.VisualStudioExtension " + `
                     "--add Microsoft.VisualStudio.Component.Windows11SDK.26100 " + `
                     "--add Microsoft.VisualStudio.ComponentGroup.VC.Tools.142.x86.x64 " + `
                     "--add Microsoft.VisualStudio.Component.VC.14.29.16.11.x86.x64.Spectre " + `
                     "--add Microsoft.Net.Component.4.8.TargetingPack " + `
                     "--add Microsoft.VisualStudio.Component.TextTemplating " + `
                     "--add Microsoft.VisualStudio.Component.DslTools " + `
                     "--includeRecommended"

winget install --id Microsoft.VisualStudio.2022.Community -e --source winget -h --accept-source-agreements --accept-package-agreements --override "$vsOverrideOptions"

InstallPackage -PackageId 'Microsoft.VisualStudio.2022.Community' -OverrideOptions $vsOverrideOptions -VerifyCommand { winget list | Select-String 'VisualStudio' }
# use VisualStudioSetup.exe directly
VisualStudioSetup.exe --add Microsoft.VisualStudio.Workload.NativeDesktop `
--add Microsoft.VisualStudio.Workload.ManagedDesktop `
--add Microsoft.VisualStudio.Workload.VisualStudioExtension `
--add Microsoft.VisualStudio.Component.Windows11SDK.26100 `
--add Microsoft.VisualStudio.ComponentGroup.VC.Tools.142.x86.x64 `
--add Microsoft.VisualStudio.Component.VC.14.29.16.11.x86.x64.Spectre `
--add Microsoft.Net.Component.4.8.TargetingPack `
--add Microsoft.VisualStudio.Component.TextTemplating `
--add Microsoft.VisualStudio.Component.DslTools `
--includeRecommended

# uninstall
UninstallPackage -PackageId 'Microsoft.VisualStudio.2022.Community'
#>