# GPU Interface Setup Helper Functions
# Translated from gi-setup bash script

. "$PSScriptRoot\tools.ps1"

function Get-GpuInterface {
    python $PSScriptRoot/../putil/clone_gi.py gpu_interface
}

function Invoke-GpuInterfaceBuild {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BuildName,
        
        [Parameter(Mandatory = $true)]
        [string]$BuildDir,
        
        [Parameter(Mandatory = $true)]
        [string]$SourceDir,
        
        [string]$CMakeOptions = ""
    )
    
    Write-Host "`n=== Building GPU Interface for $BuildName ===" -ForegroundColor Cyan
    
    # Clean old build directory
    if (Test-Path $BuildDir) {
        Write-Host "Cleaning old build directory: $BuildDir" -ForegroundColor Yellow
        Remove-Item -Path $BuildDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # CMake configuration
    $cmakeCmd = "cmake -S `"$SourceDir`" -B `"$BuildDir`" -G `"Visual Studio 17 2022`" $CMakeOptions"
    Invoke-Expression $cmakeCmd
    if (-not $? -or $LASTEXITCODE -ne 0) {
        throw "$BuildName CMake configuration failed with exit code $LASTEXITCODE"
    }
    
    # Build Release
    Write-Host "Building $BuildName Release..." -ForegroundColor Yellow
    cmake --build $BuildDir --config Release
    if (-not $? -or $LASTEXITCODE -ne 0) {
        throw "$BuildName Release build failed with exit code $LASTEXITCODE"
    }
    
    # Build Debug
    Write-Host "Building $BuildName Debug..." -ForegroundColor Yellow
    cmake --build $BuildDir --config Debug
    if (-not $? -or $LASTEXITCODE -ne 0) {
        throw "$BuildName Debug build failed with exit code $LASTEXITCODE"
    }
}

function Test-GpuInterfaceBuild {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BuildType,
        
        [Parameter(Mandatory = $true)]
        [string]$ReleaseDllPath,
        
        [Parameter(Mandatory = $true)]
        [string]$DebugDllPath
    )
    
    if (-not (Test-Path $ReleaseDllPath)) {
        throw "$BuildType Release DLL not found at: $ReleaseDllPath"
    }
    if (-not (Test-Path $DebugDllPath)) {
        throw "$BuildType Debug DLL not found at: $DebugDllPath"
    }
    Write-Host "✓ $BuildType builds completed successfully" -ForegroundColor Green
}

function Build-GpuInterface {
    param(
        [string]$SourceDir = "."
    )
    
    try {
        # Ensure SHISA environment variable is set
        if (-not $env:SHISA) {
            throw "SHISA environment variable is not set. Please run Invoke-ShisaSetup first."
        }
        
        # Build Navi (GFX10/11/12) version
        Invoke-GpuInterfaceBuild -BuildName "Navi (GFX10/11/12)" `
                                 -BuildDir "build_navi" `
                                 -SourceDir $SourceDir
        
        Test-GpuInterfaceBuild -BuildType "Navi" `
                               -ReleaseDllPath (Join-Path $env:SHISA "bin\gpu_interface.13.dll") `
                               -DebugDllPath (Join-Path $env:SHISA "binDebug\gpu_interface.13.dll")
        
        # Build Vega (GFX9/MI300) version
        Invoke-GpuInterfaceBuild -BuildName "Vega (GFX9/MI300)" `
                                 -BuildDir "build_vega" `
                                 -SourceDir $SourceDir `
                                 -CMakeOptions "-DGPU_INTERFACE_PAL_VEGA_SUPPORT=ON"
        
        Test-GpuInterfaceBuild -BuildType "Vega" `
                               -ReleaseDllPath (Join-Path $env:SHISA "bin\Vega\gpu_interface.13.dll") `
                               -DebugDllPath (Join-Path $env:SHISA "binDebug\Vega\gpu_interface.13.dll")
        
        # Summary
        Write-Host "`n=== Build Summary ===" -ForegroundColor Cyan
        Write-Host "Navi Release:  $(Join-Path $env:SHISA 'bin\gpu_interface.13.dll')" -ForegroundColor Green
        Write-Host "Navi Debug:    $(Join-Path $env:SHISA 'binDebug\gpu_interface.13.dll')" -ForegroundColor Green
        Write-Host "Vega Release:  $(Join-Path $env:SHISA 'bin\Vega\gpu_interface.13.dll')" -ForegroundColor Green
        Write-Host "Vega Debug:    $(Join-Path $env:SHISA 'binDebug\Vega\gpu_interface.13.dll')" -ForegroundColor Green
        Write-Host "`n✓ All GPU Interface builds completed successfully!" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Error "GPU Interface build failed: $_"
        return $false
    }
}

function Install-GpuInterface {
    $originalDir = Get-Location
    
    try {
        # Read configuration to get WORK_DIR
        $config = Read-Yaml -Path "$PSScriptRoot\config.yaml"
        if (-not ($config.paths -and $config.paths.WORK_DIR)) {
            throw "WORK_DIR not found in config.yaml. Please configure paths.WORK_DIR in config.local.yaml"
        }
        $workDir = $config.paths.WORK_DIR
        
        Write-Host "Building GPU Interface from source..." -ForegroundColor Cyan
        
        # Change to work directory for cloning
        Set-Location $workDir
        
        # Clone GPU Interface repository
        Write-Host "Cloning GPU Interface repository to: $workDir\gpu_interface" -ForegroundColor Cyan
        Get-GpuInterface
        
        # Build GPU Interface
        $giSourceDir = Join-Path $workDir "gpu_interface"
        if (Test-Path $giSourceDir) {
            Push-Location $giSourceDir
            try {
                $success = Build-GpuInterface -SourceDir "."
                if (-not $success) {
                    Write-Error "Failed to build GPU Interface."
                    return $false
                }
                return $true
            }
            finally {
                Pop-Location
            }
        } else {
            Write-Warning "GPU Interface source directory not found at: $giSourceDir"
            Write-Warning "Using pre-built GPU Interface binaries from SHISA setup."
            return $true  # Not a failure - fallback to pre-built binaries
        }
    }
    catch {
        Write-Error "GPU Interface installation failed: $_"
        Write-Warning "Using pre-built GPU Interface binaries from SHISA setup."
        return $false
    }
    finally {
        Set-Location $originalDir
    }
}