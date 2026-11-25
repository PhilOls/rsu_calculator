@echo off
setlocal

set "INSTALL_PS1=%~dp0install_windows.ps1"

if exist "%INSTALL_PS1%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%INSTALL_PS1%" %*
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/PhilOls/rsu_calculator/main/install_windows.ps1' | iex"
)

if errorlevel 1 (
    echo.
    echo Installation failed.
    pause
    exit /b 1
)

echo.
echo Installation completed.
echo.
echo If the calculator window did not open automatically, double-click
echo "ARM RSU Tax Calculator" on your Desktop, or search for it
echo from the Windows Start Menu.
echo.
pause
exit /b 0
