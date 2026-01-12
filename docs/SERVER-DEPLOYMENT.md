# Server Deployment Guide

This guide explains how to deploy the VEA to LibInsights automated pipeline on a Windows Server.

## Prerequisites

- Windows Server 2016 or later
- PowerShell 5.1 or higher
- Internet access to VEA API and LibInsights API
- Administrator access for Task Scheduler setup
- VEA API credentials (Client ID and Secret)
- LibInsights API credentials (Client ID and Secret)

---

## Step 1: Clone the Repository

```powershell
# Navigate to desired location
cd C:\Scripts

# Clone the repository
git clone https://github.com/matjmiles/SenSourceToLibInsights.git
cd SenSourceToLibInsights
```

Or copy the project folder directly from your development machine.

---

## Step 2: Configure VEA Credentials

### Option A: Interactive Setup (Recommended)
```batch
setup.bat
```
Follow the prompts to enter your VEA API credentials. They will be stored securely in Windows Credential Manager.

### Option B: Automated Setup
```powershell
powershell -ExecutionPolicy Bypass -File "scripts\setup-automated.ps1" -ClientId "your-vea-client-id" -ClientSecret "your-vea-client-secret"
```

### Option C: Environment Variables
```powershell
# Set system environment variables (requires admin)
[Environment]::SetEnvironmentVariable("VEA_API_CLIENT_ID", "your-client-id", "Machine")
[Environment]::SetEnvironmentVariable("VEA_API_CLIENT_SECRET", "your-client-secret", "Machine")
```

### Verify VEA Credentials
```powershell
powershell -ExecutionPolicy Bypass -File "scripts\test-credentials.ps1"
```

---

## Step 3: Configure LibInsights Credentials

Run the LibInsights API Explorer to save credentials:
```powershell
powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-API-Explorer.ps1" -SaveCredentials
```

You will be prompted for:
- **Client ID**: Your LibInsights API client ID
- **Client Secret**: Your LibInsights API client secret

These are stored securely in `scripts\libinsights_credentials.xml`.

### Verify LibInsights Credentials
```powershell
powershell -ExecutionPolicy Bypass -File "scripts\LibInsights-API-Explorer.ps1" -TestOnly
```

---

## Step 4: Test the Daily Pipeline

Before scheduling, test that the daily pipeline works:

### Test Export Only
```powershell
# Export yesterday's data
powershell -ExecutionPolicy Bypass -File "scripts\Daily-VEA-Export.ps1"

# Or export a specific date
powershell -ExecutionPolicy Bypass -File "scripts\Daily-VEA-Export.ps1" -SpecificDate "2026-01-11"
```

### Test Import (Dry Run)
```powershell
powershell -ExecutionPolicy Bypass -File "scripts\Daily-LibInsights-Import.ps1" -DryRun
```

### Test Full Pipeline
```batch
run_daily_pipeline.bat
```

---

## Step 5: Create Scheduled Task

### Option A: Using Task Scheduler GUI

1. **Open Task Scheduler** (`Win + R` → `taskschd.msc`)

2. **Create Task** (not "Basic Task")

3. **General Tab**:
   - Name: `VEA to LibInsights Daily Pipeline`
   - Description: `Extracts previous day's VEA sensor data and imports to LibInsights`
   - ☑ Run whether user is logged on or not
   - ☑ Run with highest privileges
   - Configure for: Windows Server 2016 (or your version)

4. **Triggers Tab** → New:
   - Begin the task: On a schedule
   - Daily, Start: `2:00:00 AM`
   - ☑ Enabled

5. **Actions Tab** → New:
   - Action: Start a program
   - Program/script: `C:\Scripts\SenSourceToLibInsights\run_daily_pipeline.bat`
   - Start in: `C:\Scripts\SenSourceToLibInsights`

6. **Conditions Tab**:
   - ☑ Start only if the following network connection is available: Any connection

7. **Settings Tab**:
   - ☑ Allow task to be run on demand
   - ☑ If the task fails, restart every: 30 minutes
   - Attempt to restart up to: 3 times
   - ☑ Stop the task if it runs longer than: 1 hour

8. **Save** and enter Windows credentials when prompted

### Option B: Using PowerShell (Run as Administrator)

```powershell
# Define the task parameters
$TaskName = "VEA to LibInsights Daily Pipeline"
$TaskPath = "C:\Scripts\SenSourceToLibInsights"

# Create the action
$Action = New-ScheduledTaskAction `
    -Execute "$TaskPath\run_daily_pipeline.bat" `
    -WorkingDirectory $TaskPath

# Create the trigger (daily at 2:00 AM)
$Trigger = New-ScheduledTaskTrigger -Daily -At "02:00"

# Create the principal (run with highest privileges)
$Principal = New-ScheduledTaskPrincipal `
    -UserId "NT AUTHORITY\SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

# Create settings
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 30) `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1)

# Register the task
Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Settings $Settings `
    -Description "Extracts previous day's VEA sensor data and imports to LibInsights"

Write-Host "Task '$TaskName' created successfully!" -ForegroundColor Green
```

---

## Step 6: Verify the Setup

### Check Task Status
```powershell
Get-ScheduledTask -TaskName "VEA to LibInsights Daily Pipeline"
```

### Run Task Manually
```powershell
Start-ScheduledTask -TaskName "VEA to LibInsights Daily Pipeline"
```

### Check Logs
Logs are stored in the `logs/` directory:
- `logs/daily-export-YYYY-MM-DD.log` - VEA extraction logs
- `logs/daily-import-YYYY-MM-DD.log` - LibInsights import logs

---

## Troubleshooting

### Common Issues

1. **Credentials Not Found**
   - Ensure credentials were set up with the same user account that runs the scheduled task
   - For SYSTEM account, use environment variables instead of Credential Manager

2. **Network Errors**
   - Check firewall rules for outbound HTTPS to:
     - `vea.sensourceinc.com` (VEA API)
     - `byui.libinsight.com` (LibInsights API)

3. **Permission Denied**
   - Run Task Scheduler as Administrator
   - Ensure the task runs with highest privileges

4. **No Data Exported**
   - Check if sensors were active on the target date
   - Verify date range in logs

### View Recent Logs
```powershell
# View today's export log
Get-Content "C:\Scripts\SenSourceToLibInsights\logs\daily-export-$(Get-Date -Format 'yyyy-MM-dd').log"

# View today's import log
Get-Content "C:\Scripts\SenSourceToLibInsights\logs\daily-import-$(Get-Date -Format 'yyyy-MM-dd').log"
```

### Manual Recovery
If a day was missed, you can manually export/import a specific date:
```powershell
# Export specific date
powershell -ExecutionPolicy Bypass -File "scripts\Daily-VEA-Export.ps1" -SpecificDate "2026-01-15"

# Import all current CSV files
powershell -ExecutionPolicy Bypass -File "scripts\Daily-LibInsights-Import.ps1"
```

---

## Directory Structure After Setup

```
SenSourceToLibInsights/
├── scripts/
│   ├── Daily-VEA-Export.ps1        # Daily export script
│   ├── Daily-LibInsights-Import.ps1 # Daily import script
│   ├── Fill-Data-Gap.ps1           # One-time gap fill
│   ├── libinsights_credentials.xml  # LibInsights credentials (encrypted)
│   └── ... (other scripts)
├── output/
│   ├── csv/
│   │   ├── gate_counts/            # Gate count CSVs
│   │   └── occupancy/              # Occupancy CSVs
│   └── json/                       # Raw JSON data
├── logs/                           # Daily log files
│   ├── daily-export-2026-01-13.log
│   └── daily-import-2026-01-13.log
├── run_daily_pipeline.bat          # Main scheduled task script
├── setup.bat                       # VEA credential setup
└── README.md
```

---

## Security Notes

1. **Credential Storage**:
   - VEA credentials: Windows Credential Manager (encrypted)
   - LibInsights credentials: XML file (encrypted via PowerShell SecureString)
   - Never store credentials in plain text

2. **File Permissions**:
   - Restrict access to the `scripts/` folder
   - Only the service account needs read/execute access

3. **Network Security**:
   - All API calls use HTTPS
   - No data is stored permanently (CSVs are overwritten daily)

---

## Support

- Check logs in `logs/` directory for error details
- VEA API documentation: Contact VEA/SenSource support
- LibInsights API: https://ask.springshare.com/libinsight/
