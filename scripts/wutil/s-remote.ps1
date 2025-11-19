#!/usr/bin/env pwsh
# SHISA Remote Debug Server Connection
# Establishes SSH tunnel with port forwarding to remote SHISA server
#
# Usage:
#   s-remote.ps1                              # Use config.local.yaml, auto-start server (default)
#   s-remote.ps1 -AutoStartShisaServer:$false # SSH tunnel only (manual server start)
#   s-remote.ps1 -Remote b2                   # Override remote host from config
#   s-remote.ps1 b2 0                         # Positional: remote host + no auto-start

param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$Remote,
    
    [Parameter(Position=1, Mandatory=$false)]
    [bool]$AutoStartShisaServer = $true
)

. "$PSScriptRoot\shisa_helper.ps1"

# Connect to remote server
Connect-ShisaRemoteServer -LaunchServer $AutoStartShisaServer -RemoteHost $Remote
