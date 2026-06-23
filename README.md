# VEA to LibInsights Data Pipeline

Automated extraction of VEA (SenSource) sensor data and import to Springshare LibInsights.

## What This Does

1. **Extracts** hourly traffic data from VEA sensors (5 library entrances)
2. **Converts** data to CSV format
3. **Imports** directly to LibInsights via API

## Quick Start

```batch
# 1. Clone repository
git clone https://github.com/byui-library/SenSourceToLibInsights.git
cd SenSourceToLibInsights

# 2. Configure credentials (prompts for VEA + LibInsights)
setup.bat

# 3. Test daily export
powershell -ExecutionPolicy Bypass -File "scripts\Daily-VEA-Export.ps1"

# 4. Test daily import (dry run)
powershell -ExecutionPolicy Bypass -File "scripts\Daily-LibInsights-Import.ps1" -DryRun
```

## Server Deployment & Task Scheduler

**For production server setup with automated nightly runs, see:**

📋 **[docs/SERVER-DEPLOYMENT.md](docs/SERVER-DEPLOYMENT.md)**

This guide covers:
- Server prerequisites
- Credential configuration (VEA + LibInsights)
- Task Scheduler setup (step-by-step)
- Troubleshooting

## Daily Automation

The **`run_daily_pipeline.bat`** script runs nightly to:
1. Extract **previous day's** VEA data (complete 24-hour data)
2. Import to LibInsights via API

Schedule this in Windows Task Scheduler to run after midnight (e.g., 2:00 AM).

## Project Structure

```
SenSourceToLibInsights/
├── run_daily_pipeline.bat      # ← SCHEDULE THIS IN TASK SCHEDULER
├── setup.bat                   # Configure VEA + LibInsights credentials
├── scripts/
│   ├── Daily-VEA-Export.ps1    # Exports previous day's data
│   ├── Daily-LibInsights-Import.ps1  # Imports CSVs to LibInsights
│   ├── VEA-Zone-Extractor.ps1  # Core extraction (custom date ranges)
│   └── LibInsights-Importer.ps1 # Core import logic
├── output/csv/                 # Generated CSV files
├── logs/                       # Daily execution logs
└── docs/                       # Detailed documentation
```

## Sensor Mapping

| VEA Sensor | LibInsights Gate ID | Location |
|------------|---------------------|----------|
| McKay_Library_Level_1_Main_Entrance_1 | 12 | West Wing Level 1 East Side |
| McKay_Library_Level_1_New_Entrance | 13 | West Wing Level 1 West Side |
| McKay_Library_Level_2_Stairs | 14 | West Wing Level 2 Stairs |
| McKay_Library_Level_3_Bridge | 15 | West Wing Level 3 Bridge |
| McKay_Library_Level_3_Stairs | 16 | West Wing Level 3 Stairs |

## Manual Operations

```powershell
# Export specific date
.\scripts\Daily-VEA-Export.ps1 -SpecificDate "2026-01-15"

# Export custom date range
.\scripts\VEA-Zone-Extractor.ps1 -StartDate "2026-01-01T00:00:00Z" -EndDate "2026-01-31T23:59:59Z"

# Import with options
.\scripts\Daily-LibInsights-Import.ps1 -DryRun          # Preview only
.\scripts\Daily-LibInsights-Import.ps1 -GateCountsOnly  # Gate counts only
```

## Documentation

- [Server Deployment Guide](docs/SERVER-DEPLOYMENT.md) - Production setup & Task Scheduler
- [Scripts Reference](docs/SCRIPTS.md) - Detailed script documentation
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## Security

- **VEA credentials**: Windows Credential Manager (encrypted)
- **LibInsights credentials**: Encrypted XML file (`scripts/libinsights_credentials.xml`)
- **No plain text secrets** in repository