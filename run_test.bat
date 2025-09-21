@echo off
echo Running grepreaper cross-device test...
echo.

REM Check if R is available
where R >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: R is not found in PATH
    echo Please install R and add it to your PATH
    pause
    exit /b 1
)

REM Run the test
echo Starting test...
R --slave --no-restore --file=quick_test.R

echo.
echo Test completed!
pause
