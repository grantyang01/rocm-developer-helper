#!/usr/bin/env pwsh
# SHISA Remote Debug Server Connection
# Establishes SSH tunnel with port forwarding to remote SHISA server

. "$PSScriptRoot\shisa_helper.ps1"

# Connect to remote server
Connect-ShisaRemoteServer
