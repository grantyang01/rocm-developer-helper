. "$PSScriptRoot\tools.ps1"

function Set-ShisaEnvVars {
    param(
        [string]$yamlPath = "$PSScriptRoot\shisa_config.yaml"
    )
    $errors = @()

    # Read YAML configuration using the generic Read-Yaml function
    $envConfig = Read-Yaml -Path $yamlPath
    if (-not $envConfig) {
        Write-Error "Failed to load SHISA configuration from: $yamlPath"
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

    # Add SHISA bin to PATH after setting environment variables
    if ($shisaValue) {
        $shisaBinPath = Join-Path $shisaValue "bin"
        try {
            Write-Host "Adding SHISA bin to user PATH: $shisaBinPath"
            Add-PathEntry -PathToAdd $shisaBinPath -Scope 'User'
        } catch {
            $errors += "Failed to add SHISA bin to PATH: $_"
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
