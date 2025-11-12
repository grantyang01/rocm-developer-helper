# GPU Interface Setup Helper Functions
# Translated from gi-setup bash script

. "$PSScriptRoot\tools.ps1"

function Setup-RocR {
    param (
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$RocmVersion
    )

    Write-Host "Setting up ROCR-Runtime at: $Target" -ForegroundColor Cyan

    # Create target directory
    if (Test-Path $Target) {
        Remove-Item -Path $Target -Recurse -Force
    }
    New-Item -Path $Target -ItemType Directory -Force | Out-Null

    # Clone source
    $cloneArgs = @(
        'clone',
        "https://github.com/RadeonOpenCompute/ROCR-Runtime",
        '-b', "rocm-$RocmVersion",
        $Target
    )
    $result = & git @cloneArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to clone ROCR-Runtime"
        return $false
    }

    # Patch: Do not check start timestamp validity
    $patchFile = Join-Path $Target "runtime\hsa-runtime\core\runtime\amd_gpu_agent.cpp"
    if (Test-Path $patchFile) {
        $content = Get-Content $patchFile -Raw
        $content = $content -replace '\(start == 0\) \|\| \(end == 0\) \|\| \(start < t0_\.GPUClockCounter\)', '(end == 0)'
        Set-Content -Path $patchFile -Value $content
    }

    # Build release
    $buildArgs = @(
        '-S', $Target,
        '-B', (Join-Path $Target "build-release"),
        '-DBUILD_SHARED_LIBS=OFF',
        '-DClang_DIR=/opt/rocm/lib/llvm/lib/cmake/clang'
    )
    & cmake @buildArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to configure ROCR-Runtime (release)"
        return $false
    }

    & cmake --build (Join-Path $Target "build-release") --config Release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build ROCR-Runtime (release)"
        return $false
    }

    # Build debug
    $buildArgs = @(
        '-S', $Target,
        '-B', (Join-Path $Target "build-debug"),
        '-DBUILD_SHARED_LIBS=OFF',
        '-DClang_DIR=/opt/rocm/lib/llvm/lib/cmake/clang'
    )
    & cmake @buildArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to configure ROCR-Runtime (debug)"
        return $false
    }

    & cmake --build (Join-Path $Target "build-debug") --config Debug
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build ROCR-Runtime (debug)"
        return $false
    }

    Write-Host "ROCR-Runtime setup completed successfully" -ForegroundColor Green
    return $true
}

function Setup-GpuInterface {
    param (
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$RocRPath,
        [Parameter(Mandatory = $true)][string]$GhUser,
        [Parameter(Mandatory = $true)][string]$Pat,
        [string]$GiBranch = ""
    )

    Write-Host "Setting up GPU Interface at: $Target" -ForegroundColor Cyan

    # Create target directory
    if (Test-Path $Target) {
        Remove-Item -Path $Target -Recurse -Force
    }
    New-Item -Path $Target -ItemType Directory -Force | Out-Null

    # Configure git credential helper
    & git config --global credential.helper store
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to configure git credential helper"
        return $false
    }

    # Clone gpu_interface with submodules
    $cloneArgs = @(
        'clone',
        '--recurse-submodules',
        "https://${GhUser}:${Pat}@github.amd.com/LibAmd/SHISA_gpu_interface"
    )
    if ($GiBranch) {
        $cloneArgs += @('-b', $GiBranch)
    }
    $cloneArgs += $Target

    & git @cloneArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to clone SHISA_gpu_interface"
        return $false
    }

    Push-Location $Target

    try {
        # Apply patch to pal_navi
        Set-Location "pal_navi"
        & git apply "..\0001-PAL_CLIENT_SHISA.pal_navi.patch"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to apply navi patch to pal_navi"
            return $false
        }
        & git status

        # Fix syntax error in queue.h
        $queueFile = "shared\devdriver\shared\legacy\inc\util\queue.h"
        if (Test-Path $queueFile) {
            $content = Get-Content $queueFile -Raw
            $content = $content -replace ': Queue\(rhs\.allocCb\(\)\)', ': Queue(rhs.m_allocCb())'
            Set-Content -Path $queueFile -Value $content
        }

        # Fix syntax error in document.h
        $docFile = "shared\devdriver\third_party\rapidjson\include\rapidjson\document.h"
        if (Test-Path $docFile) {
            $content = Get-Content $docFile -Raw
            $content = $content -replace 'const SizeType length;', 'SizeType length;'
            Set-Content -Path $docFile -Value $content
        }

        # Apply patch to pal_vega
        Set-Location "..\pal_vega"
        & git apply "..\0001-PAL_CLIENT_SHISA.pal_vega.patch"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to apply vega patch to pal_vega"
            return $false
        }
        & git status

        # Setup drivers sparse checkout
        Set-Location ".."
        New-Item -Path "drivers" -ItemType Directory -Force | Out-Null
        Set-Location "drivers"

        & git init
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to init drivers"
            return $false
        }

        & git sparse-checkout set drivers/pxproxy drivers/inc/asic_reg drivers/inc/shared drivers/dx/dxx/vam
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to configure sparse-checkout"
            return $false
        }

        & git remote add origin https://github.amd.com/AMD-Radeon-Driver/drivers.git
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to add origin repo"
            return $false
        }

        & git pull --depth 1 origin amd/release/23.30
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to pull amd/release/23.30 from drivers"
            return $false
        }

        # Move directories to root
        if (Test-Path "drivers\pxproxy") { Move-Item "drivers\pxproxy" . -Force }
        if (Test-Path "drivers\inc") { Move-Item "drivers\inc" . -Force }
        if (Test-Path "drivers\dx\dxx\vam") { Move-Item "drivers\dx\dxx\vam" . -Force }

        Set-Location ".."

        # Create SHISA directories
        New-Item -Path "/SHISA/bin" -ItemType Directory -Force | Out-Null
        New-Item -Path "/SHISA/binDebug" -ItemType Directory -Force | Out-Null

        # Build Release
        Write-Host "Building GPU Interface (Release)..." -ForegroundColor Cyan
        $hsaLibRelease = Join-Path $RocRPath "build-release\runtime\hsa-runtime\libhsa-runtime64.a"
        $buildArgs = @(
            '-S', '.',
            '-B', 'build-release',
            '-DCMAKE_BUILD_TYPE=Release',
            '-DGPU_INTERFACE_PAL_SUPPORT=ON',
            '-DGPU_INTERFACE_HSA_SUPPORT=ON',
            "-DHSA_STATIC_LIBRARY=$hsaLibRelease"
        )
        & cmake @buildArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to configure GPU Interface (release)"
            return $false
        }

        & cmake --build build-release --config Release
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to build GPU Interface (release)"
            return $false
        }

        # Build Debug
        Write-Host "Building GPU Interface (Debug)..." -ForegroundColor Cyan
        $hsaLibDebug = Join-Path $RocRPath "build-debug\runtime\hsa-runtime\libhsa-runtime64.a"
        $buildArgs = @(
            '-S', '.',
            '-B', 'build-debug',
            '-DCMAKE_BUILD_TYPE=Debug',
            '-DGPU_INTERFACE_PAL_SUPPORT=ON',
            '-DGPU_INTERFACE_HSA_SUPPORT=ON',
            "-DHSA_STATIC_LIBRARY=$hsaLibDebug"
        )
        & cmake @buildArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to configure GPU Interface (debug)"
            return $false
        }

        & cmake --build build-debug --config Debug
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to build GPU Interface (debug)"
            return $false
        }

        Write-Host "GPU Interface setup completed successfully" -ForegroundColor Green
        return $true

    } finally {
        Pop-Location
    }
}

function Invoke-GpuInterfaceSetup {
    # Load configuration
    $yamlPath = Join-Path $PSScriptRoot "config.yaml"
    $config = Get-Content $yamlPath -Raw | ConvertFrom-Yaml
    $giConfig = $config.gpu_interface

    if (-not $giConfig -or -not $giConfig.enable) {
        Write-Host "GPU Interface setup is disabled in config.yaml" -ForegroundColor Yellow
        return $true
    }

    # Check required parameters
    if (-not $giConfig.gh_user -or -not $giConfig.pat) {
        Write-Error "GPU Interface setup requires 'gh_user' and 'pat' in config.yaml"
        return $false
    }

    $workDir = if ($giConfig.work_dir) { $giConfig.work_dir } else { "C:\work\rdh\shisa" }
    $rocrDir = Join-Path $workDir "rocr"
    $giDir = Join-Path $workDir "gpu_interface"
    $rocmVersion = if ($giConfig.rocm_version_gi) { $giConfig.rocm_version_gi } else { "6.4" }
    $giBranch = $giConfig.gi_branch

    # Setup ROCR
    if (-not (Setup-RocR -Target $rocrDir -RocmVersion $rocmVersion)) {
        Write-Error "ROCR setup failed"
        return $false
    }

    # Setup GPU Interface
    if (-not (Setup-GpuInterface -Target $giDir -RocRPath $rocrDir -GhUser $giConfig.gh_user -Pat $giConfig.pat -GiBranch $giBranch)) {
        Write-Error "GPU Interface setup failed"
        return $false
    }

    # Display results
    Write-Host "`n======================Results: ROCR====================" -ForegroundColor Green
    Get-ChildItem -Path $rocrDir -Recurse -Filter "libhsa-runtime64.a" | ForEach-Object { $_.FullName }

    Write-Host "`n======================Results: GPU Interface====================" -ForegroundColor Green
    Get-ChildItem -Path $env:SHISA -Recurse -Filter "libgpu_interface.*.so" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }

    return $true
}
