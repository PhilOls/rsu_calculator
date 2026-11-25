param(
    [string]$RepoUrl = "https://github.com/PhilOls/rsu_calculator.git",
    [string]$InstallDir = "$env:LOCALAPPDATA\ArmRsuTaxCalculator",
    [switch]$NoDesktopShortcut,
    [switch]$NoStartMenuShortcut,
    [switch]$NoLaunch
)

$ErrorActionPreference = "Stop"

function Find-Python {
    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        return "py -3"
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        return "python"
    }

    throw "Python 3 was not found. Install Python 3 and enable 'Add python.exe to PATH'."
}

function Resolve-PythonExecutable {
    param(
        [string]$PythonCommand
    )

    if ($PythonCommand -eq "py -3") {
        $pythonPath = & py -3 -c "import sys; print(sys.executable)" 2>$null | Select-Object -First 1
        if ($LASTEXITCODE -eq 0 -and $pythonPath) {
            return [string]$pythonPath
        }
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        return $python.Source
    }

    return $null
}

function Find-GuiPython {
    param(
        [string]$PythonCommand
    )

    $pythonPath = Resolve-PythonExecutable -PythonCommand $PythonCommand
    if (-not $pythonPath) {
        return $null
    }

    $pythonwPath = Join-Path (Split-Path -Parent $pythonPath) "pythonw.exe"
    if (Test-Path $pythonwPath) {
        return $pythonwPath
    }

    return $null
}

function Start-Calculator {
    param(
        [string]$PythonCommand,
        [string]$GuiPythonPath,
        [string]$WorkingDirectory
    )

    Write-Host "Starting ARM RSU Tax Calculator..."
    if ($GuiPythonPath) {
        Start-Process -FilePath $GuiPythonPath -ArgumentList @("rsu_tax_calculator.py", "--gui") -WorkingDirectory $WorkingDirectory
        return
    }

    if ($PythonCommand -eq "py -3") {
        Start-Process -FilePath "py" -ArgumentList @("-3", "rsu_tax_calculator.py", "--gui") -WorkingDirectory $WorkingDirectory
    } else {
        Start-Process -FilePath "python" -ArgumentList @("rsu_tax_calculator.py", "--gui") -WorkingDirectory $WorkingDirectory
    }
}

function New-CalculatorShortcut {
    param(
        [string]$ShortcutPath,
        [string]$TargetPath,
        [string]$Arguments,
        [string]$WorkingDirectory,
        [string]$IconPath
    )

    $shortcutDir = Split-Path -Parent $ShortcutPath
    if ($shortcutDir) {
        New-Item -ItemType Directory -Force -Path $shortcutDir | Out-Null
    }
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath = $TargetPath
    if ($Arguments) {
        $shortcut.Arguments = $Arguments
    }
    $shortcut.WorkingDirectory = $WorkingDirectory
    $shortcut.Description = "ARM RSU French Tax Calculator"
    if ($IconPath -and (Test-Path $IconPath)) {
        $shortcut.IconLocation = $IconPath
    }
    $shortcut.Save()
}

function Invoke-PythonPip {
    param(
        [string]$PythonCommand,
        [string[]]$PipArgs
    )

    if ($PythonCommand -eq "py -3") {
        & py -3 -m pip @PipArgs 2>&1 | Out-Host
    } else {
        & python -m pip @PipArgs 2>&1 | Out-Host
    }
    return ($LASTEXITCODE -eq 0)
}

function Ensure-Pip {
    param(
        [string]$PythonCommand
    )

    $pipOk = Invoke-PythonPip -PythonCommand $PythonCommand -PipArgs @("--version")
    if ($pipOk) {
        return
    }

    Write-Host "pip was not available; trying ensurepip."
    if ($PythonCommand -eq "py -3") {
        & py -3 -m ensurepip --upgrade 2>&1 | Out-Host
    } else {
        & python -m ensurepip --upgrade 2>&1 | Out-Host
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Python pip is not available and ensurepip could not bootstrap it."
    }
}

function Install-PythonDependencies {
    param(
        [string]$PythonCommand,
        [string]$RequirementsPath,
        [string]$WheelhousePath
    )

    Write-Host "Installing Python dependencies..."
    if (Test-Path $WheelhousePath) {
        Write-Host "Trying local wheelhouse first: $WheelhousePath"
        $localExit = Invoke-PythonPip -PythonCommand $PythonCommand -PipArgs @(
            "install",
            "--disable-pip-version-check",
            "--no-index",
            "--find-links",
            $WheelhousePath,
            "-r",
            $RequirementsPath
        )
        if ($localExit) {
            return
        }
        Write-Host "Local wheelhouse install failed; trying online package index."
    }

    $onlineExit = Invoke-PythonPip -PythonCommand $PythonCommand -PipArgs @(
        "install",
        "--disable-pip-version-check",
        "--upgrade",
        "-r",
        $RequirementsPath
    )
    if (-not $onlineExit) {
        throw "Could not install Python dependencies from local wheelhouse or online package index."
    }
}

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    throw "Git was not found. Install Git for Windows or clone the repository manually."
}

$pythonCommand = Find-Python
$guiPythonPath = Find-GuiPython -PythonCommand $pythonCommand
$requirementsPath = Join-Path $InstallDir "requirements.txt"
$wheelhousePath = Join-Path $InstallDir "wheelhouse"
$iconPath = Join-Path $InstallDir "assets\rsu_tax_calculator.ico"

if (Test-Path $InstallDir) {
    Write-Host "Updating $InstallDir"
    git -C $InstallDir pull --ff-only
} else {
    Write-Host "Cloning $RepoUrl to $InstallDir"
    git clone $RepoUrl $InstallDir
}

Ensure-Pip -PythonCommand $pythonCommand
Install-PythonDependencies -PythonCommand $pythonCommand -RequirementsPath $requirementsPath -WheelhousePath $wheelhousePath

$launcherPath = Join-Path $InstallDir "Run ARM RSU Tax Calculator.cmd"
$launcher = @"
@echo off
cd /d "%~dp0"
$pythonCommand rsu_tax_calculator.py --gui %*
pause
"@
Set-Content -Path $launcherPath -Value $launcher -Encoding ASCII

$shortcutTargetPath = $launcherPath
$shortcutArguments = $null
if ($guiPythonPath) {
    $calculatorScriptPath = Join-Path $InstallDir "rsu_tax_calculator.py"
    $shortcutTargetPath = $guiPythonPath
    $shortcutArguments = "`"$calculatorScriptPath`" --gui"
}

$desktopShortcutPath = $null
if (-not $NoDesktopShortcut) {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $desktopShortcutPath = Join-Path $desktop "ARM RSU Tax Calculator.lnk"
    New-CalculatorShortcut -ShortcutPath $desktopShortcutPath -TargetPath $shortcutTargetPath -Arguments $shortcutArguments -WorkingDirectory $InstallDir -IconPath $iconPath
    Write-Host "Created desktop shortcut: $desktopShortcutPath"
}

$startMenuShortcutPath = $null
if (-not $NoStartMenuShortcut) {
    $programs = [Environment]::GetFolderPath("Programs")
    $startMenuShortcutPath = Join-Path $programs "ARM RSU Tax Calculator.lnk"
    New-CalculatorShortcut -ShortcutPath $startMenuShortcutPath -TargetPath $shortcutTargetPath -Arguments $shortcutArguments -WorkingDirectory $InstallDir -IconPath $iconPath
    Write-Host "Created Start Menu shortcut: $startMenuShortcutPath"
}

Write-Host ""
Write-Host "Installed ARM RSU Tax Calculator in: $InstallDir"
Write-Host "Launcher: $launcherPath"
if ($guiPythonPath) {
    Write-Host "GUI shortcuts target: $guiPythonPath"
} else {
    Write-Host "pythonw.exe was not found; shortcuts use the console launcher."
}
if ($desktopShortcutPath) {
    Write-Host "Desktop shortcut: $desktopShortcutPath"
}
if ($startMenuShortcutPath) {
    Write-Host "Start Menu shortcut: $startMenuShortcutPath"
}
Write-Host ""
Write-Host "If the calculator window does not open automatically, start it from the Desktop shortcut"
Write-Host "or search for 'ARM RSU Tax Calculator' in the Windows Start Menu."

if (-not $NoLaunch) {
    Start-Calculator -PythonCommand $pythonCommand -GuiPythonPath $guiPythonPath -WorkingDirectory $InstallDir
}
