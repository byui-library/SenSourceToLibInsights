@echo off
REM =============================================================================
REM Daily VEA to LibInsights Pipeline
REM =============================================================================
REM Purpose: Single batch file for Windows Task Scheduler that runs:
REM          1. Daily VEA Export (extracts yesterday's data)
REM          2. Daily LibInsights Import (uploads to LibInsights)
REM
REM Usage: run_daily_pipeline.bat
REM        Schedule this in Windows Task Scheduler to run nightly (e.g., 2:00 AM)
REM =============================================================================

echo.
echo ======================================================
echo DAILY VEA TO LIBINSIGHTS PIPELINE
echo ======================================================
echo Start Time: %DATE% %TIME%
echo.

REM Change to script directory
cd /d "%~dp0"

echo Step 1/2: Exporting previous day's VEA data...
echo.
powershell -ExecutionPolicy Bypass -File "scripts\Daily-VEA-Export.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: VEA Export failed with exit code %ERRORLEVEL%
    echo Pipeline aborted.
    exit /b 1
)

echo.
echo Step 2/2: Importing data to LibInsights...
echo.
powershell -ExecutionPolicy Bypass -File "scripts\Daily-LibInsights-Import.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: LibInsights Import failed with exit code %ERRORLEVEL%
    exit /b 1
)

echo.
echo ======================================================
echo DAILY PIPELINE COMPLETE
echo End Time: %DATE% %TIME%
echo ======================================================
echo.

exit /b 0
