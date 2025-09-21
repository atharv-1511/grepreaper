@echo off
echo ========================================
echo Windows Setup for grepreaper Package
echo ========================================
echo.

REM Check if R is available
where R >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: R is not found in PATH
    echo Please install R and add it to your PATH
    echo Download from: https://cran.r-project.org/bin/windows/base/
    pause
    exit /b 1
)

echo R found. Starting setup...
echo.

REM Run the setup script
R --slave --no-restore --file=WINDOWS_SETUP.R

echo.
echo Setup completed!
echo You can now open R/RStudio and use the grepreaper package.
pause
