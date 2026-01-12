@echo off
setlocal enabledelayedexpansion
REM =============================================================================
REM Secure API Setup Script
REM =============================================================================
REM Interactive credential setup for VEA and LibInsights APIs
REM =============================================================================

echo ====================================================
echo VEA TO LIBINSIGHTS SECURE SETUP
echo ====================================================
echo.
echo This script will prompt you to enter your API credentials
echo and store them securely.
echo.
echo Required credentials:
echo   1. VEA API (Client ID and Secret)
echo   2. LibInsights API (Client ID and Secret)
echo.

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell is available'" >nul 2>&1
if errorlevel 1 (
    echo ERROR: PowerShell is not available or not in PATH
    echo Please ensure PowerShell is installed and accessible
    pause
    exit /b 1
)

REM Test if VEA credentials exist AND work
echo Testing existing VEA credentials...
powershell -ExecutionPolicy Bypass -File "scripts\test-credentials-simple.ps1" >nul 2>&1
if %errorlevel% equ 0 (
    echo VEA credentials already configured and working.
    echo.
    goto :libinsights_setup
)

echo VEA credentials not found or not working.
echo Setting up new VEA credentials...

REM Get VEA credentials from user
echo.
echo Please enter your VEA API credentials:
echo.
set /p "CLIENT_ID=Client ID (UUID format): "
echo.
set /p "CLIENT_SECRET=Client Secret: "

echo.
echo Setting up VEA credentials securely...
powershell -ExecutionPolicy Bypass -File "scripts\setup-automated.ps1" -ClientId "%CLIENT_ID%" -ClientSecret "%CLIENT_SECRET%"

if errorlevel 1 (
    echo.
    echo ERROR: VEA credential setup failed
    echo Please check your credentials and try again.
    echo.
    echo Make sure you entered:
    echo - A valid Client ID (UUID format like 12345678-1234-1234-1234-123456789012)
    echo - A valid Client Secret (long string, typically 30+ characters)
    echo.
    pause
    exit /b 1
)

echo.
echo VEA credentials saved successfully.

:libinsights_setup
echo.
echo ====================================================
echo STEP 2: LibInsights API Credentials
echo ====================================================
echo.

REM Check if LibInsights credentials already exist
set "RECONFIGURE=n"
if exist "scripts\libinsights_credentials.xml" (
    echo LibInsights credentials file found.
    set /p "RECONFIGURE=Do you want to reconfigure LibInsights credentials? [y/N]: "
    if /i not "!RECONFIGURE!"=="y" goto :setup_complete
)

echo.
echo Please enter your LibInsights API credentials:
echo.
set /p "LI_CLIENT_ID=LibInsights Client ID: "
echo.
set /p "LI_CLIENT_SECRET=LibInsights Client Secret: "

echo.
echo Saving LibInsights credentials...
powershell -ExecutionPolicy Bypass -Command "$secureSecret = ConvertTo-SecureString '%LI_CLIENT_SECRET%' -AsPlainText -Force; @{ClientId='%LI_CLIENT_ID%'; ClientSecret=$secureSecret} | Export-Clixml 'scripts\libinsights_credentials.xml'"

if errorlevel 1 (
    echo.
    echo ERROR: LibInsights credential setup failed
    pause
    exit /b 1
)

echo LibInsights credentials saved successfully.

:setup_complete
echo.
echo ====================================================
echo ALL CREDENTIALS CONFIGURED!
echo ====================================================
echo.
echo Both VEA and LibInsights credentials are now stored securely.
echo.
echo Next Steps:
echo 1. Test the daily export: powershell -ExecutionPolicy Bypass -File "scripts\Daily-VEA-Export.ps1"
echo 2. Test the daily import: powershell -ExecutionPolicy Bypass -File "scripts\Daily-LibInsights-Import.ps1" -DryRun
echo 3. Schedule run_daily_pipeline.bat in Windows Task Scheduler
echo.
pause