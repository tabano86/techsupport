# Tech Support Cheatsheet

Quick commands for common tasks. Run in PowerShell (as Admin when noted).

## Getting Started

```powershell
# One-liner to download all scripts to Desktop
$dest = "$env:USERPROFILE\Desktop\TechSupport"
New-Item -ItemType Directory -Path $dest -Force
@(
    "bootstrap.ps1", "setup.ps1", "verify.ps1", "diagnose.ps1",
    "google-audit.ps1", "backup.ps1", "browser-cleanup.ps1",
    "install-tools.ps1", "fix-common.ps1", "claude-code.ps1"
) | ForEach-Object {
    $url = "https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/$_"
    Invoke-WebRequest -Uri $url -OutFile "$dest\$_"
}
Write-Host "Scripts downloaded to $dest"
```

## Script Quick Reference

| Script | Purpose | Command |
|--------|---------|---------|
| `diagnose.ps1` | Full system diagnostic | `.\diagnose.ps1` |
| `google-audit.ps1` | Check Google accounts | `.\google-audit.ps1` |
| `backup.ps1` | Backup user data | `.\backup.ps1` |
| `browser-cleanup.ps1` | Clean browser cache | `.\browser-cleanup.ps1` |
| `install-tools.ps1` | Install utilities | `.\install-tools.ps1` |
| `fix-common.ps1` | Fix common issues | `.\fix-common.ps1` |
| `claude-code.ps1` | Manage Claude CLI | `.\claude-code.ps1 -Action Install` |

## System Info

```powershell
# Computer name and Windows version
Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, CSName

# Check disk space
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID, @{N='FreeGB';E={[math]::Round($_.FreeSpace/1GB,1)}}, @{N='TotalGB';E={[math]::Round($_.Size/1GB,1)}}

# RAM info
[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)

# CPU info
Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores

# Uptime
(Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
```

## Network

```powershell
# Show IP addresses
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '^169' }

# Flush DNS (fixes "site not loading")
ipconfig /flushdns

# Release and renew IP
ipconfig /release; ipconfig /renew

# Test connectivity
Test-NetConnection google.com
Test-NetConnection 8.8.8.8 -Port 53

# Show WiFi networks
netsh wlan show networks

# Get WiFi password for connected network
netsh wlan show profile name="NETWORK_NAME" key=clear

# Reset network stack (Admin, requires restart)
netsh winsock reset
netsh int ip reset
```

## Browser Commands

```powershell
# Kill Chrome (to clean cache)
Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue

# Kill Edge
Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue

# Open Chrome profiles folder
explorer "$env:LOCALAPPDATA\Google\Chrome\User Data"

# Clear Chrome cache only
$cachePaths = @("$env:LOCALAPPDATA\Google\Chrome\User Data\*\Cache", "$env:LOCALAPPDATA\Google\Chrome\User Data\*\Code Cache")
$cachePaths | Get-ChildItem -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Find Chrome bookmarks
Get-ChildItem "$env:LOCALAPPDATA\Google\Chrome\User Data\*\Bookmarks" | Select-Object FullName
```

## User Accounts

```powershell
# List local users
Get-LocalUser | Where-Object Enabled | Select-Object Name, LastLogon

# List admins
Get-LocalGroupMember -Group "Administrators"

# Create new admin user
$pw = ConvertTo-SecureString "TempPassword123!" -AsPlainText -Force
New-LocalUser -Name "support" -Password $pw -PasswordNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member "support"

# Reset user password
$pw = ConvertTo-SecureString "NewPassword123!" -AsPlainText -Force
Set-LocalUser -Name "username" -Password $pw
```

## Disk Cleanup

```powershell
# Size of common junk folders
@("$env:TEMP", "$env:WINDIR\Temp", "$env:LOCALAPPDATA\Microsoft\Windows\INetCache") | ForEach-Object {
    $size = (Get-ChildItem $_ -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "$_ : $([math]::Round($size, 1)) MB"
}

# Clear temp files (safe)
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Find large files
Get-ChildItem C:\ -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 500MB } |
    Sort-Object Length -Descending |
    Select-Object -First 20 @{N='SizeGB';E={[math]::Round($_.Length/1GB,2)}}, FullName

# Windows Disk Cleanup (GUI)
cleanmgr /d C:

# Clear Windows Update cache (Admin)
Stop-Service wuauserv -Force
Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force
Start-Service wuauserv
```

## Installed Software

```powershell
# List installed programs
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object DisplayName |
    Select-Object DisplayName, DisplayVersion, Publisher |
    Sort-Object DisplayName

# Check if winget is available
winget --version

# Search for an app
winget search "app name"

# Install an app
winget install --id "Publisher.AppName" --silent

# Update all apps
winget upgrade --all
```

## Services

```powershell
# Check if service is running
Get-Service -Name "servicename"

# Start/Stop service
Start-Service -Name "servicename"
Stop-Service -Name "servicename" -Force

# Common services
Get-Service wuauserv      # Windows Update
Get-Service sshd          # SSH Server
Get-Service Tailscale     # Tailscale
```

## Tailscale

```powershell
$ts = "$env:ProgramFiles\Tailscale\tailscale.exe"

# Check status
& $ts status

# Get Tailscale IP
& $ts ip -4

# Ping another device
& $ts ping devicename

# Re-authenticate
& $ts up --auth-key=tskey-xxxxx
```

## SSH

```powershell
# Install OpenSSH Server (Admin)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd

# Check if SSH is running
Get-Service sshd
Test-NetConnection localhost -Port 22

# Connect to remote machine
ssh user@hostname
ssh user@100.x.y.z

# Run command remotely
ssh user@host "powershell -Command Get-Process"
```

## Repair Windows

```powershell
# System File Checker (Admin)
sfc /scannow

# DISM repair (Admin)
DISM /Online /Cleanup-Image /RestoreHealth

# Check Windows health
DISM /Online /Cleanup-Image /CheckHealth

# Reset Windows Update (Admin)
Stop-Service wuauserv, cryptSvc, bits, msiserver -Force
Remove-Item "$env:WINDIR\SoftwareDistribution\*" -Recurse -Force
Remove-Item "$env:WINDIR\System32\catroot2\*" -Recurse -Force
Start-Service wuauserv, cryptSvc, bits, msiserver
```

## Startup Programs

```powershell
# List startup programs
Get-CimInstance Win32_StartupCommand | Select-Object Name, Location, Command

# Registry startup locations
Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"

# Startup folder
explorer "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"

# Disable a startup item
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "ProgramName"
```

## Useful One-Liners

```powershell
# Restart computer
Restart-Computer -Force

# Lock screen
rundll32.exe user32.dll,LockWorkStation

# Open Windows settings
Start-Process "ms-settings:"

# Open Windows Update
Start-Process "ms-settings:windowsupdate"

# Open Apps & Features
Start-Process "ms-settings:appsfeatures"

# Take screenshot (saves to clipboard)
# Win+Shift+S (not PowerShell, just keyboard)

# Open Task Manager
taskmgr

# Open Resource Monitor (detailed)
resmon

# Generate system report
systeminfo > "$env:USERPROFILE\Desktop\systeminfo.txt"
```

## Remote Access URLs

| Tool | URL |
|------|-----|
| Tailscale | https://login.tailscale.com/admin |
| RustDesk | Download from https://rustdesk.com |
| Google Remote Desktop | https://remotedesktop.google.com |

## Emergency Fixes

```powershell
# If Windows is really broken (Safe Mode from CMD)
bcdedit /set {default} safeboot minimal
# Then restart. To exit safe mode:
bcdedit /deletevalue {default} safeboot

# If you can't log in - reset password from Safe Mode
# Boot to Safe Mode, log in as Administrator, then:
net user username newpassword

# If Windows Update is completely stuck (nuclear option)
Stop-Service wuauserv -Force
Remove-Item "$env:WINDIR\SoftwareDistribution" -Recurse -Force
Start-Service wuauserv
```
