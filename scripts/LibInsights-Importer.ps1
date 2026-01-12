# =============================================================================
# LibInsights Gate Count Importer
# =============================================================================
# Purpose: Import VEA gate count/occupancy data from CSV files into LibInsights
# 
# Usage:
#   .\LibInsights-Importer.ps1                    # Import all CSV files
#   .\LibInsights-Importer.ps1 -GateCountsOnly    # Import only gate counts
#   .\LibInsights-Importer.ps1 -OccupancyOnly     # Import only occupancy data
#   .\LibInsights-Importer.ps1 -DryRun            # Preview without importing
#   .\LibInsights-Importer.ps1 -TestSingle        # Test with single record
# =============================================================================

param(
    [switch]$GateCountsOnly,
    [switch]$OccupancyOnly,
    [switch]$DryRun,
    [switch]$TestSingle,
    [int]$BatchSize = 100
)

# =============================================================================
# Configuration
# =============================================================================

$LibInsightsBaseUrl = "https://byui.libinsight.com/v1.0"
$GateCountDatasetId = "43702"      # SenSource Gate Count By Entrance
$OccupancyDatasetId = "43600"      # SenSource Occupancy Rates

# Gate ID Mapping: CSV filename pattern -> LibInsights gate_id
$GateIdMapping = @{
    "West Wing Level 1 East Side"  = 12  # McKay_Library_Level_1_Main_Entrance_1
    "West Wing Level 1 West Side"  = 13  # McKay_Library_Level_1_New_Entrance
    "West Wing Level 2 Stairs"     = 14  # McKay_Library_Level_2_Stairs
    "West Wing Level 3 Bridge"     = 15  # McKay_Library_Level_3_Bridge
    "West Wing Level 3 Stairs"     = 16  # McKay_Library_Level_3_Stairs
}

# Script paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$GateCountsDir = Join-Path $ProjectRoot "output\csv\gate_counts"
$OccupancyDir = Join-Path $ProjectRoot "output\csv\occupancy"
$CredentialFile = Join-Path $ScriptDir "libinsights_credentials.xml"

# =============================================================================
# Credential Management
# =============================================================================

function Get-LibInsightsCredentials {
    if (-not (Test-Path $CredentialFile)) {
        Write-Host "LibInsights credentials not found!" -ForegroundColor Red
        Write-Host "Please run: .\LibInsights-API-Explorer.ps1 -SaveCredentials" -ForegroundColor Yellow
        return $null
    }
    
    try {
        $storedCred = Import-Clixml $CredentialFile
        return @{
            ClientId = $storedCred.ClientId
            ClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($storedCred.ClientSecret)
            )
        }
    }
    catch {
        Write-Host "Failed to read credentials: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# =============================================================================
# API Functions
# =============================================================================

function Get-LibInsightsAccessToken {
    param(
        [string]$ClientId,
        [string]$ClientSecret
    )
    
    $tokenUrl = "$LibInsightsBaseUrl/oauth/token"
    
    $body = @{
        client_id = $ClientId
        client_secret = $ClientSecret
        grant_type = "client_credentials"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
        return $response.access_token
    }
    catch {
        Write-Host "Authentication failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Send-GateCountData {
    param(
        [string]$AccessToken,
        [string]$DatasetId,
        [array]$Records
    )
    
    $url = "$LibInsightsBaseUrl/gate-count/$DatasetId/save"
    $headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type" = "application/json"
    }
    
    $body = $Records | ConvertTo-Json -Depth 10
    
    # Ensure it's always an array in JSON
    if ($Records.Count -eq 1) {
        $body = "[$body]"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
        return $response
    }
    catch {
        $errorMsg = $_.Exception.Message
        if ($_.ErrorDetails.Message) {
            $errorMsg += " - $($_.ErrorDetails.Message)"
        }
        Write-Host "  API Error: $errorMsg" -ForegroundColor Red
        return $null
    }
}

# =============================================================================
# Data Processing Functions
# =============================================================================

function Get-GateIdFromFileName {
    param([string]$FileName)
    
    foreach ($pattern in $GateIdMapping.Keys) {
        if ($FileName -like "*$pattern*") {
            return $GateIdMapping[$pattern]
        }
    }
    
    Write-Host "  Warning: No gate_id mapping found for: $FileName" -ForegroundColor Yellow
    return $null
}

function Import-CsvToRecords {
    param(
        [string]$CsvPath,
        [int]$GateId,
        [bool]$IncludeGateEnd = $false
    )
    
    $records = @()
    $skippedZeros = 0
    $csvData = Import-Csv -Path $CsvPath
    
    foreach ($row in $csvData) {
        $gateStart = [int]$row.gate_start
        $gateEnd = if ($row.gate_end) { [int]$row.gate_end } else { 0 }
        
        # Skip records where both gate_start and gate_end are 0
        # LibInsights API rejects these with 400 Bad Request
        if ($IncludeGateEnd -and $gateStart -eq 0 -and $gateEnd -eq 0) {
            $skippedZeros++
            continue
        }
        
        $record = @{
            gate_id = $GateId
            date = $row.date
            gate_start = $gateStart
        }
        
        if ($IncludeGateEnd -and $row.gate_end) {
            $record.gate_end = $gateEnd
        }
        
        $records += $record
    }
    
    if ($skippedZeros -gt 0) {
        Write-Host "    Skipped $skippedZeros zero-traffic records" -ForegroundColor Gray
    }
    
    return $records
}

function Send-RecordsInBatches {
    param(
        [string]$AccessToken,
        [string]$DatasetId,
        [array]$Records,
        [int]$BatchSize,
        [string]$FileName
    )
    
    $totalRecords = $Records.Count
    $totalBatches = [math]::Ceiling($totalRecords / $BatchSize)
    $successCount = 0
    $failCount = 0
    
    for ($i = 0; $i -lt $totalRecords; $i += $BatchSize) {
        $batchNum = [math]::Floor($i / $BatchSize) + 1
        $endIndex = [math]::Min($i + $BatchSize - 1, $totalRecords - 1)
        $batch = $Records[$i..$endIndex]
        
        Write-Host "    Batch $batchNum/$totalBatches ($($batch.Count) records)..." -NoNewline
        
        $response = Send-GateCountData -AccessToken $AccessToken -DatasetId $DatasetId -Records $batch
        
        if ($response -and $response.type -eq "success") {
            $successCount += $response.payload.result
            Write-Host " OK ($($response.payload.result) imported)" -ForegroundColor Green
        }
        else {
            $failCount += $batch.Count
            Write-Host " FAILED" -ForegroundColor Red
        }
        
        # Small delay between batches to avoid rate limiting
        Start-Sleep -Milliseconds 200
    }
    
    return @{
        Success = $successCount
        Failed = $failCount
    }
}

# =============================================================================
# Main Import Function
# =============================================================================

function Import-GateCountFiles {
    param(
        [string]$AccessToken,
        [string]$Directory,
        [string]$DatasetId,
        [bool]$IncludeGateEnd,
        [string]$DataType
    )
    
    if (-not (Test-Path $Directory)) {
        Write-Host "Directory not found: $Directory" -ForegroundColor Yellow
        return @{ TotalSuccess = 0; TotalFailed = 0; FilesProcessed = 0 }
    }
    
    $csvFiles = Get-ChildItem -Path $Directory -Filter "*.csv"
    
    if ($csvFiles.Count -eq 0) {
        Write-Host "No CSV files found in: $Directory" -ForegroundColor Yellow
        return @{ TotalSuccess = 0; TotalFailed = 0; FilesProcessed = 0 }
    }
    
    Write-Host "`nProcessing $DataType files from: $Directory" -ForegroundColor Cyan
    Write-Host "Found $($csvFiles.Count) CSV files" -ForegroundColor Gray
    
    $totalSuccess = 0
    $totalFailed = 0
    $filesProcessed = 0
    
    foreach ($csvFile in $csvFiles) {
        Write-Host "`n  File: $($csvFile.Name)" -ForegroundColor White
        
        $gateId = Get-GateIdFromFileName -FileName $csvFile.Name
        
        if (-not $gateId) {
            Write-Host "    Skipping - no gate_id mapping" -ForegroundColor Yellow
            continue
        }
        
        Write-Host "    Gate ID: $gateId" -ForegroundColor Gray
        
        # Load CSV data
        $records = Import-CsvToRecords -CsvPath $csvFile.FullName -GateId $gateId -IncludeGateEnd $IncludeGateEnd
        Write-Host "    Records: $($records.Count)" -ForegroundColor Gray
        
        if ($records.Count -eq 0) {
            Write-Host "    Skipping - no records" -ForegroundColor Yellow
            continue
        }
        
        if ($DryRun) {
            Write-Host "    [DRY RUN] Would import $($records.Count) records" -ForegroundColor Cyan
            Write-Host "    Sample record: $($records[0] | ConvertTo-Json -Compress)" -ForegroundColor Gray
            $filesProcessed++
            continue
        }
        
        if ($TestSingle) {
            # Only send first record for testing
            Write-Host "    [TEST] Sending single record..." -ForegroundColor Cyan
            $testRecord = @($records[0])
            Write-Host "    Record: $($testRecord | ConvertTo-Json -Compress)" -ForegroundColor Gray
            
            $response = Send-GateCountData -AccessToken $AccessToken -DatasetId $DatasetId -Records $testRecord
            
            if ($response) {
                Write-Host "    Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
                if ($response.type -eq "success") {
                    Write-Host "    Test successful!" -ForegroundColor Green
                    $totalSuccess++
                }
            }
            $filesProcessed++
            continue
        }
        
        # Send in batches
        $result = Send-RecordsInBatches -AccessToken $AccessToken -DatasetId $DatasetId -Records $records -BatchSize $BatchSize -FileName $csvFile.Name
        
        $totalSuccess += $result.Success
        $totalFailed += $result.Failed
        $filesProcessed++
    }
    
    return @{
        TotalSuccess = $totalSuccess
        TotalFailed = $totalFailed
        FilesProcessed = $filesProcessed
    }
}

# =============================================================================
# Main Script
# =============================================================================

Write-Host "=" * 60 -ForegroundColor Blue
Write-Host "LibInsights Gate Count Importer" -ForegroundColor Blue
Write-Host "=" * 60 -ForegroundColor Blue

if ($DryRun) {
    Write-Host "`n[DRY RUN MODE - No data will be imported]" -ForegroundColor Yellow
}

if ($TestSingle) {
    Write-Host "`n[TEST MODE - Only single records will be sent]" -ForegroundColor Yellow
}

# Get credentials
Write-Host "`nStep 1: Loading credentials..." -ForegroundColor Cyan
$credentials = Get-LibInsightsCredentials

if (-not $credentials) {
    exit 1
}

Write-Host "  Credentials loaded" -ForegroundColor Green

# Authenticate
Write-Host "`nStep 2: Authenticating with LibInsights..." -ForegroundColor Cyan
$accessToken = Get-LibInsightsAccessToken -ClientId $credentials.ClientId -ClientSecret $credentials.ClientSecret

if (-not $accessToken) {
    Write-Host "Authentication failed!" -ForegroundColor Red
    exit 1
}

Write-Host "  Authentication successful" -ForegroundColor Green

# Import Gate Counts
$gateCountResults = @{ TotalSuccess = 0; TotalFailed = 0; FilesProcessed = 0 }
$occupancyResults = @{ TotalSuccess = 0; TotalFailed = 0; FilesProcessed = 0 }

if (-not $OccupancyOnly) {
    Write-Host "`n" + "=" * 60 -ForegroundColor Yellow
    Write-Host "Step 3: Importing Gate Count Data" -ForegroundColor Yellow
    Write-Host "  Dataset ID: $GateCountDatasetId" -ForegroundColor Gray
    Write-Host "  Endpoint: POST /gate-count/$GateCountDatasetId/save" -ForegroundColor Gray
    Write-Host "=" * 60 -ForegroundColor Yellow
    
    $gateCountResults = Import-GateCountFiles `
        -AccessToken $accessToken `
        -Directory $GateCountsDir `
        -DatasetId $GateCountDatasetId `
        -IncludeGateEnd $false `
        -DataType "Gate Count"
}

# Import Occupancy Data
if (-not $GateCountsOnly) {
    Write-Host "`n" + "=" * 60 -ForegroundColor Yellow
    Write-Host "Step 4: Importing Occupancy Data" -ForegroundColor Yellow
    Write-Host "  Dataset ID: $GateCountDatasetId" -ForegroundColor Gray
    Write-Host "  Note: Using same gate-count endpoint with gate_end values" -ForegroundColor Gray
    Write-Host "=" * 60 -ForegroundColor Yellow
    
    $occupancyResults = Import-GateCountFiles `
        -AccessToken $accessToken `
        -Directory $OccupancyDir `
        -DatasetId $GateCountDatasetId `
        -IncludeGateEnd $true `
        -DataType "Occupancy"
}

# Summary
Write-Host "`n" + "=" * 60 -ForegroundColor Green
Write-Host "IMPORT COMPLETE" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green

Write-Host "`nGate Count Import:" -ForegroundColor White
Write-Host "  Files Processed: $($gateCountResults.FilesProcessed)" -ForegroundColor Gray
Write-Host "  Records Imported: $($gateCountResults.TotalSuccess)" -ForegroundColor Green
if ($gateCountResults.TotalFailed -gt 0) {
    Write-Host "  Records Failed: $($gateCountResults.TotalFailed)" -ForegroundColor Red
}

Write-Host "`nOccupancy Import:" -ForegroundColor White
Write-Host "  Files Processed: $($occupancyResults.FilesProcessed)" -ForegroundColor Gray
Write-Host "  Records Imported: $($occupancyResults.TotalSuccess)" -ForegroundColor Green
if ($occupancyResults.TotalFailed -gt 0) {
    Write-Host "  Records Failed: $($occupancyResults.TotalFailed)" -ForegroundColor Red
}

$grandTotal = $gateCountResults.TotalSuccess + $occupancyResults.TotalSuccess
Write-Host "`nTotal Records Imported: $grandTotal" -ForegroundColor Cyan
