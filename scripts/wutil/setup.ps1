. "$PSScriptRoot\tools.ps1"
function Install-Chocolatey {
    
    try {
        # Check if running as administrator
        if (-not (IsAdmin)) {
            Write-Error "Administrator privileges required to install Chocolatey!"
            throw "Installation failed: Not running as administrator"
        }

        Write-Host "Installing Chocolatey..." -ForegroundColor Green

        # Check if Chocolatey is already installed
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Chocolatey is already installed!" -ForegroundColor Yellow
            return
        }

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
        Write-Host "You may need to restart your shell or run 'refreshenv' to use choco commands." -ForegroundColor Cyan
    }
    catch {
        Write-Error "Failed to install Chocolatey: $($_.Exception.Message)"
        throw
    }
}

function Install-Haskell {
    try {
        # Check if running as administrator
        if (-not (IsAdmin)) {
            Write-Error "Administrator privileges required to install Haskell tools!"
            throw "Installation failed: Not running as administrator"
        }

        Write-Host "Installing Haskell tools..." -ForegroundColor Green
        
        choco install haskell-stack -y
        choco install ghc -y
        
        Write-Host "Haskell tools installation completed!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install Haskell tools: $($_.Exception.Message)"
        throw
    }
}

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

# Install Chocolatey
# Install-Chocolatey

# setup hip sdk
# InstallHipSdk -rocmBranch "release_rocm-rel-6.4" -rocmBuild "76"

# config
# setx /M PATH "%PATH%;C:\Users\gryang\Downloads"
# Add-PathEntry -PathToAdd 'C:\Users\gryang\Downloads' -Scope 'Machine'

## sshfs
# 
<##
# save path
C:\WINDOWS\system32
C:\WINDOWS
C:\WINDOWS\System32\Wbem
C:\WINDOWS\System32\WindowsPowerShell\v1.0\
C:\WINDOWS\System32\OpenSSH\
C:\Program Files\Perforce\
C:\Program Files\Git LFS
C:\Program Files\PowerShell\7\
C:\Program Files\dotnet\
C:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit\
C:\Strawberry\c\bin
C:\Strawberry\perl\site\bin
C:\Strawberry\perl\bin
C:\Program Files\LLVM\bin
C:\Program Files\Git\cmd
C:\Program Files\Git\mingw64\bin
C:\Program Files\Git\usr\bin
C:\Users\gryang\AppData\Roaming\local\bin
C:\Users\gryang\AppData\Local\Microsoft\WindowsApps
C:\Users\gryang\AppData\Local\Programs\Microsoft VS Code\bin
C:\Users\gryang\.dotnet\tools
C:\opt\rocm\bin
C:\Users\gryang\AppData\Roaming\local\bin
C:\Users\gryang\AppData\Local\Microsoft\WindowsApps
C:\Users\gryang\AppData\Local\Programs\Microsoft VS Code\bin
C:\Users\gryang\.dotnet\tools
C:\Users\gryang\Downloads
C:\Users\gryang\AppData\Roaming\local\bin
C:\Users\gryang\AppData\Local\Microsoft\WindowsApps
C:\Users\gryang\AppData\Local\Programs\Microsoft VS Code\bin
C:\Users\gryang\.dotnet\tools

#>