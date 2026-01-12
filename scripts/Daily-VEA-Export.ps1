# =============================================================================
# Daily VEA Export Script
# =============================================================================
# Purpose: Export previous day's VEA sensor data to CSV files
# 
# Usage:
#   .\Daily-VEA-Export.ps1                    # Export yesterday's data
#   .\Daily-VEA-Export.ps1 -DaysBack 2        # Export data from 2 days ago
#   .\Daily-VEA-Export.ps1 -SpecificDate "2026-01-10"  # Export specific date
#
# Designed for Windows Task Scheduler nightly automation
# =============================================================================

param(
    [int]$DaysBack = 1,
    [string]$SpecificDate = ""
)

$ErrorActionPreference = "Stop"

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$LogDir = Join-Path $ProjectRoot "logs"

# Ensure log directory exists
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Set up logging
$LogDate = Get-Date -Format "yyyy-MM-dd"
$LogFile = Join-Path $LogDir "daily-export-$LogDate.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry
    
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN"  { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host $logEntry -ForegroundColor $color
}

# Calculate date range
if (-not [string]::IsNullOrWhiteSpace($SpecificDate)) {
    try {
        $targetDate = [DateTime]::ParseExact($SpecificDate, "yyyy-MM-dd", $null)
    } catch {
        Write-Log "Invalid date format. Use yyyy-MM-dd (e.g., 2026-01-10)" "ERROR"
        exit 1
    }
} else {
    $targetDate = (Get-Date).AddDays(-$DaysBack).Date
}

$StartDate = $targetDate.ToString("yyyy-MM-ddT00:00:00Z")
$EndDate = $targetDate.ToString("yyyy-MM-ddT23:59:59Z")

Write-Log "=============================================="
Write-Log "DAILY VEA EXPORT - Starting"
Write-Log "=============================================="
Write-Log "Target Date: $($targetDate.ToString('yyyy-MM-dd'))"
Write-Log "Start: $StartDate"
Write-Log "End: $EndDate"
Write-Log "Log File: $LogFile"

# Check if VEA-Zone-Extractor.ps1 exists
$extractorScript = Join-Path $ScriptDir "VEA-Zone-Extractor.ps1"
if (-not (Test-Path $extractorScript)) {
    Write-Log "VEA-Zone-Extractor.ps1 not found at: $extractorScript" "ERROR"
    exit 1
}

# Run the extraction
Write-Log "Running VEA-Zone-Extractor.ps1..."

try {
    $extractorParams = @{
        StartDate = $StartDate
        EndDate = $EndDate
    }
    
    & $extractorScript @extractorParams
    
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
        Write-Log "VEA-Zone-Extractor.ps1 exited with code: $LASTEXITCODE" "ERROR"
        exit 1
    }
    
    Write-Log "VEA data extraction completed successfully" "SUCCESS"
    
} catch {
    Write-Log "Error during extraction: $_" "ERROR"
    exit 1
}

# Verify output files were created
$gateCountsDir = Join-Path $ProjectRoot "output\csv\gate_counts"
$occupancyDir = Join-Path $ProjectRoot "output\csv\occupancy"

$gateCountFiles = Get-ChildItem -Path $gateCountsDir -Filter "*.csv" -ErrorAction SilentlyContinue
$occupancyFiles = Get-ChildItem -Path $occupancyDir -Filter "*.csv" -ErrorAction SilentlyContinue

Write-Log "Output verification:"
Write-Log "  Gate count files: $($gateCountFiles.Count)"
Write-Log "  Occupancy files: $($occupancyFiles.Count)"

if ($gateCountFiles.Count -eq 0 -and $occupancyFiles.Count -eq 0) {
    Write-Log "WARNING: No CSV files found in output directories" "WARN"
}

Write-Log "=============================================="
Write-Log "DAILY VEA EXPORT - Complete"
Write-Log "=============================================="

exit 0
