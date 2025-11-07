function Init-Bootstrap {
    param(
        [string]$WorkPath = "c:\work"
    )
    
    # install git if not available
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        winget install Git.Git
        $env:Path += ";C:\Program Files\Git\cmd"
    }

    # check out bootstrap: rdh
    # establish .ssh to user profile\.ssh
    New-Item -Path $WorkPath -ItemType Directory -Force | Set-Location
    git clone git@me.github.com:grantyang01/rocm-developer-helper.git rdh
}

Init-Bootstrap
<#
    # Before running this script:
    # Enable PowerShell script execution by running ONE of these commands as Administrator:
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

#>
