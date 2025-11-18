#!/usr/bin/env pwsh

. "$PSScriptRoot\tools.ps1"

function Set-P4Config {
    $yamlPath = "$PSScriptRoot\config.yaml"
    $config = Read-Yaml -Path $yamlPath
    
    if (-not $config) {
        return $false
    }
    
    if (-not $config.devtools.p4) {
        Write-Warning "P4 configuration not found in config.yaml"
        return $true
    }

    $p4Config = $config.devtools.p4
    
    Write-Host "Configuring Perforce (P4) settings..." -ForegroundColor Cyan
    
    if ($p4Config.port) {
        Write-Host "  Setting P4PORT: $($p4Config.port)" -ForegroundColor Gray
        p4 set P4PORT=$($p4Config.port)
    }
    
    if ($p4Config.user) {
        Write-Host "  Setting P4USER: $($p4Config.user)" -ForegroundColor Gray
        p4 set P4USER=$($p4Config.user)
    }
    
    if ($p4Config.client) {
        Write-Host "  Setting P4CLIENT: $($p4Config.client)" -ForegroundColor Gray
        p4 set P4CLIENT=$($p4Config.client)
    }

    # Verify connection (if on network)
    Write-Host "Verifying P4 connection..." -ForegroundColor Cyan
    p4 info 2>&1 | Out-Null
    $connectionSuccess = ($LASTEXITCODE -eq 0)
    
    if (-not $connectionSuccess) {
        Write-Warning "P4 configured but connection test failed. You may need to be on VPN."
        Write-Host "P4 settings have been saved and will work when connected to the network." -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "P4 configuration successful!" -ForegroundColor Green

    # Create P4 client workspace if configured
    if ($p4Config.client -and $p4Config.root) {
        $clientName = $p4Config.client
        $rootPath = $p4Config.root
        $username = if ($p4Config.user) { $p4Config.user } else { $env:USERNAME }
        $viewPath = if ($p4Config.view) { $p4Config.view } else { "//depot/main/sw/SHISA/..." }

        Write-Host "`nCreating P4 client workspace: $clientName" -ForegroundColor Cyan
        Write-Host "  Root: $rootPath" -ForegroundColor Gray
        Write-Host "  Owner: $username" -ForegroundColor Gray
        Write-Host "  View: $viewPath" -ForegroundColor Gray

        # Check if client already exists
        $existingClient = p4 clients | Select-String -Pattern "^Client $clientName "
        if ($existingClient) {
            Write-Warning "Client '$clientName' already exists. Skipping creation."
            Write-Host "To recreate, delete it first with: p4 client -d $clientName" -ForegroundColor Yellow
        } else {
            # Create the client workspace
            $clientSpec = @"
Client: $clientName
Owner: $username
Root: $rootPath
Options: noallwrite noclobber nocompress unlocked nomodtime normdir
SubmitOptions: submitunchanged
LineEnd: local
View:
	$viewPath //$clientName/...
"@

            try {
                $clientSpec | p4 client -i 2>&1 | Out-Null
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "P4 client workspace created successfully!" -ForegroundColor Green
                    
                    # Sync files after creating the workspace
                    Write-Host "`nSyncing files from Perforce..." -ForegroundColor Cyan
                    Write-Host "This may take a while for large repositories..." -ForegroundColor Gray
                    
                    p4 sync
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Files synced successfully!" -ForegroundColor Green
                    } else {
                        Write-Warning "Sync completed with errors. Check output above."
                    }
                } else {
                    Write-Error "Failed to create P4 client workspace"
                    return $false
                }
            } catch {
                Write-Error "Error creating P4 client: $_"
                return $false
            }
        }
    }
    
    return $true
}

function Remove-P4Client {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ClientName
    )
    
    if ([string]::IsNullOrWhiteSpace($ClientName)) {
        Write-Error "Client name is required. Usage: Remove-P4Client -ClientName <name>"
        return $false
    }
    
    Write-Host "Removing P4 client workspace: $ClientName" -ForegroundColor Cyan
    
    # Check if client exists
    $clientExists = p4 clients | Select-String -Pattern "^Client $ClientName "
    if (-not $clientExists) {
        Write-Warning "Client '$ClientName' does not exist on the server"
        return $false
    }
    
    # Set as current client temporarily to enable file removal
    Write-Host "`nSetting as current client..." -ForegroundColor Cyan
    p4 set P4CLIENT=$ClientName
    
    # Remove synced files
    Write-Host "Removing synced files..." -ForegroundColor Cyan
    Write-Host "  This will delete all files in the workspace" -ForegroundColor Yellow
    
    try {
        p4 sync -f "#none"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Files removed successfully" -ForegroundColor Green
        } else {
            Write-Warning "Failed to remove some files. Continuing with client deletion..."
        }
    } catch {
        Write-Warning "Error removing files: $_"
    }
    
    # Delete the client workspace specification
    Write-Host "`nDeleting client workspace specification..." -ForegroundColor Cyan
    
    try {
        p4 client -d $ClientName
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Client workspace '$ClientName' deleted successfully!" -ForegroundColor Green
            
            p4 set P4CLIENT=
            return $true
        } else {
            Write-Error "Failed to delete client workspace"
            return $false
        }
    } catch {
        Write-Error "Error deleting client: $_"
        return $false
    }
}

