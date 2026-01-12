@echo off
REM =============================================================================
REM VEA to LibInsights Full Pipeline
REM =============================================================================
REM This script runs the complete pipeline:
REM   1. Extract data from VEA API
REM   2. Generate CSV files
REM   3. Import into LibInsights
REM =============================================================================

echo ====================================================
echo VEA TO LIBINSIGHTS FULL PIPELINE
echo ====================================================
echo.
echo This will:
echo   1. Extract VEA sensor data (current year to date)
echo   2. Generate CSV files for gate counts and occupancy
echo   3. Import all data into LibInsights
echo.

set /p CONFIRM=Do you want to continue? (Y/N): 
if /i not "%CONFIRM%"=="Y" goto :EOF

echo.
echo Step 1: Extracting VEA data...
echo --------------------------------------------------------
powershell -ExecutionPolicy Bypass -File "scripts\VEA-Zone-Extractor.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: VEA extraction failed!
    pause
    exit /b 1
)

echo.
echo Step 2: Importing to LibInsights...
echo --------------------------------------------------------
powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-Importer.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: LibInsights import failed!
    pause
    exit /b 1
)

echo.
echo ====================================================
echo PIPELINE COMPLETE!
echo ====================================================
echo.
echo Data has been extracted from VEA and imported to LibInsights.
echo.
pause
