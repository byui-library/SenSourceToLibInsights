@echo off
REM Secure API Setup Script
REM Interactive credential setup for VEA and LibInsights APIs

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

REM Test if credentials exist AND work
echo Testing existing credentials...
powershell -ExecutionPolicy Bypass -File "scripts\test-credentials-simple.ps1" >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo ====================================================
    echo CREDENTIALS ALREADY CONFIGURED AND WORKING!
    echo ====================================================
    echo.
    echo Your VEA API credentials are properly set up.
    echo You can now run the export pipeline with: run_export.bat
    echo.
    pause
    exit /b 0
)

echo Existing credentials not found or not working.
echo Setting up new credentials...

REM Get credentials from user
echo.
echo Please enter your VEA API credentials:
echo.
set /p "CLIENT_ID=Client ID (UUID format): "
echo.
set /p "CLIENT_SECRET=Client Secret: "

echo.
echo Setting up credentials securely...
powershell -ExecutionPolicy Bypass -File "scripts\setup-automated.ps1" -ClientId "%CLIENT_ID%" -ClientSecret "%CLIENT_SECRET%"

if errorlevel 1 (
    echo.
    echo ERROR: Credential setup failed
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
echo ====================================================
echo SETUP COMPLETE!
echo ====================================================
echo.
echo Your VEA API credentials are now stored securely in Windows Credential Manager.
echo.
echo ====================================================
echo STEP 2: LibInsights API Credentials
echo ====================================================
echo.
echo Now setting up LibInsights API credentials...
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