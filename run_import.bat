@echo off
REM =============================================================================
REM Import existing CSV files to LibInsights
REM =============================================================================
REM This script imports the CSV files already in output/csv/ to LibInsights
REM without re-extracting from VEA
REM =============================================================================

echo ====================================================
echo IMPORT TO LIBINSIGHTS
echo ====================================================
echo.
echo This will import existing CSV files to LibInsights.
echo.
echo Options:
echo   1. Import all (gate counts + occupancy)
echo   2. Import gate counts only
echo   3. Import occupancy only
echo   4. Dry run (preview only)
echo   5. Cancel
echo.

set /p CHOICE=Enter choice (1-5): 

if "%CHOICE%"=="1" (
    echo.
    echo Importing all data...
    powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-Importer.ps1"
) else if "%CHOICE%"=="2" (
    echo.
    echo Importing gate counts only...
    powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-Importer.ps1" -GateCountsOnly
) else if "%CHOICE%"=="3" (
    echo.
    echo Importing occupancy only...
    powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-Importer.ps1" -OccupancyOnly
) else if "%CHOICE%"=="4" (
    echo.
    echo Running dry run...
    powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-Importer.ps1" -DryRun
) else (
    echo Cancelled.
    goto :EOF
)

echo.
pause
