. "$PSScriptRoot\tools.ps1"
. "$PSScriptRoot\git_helper.ps1"
. "$PSScriptRoot\p4_helper.ps1"
. "$PSScriptRoot\vs_helper.ps1"

function Install-DevelopmentTools {
    try {
        # Python - find and install latest version
        Write-Host "Finding latest Python version..." -ForegroundColor Cyan
        $latestPython = Get-LatestPackageVersion -PackageIdPattern "Python.Python"
        if ($latestPython) {
            Write-Host "Installing Python (latest: $latestPython)..." -ForegroundColor Cyan
            InstallPackage -PackageId $latestPython `
                           -VerifyCommand { Test-Path "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python*\python.exe" }
        } else {
            Write-Error "Could not find Python package to install"
        }
        
        # Refresh PATH to make python and pip available immediately
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + `
                    [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Write-Host "Installing Python packages (pypdf, jinja2, ruamel.yaml)..." -ForegroundColor Cyan
        python -m pip install pypdf jinja2 ruamel.yaml --quiet

        # sshfs-win
        Write-Host "Installing sshfs-win..." -ForegroundColor Cyan
        InstallPackage -PackageId 'SSHFS-Win.SSHFS-Win' `
                       -VerifyCommand { Test-Path "C:\Program Files\SSHFS-Win\bin\sshfs.exe" }

        # chrome
        Write-Host "Installing Chrome..." -ForegroundColor Cyan
        InstallPackage -PackageId 'Google.Chrome' `
                       -VerifyCommand { Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe" }

        # pdf reader
        Write-Host "Installing Adobe Reader..." -ForegroundColor Cyan
        InstallPackage -PackageId 'Adobe.Acrobat.Reader.64-bit' `
               -VerifyCommand { Test-Path "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe" }

        # vscode
        Write-Host "Installing VisualStudio Code..." -ForegroundColor Cyan
        InstallPackage -PackageId 'Microsoft.VisualStudioCode' `
                       -VerifyCommand { Test-Path "C:\Users\$env:USERNAME\AppData\Local\Programs\Microsoft VS Code\Code.exe" }

        # cursor
        Write-Host "Installing Cursor..." -ForegroundColor Cyan
        InstallPackage -PackageId 'Anysphere.Cursor' `
                       -VerifyCommand { Test-Path "C:\Users\$env:USERNAME\AppData\Local\Programs\Cursor\Cursor.exe" }

        # reinstall Git with options /o:PathOption=CmdTools
        Write-Host "Installing git..." -ForegroundColor Cyan
        UninstallPackage -PackageId 'Git.Git'
        InstallPackage -PackageId 'Git.Git' -CustomOptions "'/o:PathOption=CmdTools'" `
                       -VerifyCommand { & "C:\Program Files\Git\cmd\git.exe" --version }

        $env:Path = "C:\Program Files\Git\cmd;$env:Path"
        Configure-Git

        # Git LFS
        Write-Host "Installing git lfs..." -ForegroundColor Cyan
        InstallPackage -PackageId 'GitHub.GitLFS' `
                       -VerifyCommand { & "C:\Program Files\Git\cmd\git.exe" lfs version }

        # P4V (Perforce Visual Client)
         Write-Host "Installing p4v..." -ForegroundColor Cyan
        InstallPackage -PackageId 'Perforce.P4V' `
                       -VerifyCommand { Test-Path "C:\Program Files\Perforce\p4v.exe" }
        
        # Configure P4 settings and create shisa workspace
        Set-P4Config

        <# 
        install copilot cli pre-requirements:
            1. Node.js version 22 or later
            2. npm version 10 or later
        #>
        Write-Host "Installing node js..." -ForegroundColor Cyan
        InstallPackage -PackageId 'OpenJS.NodeJS'  `
                       -VerifyCommand { & "C:\Program Files\nodejs\node.exe" -v }
        & "C:\Program Files\nodejs\npm.cmd" install -g @github/copilot

        
        # Docker Desktop
        Write-Host "Installing docker desktop..." -ForegroundColor Cyan
        InstallPackage -PackageId 'Docker.DockerDesktop' `
                       -VerifyCommand { Test-Path "C:\Program Files\Docker\Docker\Docker Desktop.exe" }
       
        # visual studio 2022
        Install-VisualStudio -UnattendedInstall $true

        Write-Host "Development tools installation completed!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Error during development tools installation: $($_.Exception.Message)"
        Write-Host "Installation failed at: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
        return $false
    }
}

function Uninstall-DevelopmentTools {
    # Uninstall Python - find any installed Python version
    Write-Host "Finding installed Python version..." -ForegroundColor Cyan
    $installedPython = Get-InstalledPackageVersion -PackageIdPattern 'Python\.Python(\.\d+)+'
    if ($installedPython) {
        Write-Host "Uninstalling $installedPython..." -ForegroundColor Cyan
        UninstallPackage -PackageId $installedPython
    } else {
        Write-Host "No Python installation found." -ForegroundColor Yellow
    }

    UninstallPackage -PackageId 'SSHFS-Win.SSHFS-Win'

    UninstallPackage -PackageId 'Google.Chrome'

    UninstallPackage -PackageId 'Adobe.Acrobat.Reader.64-bit'

    UninstallPackage -PackageId 'Microsoft.VisualStudioCode'

    UninstallPackage -PackageId 'Anysphere.Cursor'

    UninstallPackage -PackageId 'GitHub.GitLFS'

    UninstallPackage -PackageId 'Git.Git'

    UninstallPackage -PackageId 'OpenJS.NodeJS'

    UninstallPackage -PackageId 'Docker.DockerDesktop'

    winget uninstall --id 'Microsoft.VisualStudio.2022.Community' --all-versions --accept-source-agreements
}
