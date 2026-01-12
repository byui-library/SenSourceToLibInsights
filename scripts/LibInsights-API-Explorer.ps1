# =============================================================================
# LibInsights API Explorer
# =============================================================================
# Purpose: Explore LibInsights API to understand data structures and test authentication
# This script will help us understand what format is needed for importing VEA data
# =============================================================================

param(
    [switch]$SaveCredentials,
    [switch]$TestOnly
)

# Configuration
$LibInsightsBaseUrl = "https://byui.libinsight.com/v1.0"
$GateCountDatasetId = "43702"      # SenSource Gate Count By Entrance
$OccupancyDatasetId = "43600"      # SenSource Occupancy Rates

# Credential Management Functions
function Get-LibInsightsCredentials {
    # Try Windows Credential Manager first
    try {
        $cred = Get-StoredCredential -Target "LibInsights_API" -ErrorAction SilentlyContinue
        if ($cred) {
            return @{
                ClientId = $cred.UserName
                ClientSecret = $cred.GetNetworkCredential().Password
            }
        }
    } catch {
        # Cmdlet not available, try alternative method
    }
    
    # Try using cmdkey-based retrieval
    try {
        $credTarget = "LibInsights_API"
        $cred = [System.Net.CredentialCache]::DefaultNetworkCredentials
        
        # Check if credentials are stored in a file (encrypted)
        $credFile = Join-Path $PSScriptRoot "libinsights_credentials.xml"
        if (Test-Path $credFile) {
            $storedCred = Import-Clixml $credFile
            return @{
                ClientId = $storedCred.ClientId
                ClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($storedCred.ClientSecret)
                )
            }
        }
    } catch {
        # Continue to prompt
    }
    
    # Prompt for credentials if not found
    Write-Host "`nLibInsights API credentials not found in secure storage." -ForegroundColor Yellow
    Write-Host "Please enter your credentials (they will be saved securely):`n" -ForegroundColor Yellow
    
    $clientId = Read-Host "Enter Client ID"
    $clientSecret = Read-Host "Enter Client Secret" -AsSecureString
    
    # Save credentials
    $credFile = Join-Path $PSScriptRoot "libinsights_credentials.xml"
    $credToSave = @{
        ClientId = $clientId
        ClientSecret = $clientSecret
    }
    $credToSave | Export-Clixml $credFile
    
    Write-Host "Credentials saved to: $credFile" -ForegroundColor Green
    
    return @{
        ClientId = $clientId
        ClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret)
        )
    }
}

function Save-LibInsightsCredentials {
    param(
        [string]$ClientId,
        [string]$ClientSecret
    )
    
    $credFile = Join-Path $PSScriptRoot "libinsights_credentials.xml"
    $secureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
    
    $credToSave = @{
        ClientId = $ClientId
        ClientSecret = $secureSecret
    }
    $credToSave | Export-Clixml $credFile
    
    Write-Host "Credentials saved securely to: $credFile" -ForegroundColor Green
}

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
        Write-Host "Requesting access token from: $tokenUrl" -ForegroundColor Cyan
        
        $response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
        
        Write-Host "Authentication successful!" -ForegroundColor Green
        Write-Host "  Token Type: $($response.token_type)" -ForegroundColor Gray
        Write-Host "  Expires In: $($response.expires_in) seconds" -ForegroundColor Gray
        
        return $response.access_token
    }
    catch {
        Write-Host "Authentication failed!" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
        return $null
    }
}

function Invoke-LibInsightsApi {
    param(
        [string]$Endpoint,
        [string]$AccessToken,
        [string]$Method = "GET",
        [object]$Body = $null
    )
    
    $url = "$LibInsightsBaseUrl$Endpoint"
    $headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type" = "application/json"
    }
    
    try {
        Write-Host "`n$Method $url" -ForegroundColor Cyan
        
        $params = @{
            Uri = $url
            Method = $Method
            Headers = $headers
        }
        
        if ($Body -and $Method -ne "GET") {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
            Write-Host "Request Body:" -ForegroundColor Gray
            Write-Host ($Body | ConvertTo-Json -Depth 5) -ForegroundColor Gray
        }
        
        $response = Invoke-RestMethod @params
        return $response
    }
    catch {
        Write-Host "API call failed!" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
        return $null
    }
}

# =============================================================================
# Main Exploration Script
# =============================================================================

Write-Host "=" * 60 -ForegroundColor Blue
Write-Host "LibInsights API Explorer" -ForegroundColor Blue
Write-Host "=" * 60 -ForegroundColor Blue

# Handle credential saving
if ($SaveCredentials) {
    Write-Host "`nSaving LibInsights credentials..." -ForegroundColor Yellow
    $clientId = Read-Host "Enter Client ID"
    $clientSecret = Read-Host "Enter Client Secret"
    Save-LibInsightsCredentials -ClientId $clientId -ClientSecret $clientSecret
    Write-Host "Done!" -ForegroundColor Green
    exit
}

# Get credentials
$credentials = Get-LibInsightsCredentials

if (-not $credentials.ClientId -or -not $credentials.ClientSecret) {
    Write-Host "No credentials available. Run with -SaveCredentials to set up." -ForegroundColor Red
    exit 1
}

# Step 1: Get Access Token
Write-Host "`n" + "=" * 60 -ForegroundColor Yellow
Write-Host "Step 1: Authentication" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Yellow

$accessToken = Get-LibInsightsAccessToken -ClientId $credentials.ClientId -ClientSecret $credentials.ClientSecret

if (-not $accessToken) {
    Write-Host "Failed to authenticate. Please check your credentials." -ForegroundColor Red
    exit 1
}

if ($TestOnly) {
    Write-Host "`nAuthentication test successful!" -ForegroundColor Green
    exit 0
}

# Step 2: Explore Gate Count Dataset
Write-Host "`n" + "=" * 60 -ForegroundColor Yellow
Write-Host "Step 2: Exploring Gate Count Dataset (ID: $GateCountDatasetId)" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Yellow

# Get libraries/gates configuration
Write-Host "`nFetching Gate Count Libraries..." -ForegroundColor Cyan
$gateCountLibraries = Invoke-LibInsightsApi -Endpoint "/gate-count/$GateCountDatasetId/libraries" -AccessToken $accessToken

if ($gateCountLibraries) {
    Write-Host "`nGate Count Libraries/Gates Configuration:" -ForegroundColor Green
    $gateCountLibraries | ConvertTo-Json -Depth 10 | Write-Host
    
    # Save to file for reference
    $outputDir = Join-Path (Split-Path $PSScriptRoot -Parent) "output\json"
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    $gateCountLibraries | ConvertTo-Json -Depth 10 | Out-File (Join-Path $outputDir "libinsights_gate_count_libraries.json") -Encoding UTF8
    Write-Host "`nSaved to: output\json\libinsights_gate_count_libraries.json" -ForegroundColor Gray
}

# Get overview stats (to understand data structure)
Write-Host "`nFetching Gate Count Overview..." -ForegroundColor Cyan
$gateCountOverview = Invoke-LibInsightsApi -Endpoint "/gate-count/$GateCountDatasetId/overview" -AccessToken $accessToken

if ($gateCountOverview) {
    Write-Host "`nGate Count Overview:" -ForegroundColor Green
    $gateCountOverview | ConvertTo-Json -Depth 10 | Write-Host
    
    $gateCountOverview | ConvertTo-Json -Depth 10 | Out-File (Join-Path $outputDir "libinsights_gate_count_overview.json") -Encoding UTF8
    Write-Host "`nSaved to: output\json\libinsights_gate_count_overview.json" -ForegroundColor Gray
}

# Step 3: Explore Occupancy Dataset  
Write-Host "`n" + "=" * 60 -ForegroundColor Yellow
Write-Host "Step 3: Exploring Occupancy Dataset (ID: $OccupancyDatasetId)" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Yellow

# The occupancy dataset might be a custom dataset, so let's check both endpoints
Write-Host "`nTrying Custom Dataset Fields endpoint..." -ForegroundColor Cyan
$occupancyFields = Invoke-LibInsightsApi -Endpoint "/custom-dataset/$OccupancyDatasetId/fields" -AccessToken $accessToken

if ($occupancyFields) {
    Write-Host "`nOccupancy Dataset Fields:" -ForegroundColor Green
    $occupancyFields | ConvertTo-Json -Depth 10 | Write-Host
    
    $occupancyFields | ConvertTo-Json -Depth 10 | Out-File (Join-Path $outputDir "libinsights_occupancy_fields.json") -Encoding UTF8
    Write-Host "`nSaved to: output\json\libinsights_occupancy_fields.json" -ForegroundColor Gray
}

# Try to get existing data to understand the format
Write-Host "`nTrying to get existing data grid..." -ForegroundColor Cyan
$occupancyData = Invoke-LibInsightsApi -Endpoint "/custom-dataset/$OccupancyDatasetId/data-grid?limit=5" -AccessToken $accessToken

if ($occupancyData) {
    Write-Host "`nSample Occupancy Data:" -ForegroundColor Green
    $occupancyData | ConvertTo-Json -Depth 10 | Write-Host
    
    $occupancyData | ConvertTo-Json -Depth 10 | Out-File (Join-Path $outputDir "libinsights_occupancy_sample.json") -Encoding UTF8
    Write-Host "`nSaved to: output\json\libinsights_occupancy_sample.json" -ForegroundColor Gray
}

# Summary
Write-Host "`n" + "=" * 60 -ForegroundColor Green
Write-Host "EXPLORATION COMPLETE" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
Write-Host @"

Summary of Findings:
--------------------
Gate Count Dataset ID: $GateCountDatasetId
  - POST Endpoint: /gate-count/$GateCountDatasetId/save

Occupancy Dataset ID: $OccupancyDatasetId
  - POST Endpoint: /custom-dataset/$OccupancyDatasetId/save (if custom)

Output files saved to: output\json\
  - libinsights_gate_count_libraries.json
  - libinsights_gate_count_overview.json
  - libinsights_occupancy_fields.json
  - libinsights_occupancy_sample.json

Next Steps:
-----------
1. Review the output files to understand the data structure
2. Map VEA sensors to LibInsights library/gate IDs
3. Create the import script to POST data from CSV files

"@ -ForegroundColor White
