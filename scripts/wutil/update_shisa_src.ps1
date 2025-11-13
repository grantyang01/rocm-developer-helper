#!/usr/bin/env pwsh

. "$PSScriptRoot\tools.ps1"

function Get-ShisaSrc {
    $outputPath = "shisa_src.tar.gz"
    $config = Read-Yaml -Path "$PSScriptRoot\config.yaml"
    
    if (-not $config) {
        return $false
    }
    
    $shisaRoot = $config.SHISA.SHISA
    if (-not $shisaRoot) {
        Write-Error "SHISA root not found in config.yaml"
        return $false
    }
    
    if (-not (Test-Path $shisaRoot)) {
        Write-Error "SHISA path not found: $shisaRoot"
        return $false
    }

    Push-Location $shisaRoot
    try {
        # Sync from Perforce
        Write-Host "Syncing SHISA from Perforce..." -ForegroundColor Cyan
        & p4 sync ...
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to sync from Perforce"
            return $false
        }
        
        Write-Host "SHISA synced successfully" -ForegroundColor Green

        # List of folders to include
        $folders = @(
            'shader_dev',
            'shader_dev_IL',
            'shader_dev_SSP',
            'shader_releases',
            'sp3',
            'testing',
            'test_apps'
        )

        # Add all subdirectories under tools\ except visual_studio_plugins
        if (Test-Path 'tools') {
            $toolsDirs = Get-ChildItem -Path 'tools' -Directory | 
                Where-Object { $_.Name -ne 'visual_studio_plugins' } |
                ForEach-Object { Join-Path 'tools' $_.Name }
            
            $folders += $toolsDirs
        }

        # Use Windows tar (available in Windows 10+)
        # Exclude temporary and cache directories
        $excludes = @(
            '--exclude=.vs',
            '--exclude=.vscode',
            '--exclude=build',
            '--exclude=build-debug',
            '--exclude=.stack-work',
            '--exclude=obj',
            '--exclude=.git',
            '--exclude=x64',
            '--exclude=Debug',
            '--exclude=Release',
            '--exclude=*.user',
            '--exclude=*.suo',
            '--exclude=*.vcxproj.filters',
            '--exclude=tools/visual_studio_plugins/*/bin'
        )
                
        Write-Host "Creating archive: $outputPath" -ForegroundColor Cyan
        & tar -czf $outputPath @excludes @folders

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Archive created: $outputPath" -ForegroundColor Green
            return $true
        } else {
            Write-Error "Failed to create archive"
            return $false
        }
    } finally {
        Pop-Location
    }
}

Get-ShisaSrc