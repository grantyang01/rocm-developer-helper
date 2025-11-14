. "$PSScriptRoot\tools.ps1"
. "$PSScriptRoot\git_helper.ps1"
. "$PSScriptRoot\p4_helper.ps1"

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
        
        # Configure P4 settings from config.yaml
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
        Write-Host "Installing VisualStudio 2022 Community..." -ForegroundColor Cyan
        # components required by shisa development
        $vsOverrideOptions = "--add Microsoft.VisualStudio.Workload.NativeDesktop " + `
                             "--add Microsoft.VisualStudio.Workload.ManagedDesktop " + `
                             "--add Microsoft.VisualStudio.Workload.VisualStudioExtension " + `
                             "--add Microsoft.VisualStudio.Component.Windows11SDK.26100 " + `
                             "--add Microsoft.VisualStudio.ComponentGroup.VC.Tools.142.x86.x64 " + `
                             "--add Microsoft.VisualStudio.Component.VC.14.29.16.11.x86.x64.Spectre " + `
                             "--add Microsoft.Net.Component.4.8.TargetingPack " + `
                             "--add Microsoft.VisualStudio.Component.TextTemplating " + `
                             "--add Microsoft.VisualStudio.Component.DslTools " + `
                             "--includeRecommended"

        InstallPackage -PackageId 'Microsoft.VisualStudio.2022.Community' `
                       -OverrideOptions $vsOverrideOptions

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

<#
visual studio 2022
SHISA need below visual studio components. To look up the id from component name refer to the links for the latest ids:
    https://learn.microsoft.com/en-us/visualstudio/install/workload-and-component-ids?view=vs-2022
    https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community?view=vs-2022&preserve-view=true

Below are current name to id maps, and component ID might evolve, so always refer to the links for the latest info:
name                                                                        id
Desktop development with C++                                                Microsoft.VisualStudio.Workload.NativeDesktop
.NET desktop development                                                    Microsoft.VisualStudio.Workload.ManagedDesktop
Visual Studio extension development                                         Microsoft.VisualStudio.Workload.VisualStudioExtension
Windows 11 SDK (10.0.26100.3916)                                            Microsoft.VisualStudio.Component.Windows11SDK.26100
MSVC v142 - VS 2019 C++ x64/x86 build tools (v14.29)                        Microsoft.VisualStudio.ComponentGroup.VC.Tools.142.x86.x64
MSVC v142 - VS 2019 C++ x64/x86 Spectre-mitigated libs (v14.29-16.11)       Microsoft.VisualStudio.Component.VC.14.29.16.11.x86.x64.Spectre
.NET Framework 4.8 targeting pack                                           Microsoft.Net.Component.4.8.TargetingPack
Text Template Transformation                                                Microsoft.VisualStudio.Component.TextTemplating
Modeling SDK                                                                Microsoft.VisualStudio.Component.DslTools
#>
