# Agent Guidelines for VEA Springshare API Repository

## Build/Lint/Test Commands

### Main Pipeline Execution
- **Daily pipeline (scheduled)**: `run_daily_pipeline.bat` (extracts previous day's data and imports - for Task Scheduler)
- **Full pipeline (manual)**: `run_full_pipeline.bat` (extracts VEA data and imports to LibInsights)
- **Setup all credentials**: `setup.bat` (configures VEA + LibInsights credentials)

### PowerShell Script Execution
- **Daily export (yesterday)**: `powershell -ExecutionPolicy Bypass -File "scripts\Daily-VEA-Export.ps1"`
- **Daily export (specific date)**: `powershell -ExecutionPolicy Bypass -File "scripts\Daily-VEA-Export.ps1" -SpecificDate "2026-01-10"`
- **Daily import**: `powershell -ExecutionPolicy Bypass -File "scripts\Daily-LibInsights-Import.ps1"`
- **Daily import (dry run)**: `powershell -ExecutionPolicy Bypass -File "scripts\Daily-LibInsights-Import.ps1" -DryRun`
- **Custom date extraction**: `powershell -ExecutionPolicy Bypass -File "scripts\VEA-Zone-Extractor.ps1" -StartDate "2025-10-21T00:00:00Z" -EndDate "2025-12-31T23:59:59Z"`

### Credential Management
- **Setup both credentials**: `setup.bat` (prompts for VEA + LibInsights credentials)
- **VEA automated setup**: `powershell -ExecutionPolicy Bypass -File "scripts\setup-automated.ps1" -ClientId "id" -ClientSecret "secret"`
- **VEA reset credentials**: `powershell -ExecutionPolicy Bypass -File "scripts\setup-automated.ps1" -ResetCredentials`
- **LibInsights credentials only**: `powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-API-Explorer.ps1" -SaveCredentials`

### Testing
- **Test daily export**: `powershell -ExecutionPolicy Bypass -File "scripts\Daily-VEA-Export.ps1"`
- **Test daily import (dry run)**: `powershell -ExecutionPolicy Bypass -File "scripts\Daily-LibInsights-Import.ps1" -DryRun`
- **Credential verification**: `powershell -ExecutionPolicy Bypass -File "scripts\test-credentials-simple.ps1"`

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