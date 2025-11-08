. "$PSScriptRoot\tools.ps1"

function InstallHipSdk {
    param (
        [string]$rocmBranch = "release_rocm-rel-6.4",
        [string]$rocmBuild = "76",
        [string]$rocmPath = "C:\opt\rocm"
    )

    # Construct release relative path and download URL
    $rocmRel = "$rocmBranch\$rocmBuild"
    $rocmUrl = "https://mkmartifactory.amd.com:8443/artifactory/sw-hip-rel-local/hip-sdk/$($rocmBranch)/$($rocmBuild)/hipSDK.zip"

    # Create ROCm base path if missing
    if (-not (Test-Path $rocmPath)) {
        mkdir $rocmPath | Out-Null
    }

    # Create destination directory for versioned release
    $versionedPath = Join-Path $rocmPath $rocmRel
    if (-not (Test-Path $versionedPath)) {
        mkdir $versionedPath | Out-Null
    }

    $rocmZipFile = Join-Path $versionedPath "hipSDK.zip"

    # Download hipSDK.zip
    Write-Host "Downloading HIP SDK from $rocmUrl to $rocmZipFile"
    curl.exe -o $rocmZipFile $rocmUrl

    # Prepare extraction folder inside TEMP
    $tempExtractPath = Join-Path $env:TEMP "hipSDK_extract"

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Write-Host "Extracting zip to $tempExtractPath"
    [System.IO.Compression.ZipFile]::ExtractToDirectory($rocmZipFile, $tempExtractPath)

    # Clear existing ROCm install contents
    Write-Host "Cleaning existing ROCm installation under $rocmPath"
    Remove-Item -Path (Join-Path $rocmPath '*') -Recurse -Force

    # Copy SDKCore and RTCRuntime Bin contents
    Write-Host "Copying SDKCore binaries"
    Copy-Item -Path (Join-Path $tempExtractPath "ROCmSDKPackages\SDKCore\Bin\*") -Destination $rocmPath -Recurse -Force
    Write-Host "Copying RTCRuntime binaries"
    Copy-Item -Path (Join-Path $tempExtractPath "ROCmSDKPackages\RTCRuntime\Bin\*") -Destination $rocmPath -Recurse -Force

    # Clean up temporary extraction folder
    Write-Host "Cleaning up temporary extraction folder"
    Remove-Item -Path $tempExtractPath -Recurse -Force

    # Set environment variables persistently using PowerShell
    Write-Host "Setting HIP_PATH and updating system PATH environment variables"
    [System.Environment]::SetEnvironmentVariable('HIP_PATH', $rocmPath, 'Machine')
    $oldPath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    if ($oldPath -notlike "*$($rocmPath)\bin*") {
        $newPath = $oldPath.TrimEnd(';') + ";$($rocmPath)\bin"
        [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine')
    }

    Write-Host "HIP SDK installation complete. Please restart your shell or system to apply environment variable changes."
}

# setup hip sdk
# InstallHipSdk -rocmBranch "release_rocm-rel-6.4" -rocmBuild "76"
