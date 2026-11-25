@echo off
setlocal

cd /d "%~dp0"

where py >nul 2>nul
if %ERRORLEVEL%==0 (
    py -3 rsu_tax_calculator.py --gui %*
    goto :eof
)

where python >nul 2>nul
if %ERRORLEVEL%==0 (
    python rsu_tax_calculator.py --gui %*
    goto :eof
)

echo Python 3 was not found.
echo Install Python 3 from https://www.python.org/downloads/windows/ and enable "Add python.exe to PATH".
pause
exit /b 1
