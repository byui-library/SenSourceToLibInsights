# Server Deployment Guide

Complete guide for deploying the VEA to LibInsights pipeline on a Windows Server with Task Scheduler automation.

## Prerequisites

- Windows Server 2016+ (or Windows 10/11)
- PowerShell 5.1 or higher
- Internet access to VEA API and LibInsights API
- Administrator access for Task Scheduler
- API Credentials:
  - VEA: Client ID and Secret
  - LibInsights: Client ID and Secret

---

## Step 1: Deploy the Code

```powershell
# Navigate to desired location
cd C:\Scripts

# Clone the repository
git clone https://github.com/byui-library/SenSourceToLibInsights.git
cd SenSourceToLibInsights
```

Or copy the project folder from your development machine.

---

## Step 2: Configure All Credentials

Run the setup script to configure **both** VEA and LibInsights credentials:

```batch
setup.bat
```

This will prompt you for:
1. **VEA API Client ID** (UUID format)
2. **VEA API Client Secret**
3. **LibInsights Client ID**
4. **LibInsights Client Secret**

Credentials are stored securely:
- VEA: Windows Credential Manager
- LibInsights: Encrypted XML file (`scripts/libinsights_credentials.xml`)

---

## Step 3: Test the Pipeline

### Test Export (Previous Day)
```powershell
powershell -ExecutionPolicy Bypass -File "scripts\Daily-VEA-Export.ps1"
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

## Step 4: Create the Scheduled Task

### Using Task Scheduler GUI

1. **Open Task Scheduler**: `Win + R` → `taskschd.msc`

2. **Create Task** (not "Basic Task") → Right-click → "Create Task..."

3. **General Tab**:
   - Name: `VEA to LibInsights Daily Pipeline`
   - ☑ Run whether user is logged on or not
   - ☑ Run with highest privileges

4. **Triggers Tab** → New:
   - Daily at `2:00:00 AM`
   - ☑ Enabled

5. **Actions Tab** → New:
   - Program/script: `C:\Scripts\SenSourceToLibInsights\run_daily_pipeline.bat`
   - Start in: `C:\Scripts\SenSourceToLibInsights`

6. **Conditions Tab**:
   - ☑ Start only if network connection is available

7. **Settings Tab**:
   - ☑ Allow task to be run on demand
   - ☑ If task fails, restart every 30 minutes (up to 3 times)

8. **Save** → Enter Windows password when prompted

### Using PowerShell (Administrator)

```powershell
$TaskPath = "C:\Scripts\SenSourceToLibInsights"

Register-ScheduledTask `
    -TaskName "VEA to LibInsights Daily Pipeline" `
    -Action (New-ScheduledTaskAction -Execute "$TaskPath\run_daily_pipeline.bat" -WorkingDirectory $TaskPath) `
    -Trigger (New-ScheduledTaskTrigger -Daily -At "02:00") `
    -Principal (New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest) `
    -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 30)) `
    -Description "Extracts previous day's VEA sensor data and imports to LibInsights"
```

---

## Step 5: Verify Setup

### Check Task Exists
```powershell
Get-ScheduledTask -TaskName "VEA to LibInsights Daily Pipeline"
```

### Run Manually
```powershell
Start-ScheduledTask -TaskName "VEA to LibInsights Daily Pipeline"
```

### Check Logs
```powershell
# Today's export log
Get-Content "logs\daily-export-$(Get-Date -Format 'yyyy-MM-dd').log"

# Today's import log  
Get-Content "logs\daily-import-$(Get-Date -Format 'yyyy-MM-dd').log"
```

---

## Troubleshooting

### Credentials Not Found
- Ensure setup was run by the same user account that runs the task
- For SYSTEM account, use environment variables:
  ```powershell
  [Environment]::SetEnvironmentVariable("VEA_API_CLIENT_ID", "your-id", "Machine")
  [Environment]::SetEnvironmentVariable("VEA_API_CLIENT_SECRET", "your-secret", "Machine")
  ```

### Network Errors
Check firewall allows outbound HTTPS to:
- `vea.sensourceinc.com`
- `byui.libinsight.com`

### Manual Recovery
If a day was missed:
```powershell
# Export specific date
.\scripts\Daily-VEA-Export.ps1 -SpecificDate "2026-01-15"

# Import to LibInsights
.\scripts\Daily-LibInsights-Import.ps1
```

---

## What Runs Daily

The `run_daily_pipeline.bat` script:

1. **Extracts** previous day's VEA sensor data (complete 24-hour data)
2. **Generates** CSV files in `output/csv/`
3. **Imports** to LibInsights via API
4. **Logs** results to `logs/` directory

Schedule it to run after midnight (e.g., 2:00 AM) to ensure yesterday's data is complete.

---

## Security

- **VEA credentials**: Encrypted in Windows Credential Manager
- **LibInsights credentials**: Encrypted XML file
- **All API calls**: HTTPS only
- **No plain text secrets** in repository
