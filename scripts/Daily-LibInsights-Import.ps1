# =============================================================================
# Daily LibInsights Import Script
# =============================================================================
# Purpose: Import VEA CSV files from output directory into LibInsights
# 
# Usage:
#   .\Daily-LibInsights-Import.ps1              # Import all data
#   .\Daily-LibInsights-Import.ps1 -GateCountsOnly   # Gate counts only
#   .\Daily-LibInsights-Import.ps1 -OccupancyOnly    # Occupancy only
#   .\Daily-LibInsights-Import.ps1 -DryRun           # Preview only
#
# Designed for Windows Task Scheduler nightly automation
# Note: LibInsights API rejects duplicate records, so re-running is safe
# =============================================================================

param(
    [switch]$GateCountsOnly,
    [switch]$OccupancyOnly,
    [switch]$DryRun
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
$LogFile = Join-Path $LogDir "daily-import-$LogDate.log"

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

Write-Log "=============================================="
Write-Log "DAILY LIBINSIGHTS IMPORT - Starting"
Write-Log "=============================================="
Write-Log "Mode: $(if ($DryRun) { 'DRY RUN (preview only)' } elseif ($GateCountsOnly) { 'Gate Counts Only' } elseif ($OccupancyOnly) { 'Occupancy Only' } else { 'Full Import' })"
Write-Log "Log File: $LogFile"

# Check if LibInsights-Importer.ps1 exists
$importerScript = Join-Path $ScriptDir "LibInsights-Importer.ps1"
if (-not (Test-Path $importerScript)) {
    Write-Log "LibInsights-Importer.ps1 not found at: $importerScript" "ERROR"
    exit 1
}

# Verify CSV files exist
$gateCountsDir = Join-Path $ProjectRoot "output\csv\gate_counts"
$occupancyDir = Join-Path $ProjectRoot "output\csv\occupancy"

$gateCountFiles = Get-ChildItem -Path $gateCountsDir -Filter "*.csv" -ErrorAction SilentlyContinue
$occupancyFiles = Get-ChildItem -Path $occupancyDir -Filter "*.csv" -ErrorAction SilentlyContinue

Write-Log "Found files to import:"
Write-Log "  Gate count files: $($gateCountFiles.Count)"
Write-Log "  Occupancy files: $($occupancyFiles.Count)"

if ($gateCountFiles.Count -eq 0 -and $occupancyFiles.Count -eq 0) {
    Write-Log "No CSV files found to import. Run Daily-VEA-Export.ps1 first." "ERROR"
    exit 1
}

# Build parameters for the importer
$importerParams = @{}
if ($GateCountsOnly) { $importerParams.GateCountsOnly = $true }
if ($OccupancyOnly) { $importerParams.OccupancyOnly = $true }
if ($DryRun) { $importerParams.DryRun = $true }

# Run the import
Write-Log "Running LibInsights-Importer.ps1..."

try {
    & $importerScript @importerParams
    
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
        Write-Log "LibInsights-Importer.ps1 exited with code: $LASTEXITCODE" "ERROR"
        exit 1
    }
    
    if ($DryRun) {
        Write-Log "Dry run completed - no data was imported" "SUCCESS"
    } else {
        Write-Log "LibInsights import completed successfully" "SUCCESS"
    }
    
} catch {
    Write-Log "Error during import: $_" "ERROR"
    exit 1
}

Write-Log "=============================================="
Write-Log "DAILY LIBINSIGHTS IMPORT - Complete"
Write-Log "=============================================="

exit 0
