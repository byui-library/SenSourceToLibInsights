# Agent Guidelines for VEA Springshare API Repository

## Build/Lint/Test Commands

### Main Pipeline Execution
- **Full pipeline (VEA + LibInsights)**: `run_full_pipeline.bat` (extracts VEA data and imports to LibInsights)
- **VEA extraction only**: `run_export.bat` (runs VEA data extraction and CSV conversion)
- **LibInsights import only**: `run_import.bat` (imports existing CSVs to LibInsights)
- **Setup**: `setup.bat` (configures secure VEA credentials)

### PowerShell Script Execution
- **Individual sensor extraction**: `powershell -ExecutionPolicy Bypass -File "scripts\VEA-Zone-Extractor.ps1"` (generates both JSON and CSV files)
- **Custom date extraction (parameter)**: `powershell -ExecutionPolicy Bypass -File "scripts\VEA-Zone-Extractor.ps1" -StartDate "2025-10-21T00:00:00Z" -EndDate "2025-12-31T23:59:59Z"`
- **Custom date extraction (interactive)**: `powershell -ExecutionPolicy Bypass -File "scripts\VEA-Zone-Extractor-Custom.ps1"`
- **LibInsights import**: `powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-Importer.ps1"`
- **LibInsights import (dry run)**: `powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-Importer.ps1" -DryRun`
- **LibInsights import (gate counts only)**: `powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-Importer.ps1" -GateCountsOnly`
- **LibInsights import (occupancy only)**: `powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-Importer.ps1" -OccupancyOnly`

### Credential Management
- **VEA interactive setup**: `setup.bat` (prompts for VEA credentials)
- **VEA automated setup**: `powershell -ExecutionPolicy Bypass -File "scripts\setup-automated.ps1" -ClientId "id" -ClientSecret "secret" -UseEnvironmentVariables`
- **VEA reset credentials**: `powershell -ExecutionPolicy Bypass -File "scripts\setup-automated.ps1" -ResetCredentials`
- **LibInsights credentials**: `powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-API-Explorer.ps1" -SaveCredentials`
- **LibInsights auth test**: `powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-API-Explorer.ps1" -TestOnly`

### Testing Single Components
- **API authentication test**: `powershell -ExecutionPolicy Bypass -File "archive\vea_auth_test.ps1"`
- **Data extraction test**: `powershell -ExecutionPolicy Bypass -File "archive\vea_clean_test.ps1"`
- **Credential verification**: `powershell -ExecutionPolicy Bypass -File "scripts\test-credentials-simple.ps1"`
- **LibInsights single record test**: `powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-Importer.ps1" -TestSingle`

## Code Style Guidelines

### PowerShell Conventions
- **Variables**: Use `$camelCase` for local variables (e.g., `$accessToken`, `$zoneData`)
- **Functions**: Use `PascalCase` for function names (e.g., `Get-VEAAccessToken`, `ConvertTo-CSV`)
- **Parameters**: Define with `param()` blocks, use `[string]`, `[int]` type hints
- **Comments**: Use `#` for single-line comments explaining complex logic
- **Error Handling**: Use `try/catch` blocks with `Write-Error` for failures
- **Indentation**: 4 spaces consistently throughout scripts

### Naming Conventions
- **Files**: PascalCase with descriptive names (e.g., `VEA-Zone-Extractor.ps1`)
- **API endpoints**: Use consistent URL construction with `$ApiBaseUrl`
- **Output files**: Use `{SensorName}_{type}_data.{ext}` pattern
- **Configuration**: Centralize credentials in secure storage with clear variable names

### Imports and Dependencies
- **Modules**: No external PowerShell modules required - uses only built-in cmdlets
- **Configuration**: Load via secure credential manager pattern in scripts
- **API calls**: Use `Invoke-RestMethod` with consistent header patterns

### Data Handling
- **JSON processing**: Use `ConvertFrom-Json`/`ConvertTo-Json` with appropriate depth
- **CSV export**: Use `Export-Csv -NoTypeInformation -Encoding UTF8`
- **Date formats**: ISO-8601 for API calls, YYYY-MM-DD for Springshare CSV
- **Encoding**: UTF-8 without BOM for all file outputs

### Error Handling and Logging
- **Validation**: Check file existence with `Test-Path` before operations
- **User feedback**: Use `Write-Host -ForegroundColor` for status messages
- **API errors**: Catch exceptions and provide meaningful error messages
- **Progress tracking**: Show counters and percentages for batch operations</content>
<parameter name="filePath">C:\Users\milesm\Documents\repos\vea springshare api\AGENTS.md