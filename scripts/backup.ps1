<#
.SYNOPSIS
    Backup important user data before making changes.
.DESCRIPTION
    Creates a backup of:
    - Desktop files
    - Documents folder
    - Downloads folder
    - Chrome bookmarks and preferences
    - Browser passwords export instructions
    - Important system info
.PARAMETER Destination
    Where to save the backup. Defaults to external drive or Desktop.
.PARAMETER Quick
    Only backup essential items (bookmarks, desktop).
#>

param(
    [string]$Destination,
    [switch]$Quick
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

function Write-Step { param([string]$msg) Write-Host "[*] $msg" -ForegroundColor Yellow }
function Write-Success { param([string]$msg) Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Info { param([string]$msg) Write-Host "[i] $msg" -ForegroundColor Cyan }

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   BACKUP IMPORTANT DATA" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Find backup destination
if (-not $Destination) {
    # Look for external drives
    $externals = Get-Volume | Where-Object {
        $_.DriveType -eq "Removable" -or
        ($_.DriveType -eq "Fixed" -and $_.DriveLetter -ne "C")
    } | Where-Object { $_.DriveLetter }

    if ($externals) {
        Write-Host "External/secondary drives found:" -ForegroundColor Yellow
        $i = 1
        $externals | ForEach-Object {
            $free = [math]::Round($_.SizeRemaining / 1GB, 1)
            Write-Host "  $i. $($_.DriveLetter): - $($_.FileSystemLabel) ($free GB free)"
            $i++
        }
        Write-Host "  $i. Desktop (C: drive)"
        Write-Host ""

        $choice = Read-Host "Select backup destination (1-$i)"
        if ($choice -eq $i -or -not $choice) {
            $Destination = "$env:USERPROFILE\Desktop"
        } else {
            $selectedDrive = $externals[$([int]$choice - 1)]
            $Destination = "$($selectedDrive.DriveLetter):\"
        }
    } else {
        $Destination = "$env:USERPROFILE\Desktop"
    }
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$backupRoot = Join-Path $Destination "Backup_$env:COMPUTERNAME`_$timestamp"

Write-Info "Backup will be saved to: $backupRoot"
Write-Host ""

# Create backup folder
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

# ============================================================
# BACKUP FUNCTIONS
# ============================================================

function Backup-Folder {
    param(
        [string]$Source,
        [string]$Name,
        [string]$DestRoot,
        [switch]$Shallow
    )

    if (-not (Test-Path $Source)) {
        Write-Host "  [SKIP] $Name (not found)" -ForegroundColor Gray
        return
    }

    $dest = Join-Path $DestRoot $Name

    try {
        if ($Shallow) {
            # Only copy files, not subfolders
            New-Item -ItemType Directory -Path $dest -Force | Out-Null
            Copy-Item "$Source\*" -Destination $dest -Force -ErrorAction SilentlyContinue
        } else {
            Copy-Item $Source -Destination $dest -Recurse -Force -ErrorAction SilentlyContinue
        }

        $count = (Get-ChildItem $dest -Recurse -File -ErrorAction SilentlyContinue).Count
        Write-Success "$Name backed up ($count files)"
    } catch {
        Write-Host "  [ERROR] Failed to backup $Name : $_" -ForegroundColor Red
    }
}

# ============================================================
# CHROME BOOKMARKS & SETTINGS
# ============================================================
Write-Step "Backing up Chrome data..."

$chromeUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data"
$chromeBackup = Join-Path $backupRoot "Chrome"
New-Item -ItemType Directory -Path $chromeBackup -Force | Out-Null

if (Test-Path $chromeUserData) {
    # Get all profiles
    $profiles = Get-ChildItem $chromeUserData -Directory | Where-Object {
        $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$"
    }

    foreach ($profile in $profiles) {
        $profileBackup = Join-Path $chromeBackup $profile.Name
        New-Item -ItemType Directory -Path $profileBackup -Force | Out-Null

        # Bookmarks
        $bookmarks = Join-Path $profile.FullName "Bookmarks"
        if (Test-Path $bookmarks) {
            Copy-Item $bookmarks -Destination $profileBackup -Force
        }

        # Preferences (contains account info)
        $prefs = Join-Path $profile.FullName "Preferences"
        if (Test-Path $prefs) {
            Copy-Item $prefs -Destination $profileBackup -Force
        }

        # Get profile name for reference
        $prefsContent = Get-Content $prefs -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        $profileName = if ($prefsContent.profile.name) { $prefsContent.profile.name } else { $profile.Name }

        Write-Success "  Chrome profile '$profileName' backed up"
    }
}

# ============================================================
# EDGE BOOKMARKS
# ============================================================
Write-Step "Backing up Edge data..."

$edgeUserData = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
$edgeBackup = Join-Path $backupRoot "Edge"

if (Test-Path $edgeUserData) {
    New-Item -ItemType Directory -Path $edgeBackup -Force | Out-Null

    $profiles = Get-ChildItem $edgeUserData -Directory | Where-Object {
        $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$"
    }

    foreach ($profile in $profiles) {
        $profileBackup = Join-Path $edgeBackup $profile.Name
        New-Item -ItemType Directory -Path $profileBackup -Force | Out-Null

        $bookmarks = Join-Path $profile.FullName "Bookmarks"
        if (Test-Path $bookmarks) {
            Copy-Item $bookmarks -Destination $profileBackup -Force
        }
    }
    Write-Success "Edge bookmarks backed up"
} else {
    Write-Host "  [SKIP] Edge (not found)" -ForegroundColor Gray
}

# ============================================================
# USER FOLDERS
# ============================================================
if (-not $Quick) {
    Write-Step "Backing up user folders..."

    # Desktop (shallow - just files, not nested folders which could be huge)
    Backup-Folder -Source "$env:USERPROFILE\Desktop" -Name "Desktop" -DestRoot $backupRoot -Shallow

    # Documents (full)
    Write-Host "  Backing up Documents (this may take a while)..." -ForegroundColor Gray
    Backup-Folder -Source "$env:USERPROFILE\Documents" -Name "Documents" -DestRoot $backupRoot

    # Downloads (recent only)
    $downloadsBackup = Join-Path $backupRoot "Downloads_Recent"
    New-Item -ItemType Directory -Path $downloadsBackup -Force | Out-Null
    Get-ChildItem "$env:USERPROFILE\Downloads" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-30) } |
        ForEach-Object { Copy-Item $_.FullName -Destination $downloadsBackup -Force }
    $dlCount = (Get-ChildItem $downloadsBackup -File).Count
    Write-Success "Recent downloads backed up ($dlCount files)"

    # Pictures (if small)
    $picturesSize = (Get-ChildItem "$env:USERPROFILE\Pictures" -Recurse -File -ErrorAction SilentlyContinue |
                    Measure-Object -Property Length -Sum).Sum / 1GB
    if ($picturesSize -lt 2) {
        Backup-Folder -Source "$env:USERPROFILE\Pictures" -Name "Pictures" -DestRoot $backupRoot
    } else {
        Write-Host "  [SKIP] Pictures folder too large ($([math]::Round($picturesSize, 1)) GB)" -ForegroundColor Yellow
    }
}

# ============================================================
# SYSTEM INFO
# ============================================================
Write-Step "Saving system info..."

$sysInfoFile = Join-Path $backupRoot "SystemInfo.txt"
$sysInfo = @"
SYSTEM BACKUP INFORMATION
=========================
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer: $env:COMPUTERNAME
User: $env:USERNAME

WINDOWS VERSION
$(Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber | Format-List | Out-String)

INSTALLED PROGRAMS
$(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName } |
    Sort-Object DisplayName |
    Select-Object DisplayName, DisplayVersion |
    Format-Table -AutoSize |
    Out-String)

NETWORK ADAPTERS
$(Get-NetAdapter | Select-Object Name, Status, MacAddress | Format-Table -AutoSize | Out-String)
"@

$sysInfo | Out-File $sysInfoFile -Encoding UTF8
Write-Success "System info saved"

# ============================================================
# WIFI PASSWORDS (Bonus)
# ============================================================
Write-Step "Exporting WiFi passwords..."

$wifiFile = Join-Path $backupRoot "WiFi_Passwords.txt"
$wifiProfiles = netsh wlan show profiles 2>&1

if ($wifiProfiles -notmatch "not running") {
    $wifiData = "SAVED WIFI NETWORKS`r`n==================`r`n`r`n"

    $profileNames = ($wifiProfiles | Select-String "All User Profile\s*:\s*(.+)$").Matches |
                    ForEach-Object { $_.Groups[1].Value.Trim() }

    foreach ($name in $profileNames) {
        $details = netsh wlan show profile name="$name" key=clear 2>&1
        $keyMatch = $details | Select-String "Key Content\s*:\s*(.+)$"
        $password = if ($keyMatch) { $keyMatch.Matches[0].Groups[1].Value.Trim() } else { "(no password)" }

        $wifiData += "Network: $name`r`n"
        $wifiData += "Password: $password`r`n`r`n"
    }

    $wifiData | Out-File $wifiFile -Encoding UTF8
    Write-Success "WiFi passwords exported"
} else {
    Write-Host "  [SKIP] No WiFi adapter" -ForegroundColor Gray
}

# ============================================================
# PASSWORD REMINDER
# ============================================================
$passwordReminder = Join-Path $backupRoot "!README_PASSWORDS.txt"
@"
IMPORTANT: EXPORT YOUR BROWSER PASSWORDS!
==========================================

This backup does NOT include your saved passwords (they're encrypted).

TO EXPORT CHROME PASSWORDS:
1. Open Chrome
2. Go to: chrome://settings/passwords
3. Click the three dots next to "Saved Passwords"
4. Click "Export passwords"
5. Save the CSV file to this backup folder

TO EXPORT EDGE PASSWORDS:
1. Open Edge
2. Go to: edge://settings/passwords
3. Click the three dots next to "Saved Passwords"
4. Click "Export passwords"
5. Save the CSV file to this backup folder

WARNING: The exported CSV contains passwords in plain text!
Delete it after you've transferred them to a password manager.

RECOMMENDED: Use Bitwarden (free) to manage all your passwords
https://bitwarden.com
"@ | Out-File $passwordReminder -Encoding UTF8

# ============================================================
# SUMMARY
# ============================================================

$backupSize = (Get-ChildItem $backupRoot -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "   BACKUP COMPLETE" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Location: $backupRoot" -ForegroundColor Cyan
Write-Host "  Size: $([math]::Round($backupSize, 1)) MB" -ForegroundColor Cyan
Write-Host ""
Write-Host "  IMPORTANT:" -ForegroundColor Yellow
Write-Host "  - Browser passwords were NOT exported (encrypted)" -ForegroundColor Yellow
Write-Host "  - See !README_PASSWORDS.txt for export instructions" -ForegroundColor Yellow
Write-Host ""

# Open backup folder
$open = Read-Host "Open backup folder? (Y/n)"
if ($open -ne "n") {
    Start-Process explorer.exe -ArgumentList $backupRoot
}
