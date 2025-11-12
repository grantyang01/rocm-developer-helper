. "$PSScriptRoot\tools.ps1"

function Invoke-InVSEnvironment {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    $vsDevCmdPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"
    
    if (-not (Test-Path $vsDevCmdPath)) {
        Write-Error "Visual Studio 2022 not found at: $vsDevCmdPath"
        return $false
    }
    
    Write-Host "Running command in VS 2022 environment: $Command" -ForegroundColor Cyan
    
    # Execute command in CMD with VS environment loaded
    & $env:comspec /c "`"$vsDevCmdPath`" && $Command"
    
    return ($LASTEXITCODE -eq 0)
}

function Install-ShisaTools {
    # Read YAML configuration to get SHISA path
    $config = Read-Yaml -Path "$PSScriptRoot\config.yaml"
    if (-not $config -or -not $config.SHISA -or -not $config.SHISA.SHISA) {
        Write-Error "Failed to read SHISA path from config.yaml"
        return $false
    }
    $shisaPath = $config.SHISA.SHISA
    
    # Install Strawberry Perl
    Write-Host "Installing Strawberry Perl..." -ForegroundColor Cyan
    InstallPackage -PackageId 'StrawberryPerl.StrawberryPerl' `
                   -VerifyCommand { Test-Path "C:\Strawberry\perl\bin\perl.exe" }

    # move strawberry perl to top of PATH in case Git's Perl already in PATH
    Write-Host "Prioritizing Strawberry Perl in Machine PATH..." -ForegroundColor Yellow
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $pathArray = ($machinePath -split ';') | Where-Object { $_ -ne 'C:\Strawberry\perl\bin' }
    $newMachinePath = (@('C:\Strawberry\perl\bin') + $pathArray) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newMachinePath, 'Machine')

    # Install LLVM (for clang.exe)
    Write-Host "Installing LLVM..." -ForegroundColor Cyan
    InstallPackage -PackageId 'LLVM.LLVM' `
                   -VerifyCommand { Test-Path "C:\Program Files\LLVM\bin\clang.exe" }

    # Install Haskell Stack
    Write-Host "Installing Haskell Stack..." -ForegroundColor Cyan
    InstallPackage -PackageId 'commercialhaskell.stack' `
                   -VerifyCommand { Test-Path "C:\Users\$env:USERNAME\AppData\Roaming\local\bin\stack.exe" }
  
    # Add source globally (run once from anywhere):
    Write-Host "Configuring NuGet sources..." -ForegroundColor Cyan
    $existingSources = dotnet nuget list source 2>$null | Out-String
    if ($existingSources -notmatch 'nuget\.org') {
        $result = dotnet nuget add source https://api.nuget.org/v3/index.json --name nuget.org 2>&1
    }
    
    # Clean Visual Studio plugins build artifacts manually
    Write-Host "Cleaning Visual Studio plugins build artifacts..." -ForegroundColor Cyan
    $pluginsPath = Join-Path $shisaPath "tools\visual_studio_plugins"
    if (Test-Path $pluginsPath) {
        Get-ChildItem -Path $pluginsPath -Include bin,obj -Recurse -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cleaned all bin and obj directories" -ForegroundColor Green
    }

    # 1. manually copy \\amd.com\svdc\dxgametraces\TOOLS\ThreadTraceViewer\Latest\ThreadTraceView.7z
    # to C:\ThreadTraceView, 
    # 2. add C:\ThreadTraceView to Machine PATH
}

function Uninstall-ShisaTools {
    UninstallPackage -PackageId 'StrawberryPerl.StrawberryPerl'

    UninstallPackage -PackageId 'LLVM.LLVM'

    UninstallPackage -PackageId 'commercialhaskell.stack'
}

function Set-ShisaEnvVars {
    param(
        [string]$yamlPath = "$PSScriptRoot\config.yaml"
    )
    $errors = @()

    # Read YAML configuration using the generic Read-Yaml function
    $config = Read-Yaml -Path $yamlPath
    if (-not $config) {
        Write-Error "Failed to load configuration from: $yamlPath"
        return $false
    }

    # Extract SHISA section from config
    $envConfig = $config.SHISA
    if (-not $envConfig) {
        Write-Error "SHISA section not found in configuration file: $yamlPath"
        return $false
    }

    $shisaValue = $envConfig.SHISA

    foreach ($pair in $envConfig.GetEnumerator()) {
        $value = $pair.Value
        if ($null -ne $value -and $value -is [string]) {
            $value = $value -replace '%%SHISA%%', $shisaValue
        }
        try {
            Set-EnvVar -Name $pair.Key -Value $value -Scope 'User'
            
        } catch {
            $errors += "Failed to set $($pair.Key): $_"
        }
    }

    # Add SHISA directories to PATH
    if ($shisaValue -and $envConfig.path_dirs) {
        foreach ($pathDir in $envConfig.path_dirs) {
            $fullPath = Join-Path $shisaValue $pathDir
            try {
                Write-Host "Adding to user PATH: $fullPath"
                Add-PathEntry -PathToAdd $fullPath -Scope 'User'
            } catch {
                $errors += "Failed to add $pathDir to PATH: $_"
            }
        }
        
        # Refresh PATH in current session after all additions
        $env:Path = (
            [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")
        )
    }
    
    # Create SP3_PREPROCESSOR_CONFIG_FILE if it doesn't exist
    if ($shisaValue) {
        $configFile = $envConfig.SP3_PREPROCESSOR_CONFIG_FILE
        if ($configFile -and $configFile -is [string]) {
            $configFile = $configFile -replace '%%SHISA%%', $shisaValue
            if (-not (Test-Path $configFile)) {
                try {
                    New-Item -Path $configFile -ItemType File -Force | Out-Null
                    Write-Host "Created empty config file at: $configFile"
                } catch {
                    $errors += "Failed to create config file: $_"
                }
            }
        }
    }

    if ($errors.Count -gt 0) {
        Write-Error (
            "SHISA environment setup encountered errors:\n" +
            ($errors -join "`n")
        )
        return $false
    } else {
        Write-Host "SHISA environment variables and PATH setup completed successfully."
        return $true
    }
}

function Invoke-ShisaSetup {
    $config = Read-Yaml -Path "$PSScriptRoot\config.yaml"
    if (-not $config -or -not $config.SHISA -or -not $config.SHISA.SHISA) {
        Write-Error "Failed to read SHISA path from config.yaml"
        return $false
    }
    
    $shisaRoot = $config.SHISA.SHISA
    $setupScript = Join-Path $shisaRoot "tools\scripts\SHISA_setup.pl"
    
    if (-not (Test-Path $setupScript)) {
        Write-Error "SHISA_setup.pl not found at: $setupScript"
        return $false
    }
    
    Write-Host "Running SHISA setup script from: $shisaRoot" -ForegroundColor Cyan
    return Invoke-InVSEnvironment ('perl "{0}"' -f $setupScript)
}
