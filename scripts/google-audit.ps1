<#
.SYNOPSIS
    Deep audit of all Google accounts and services on this computer.
.DESCRIPTION
    Specifically designed to untangle Google account confusion:
    - Lists all Chrome profiles and which Google accounts are signed in
    - Shows which profile is syncing what
    - Identifies Google Drive sync status and accounts
    - Finds saved passwords and credentials
    - Detects conflicting configurations
.PARAMETER Fix
    Attempt to fix common issues (with confirmation).
#>

param(
    [switch]$Fix
)

$ErrorActionPreference = "Continue"

function Write-Header { param([string]$msg)
    Write-Host ""
    Write-Host ("=" * 55) -ForegroundColor Cyan
    Write-Host "  $msg" -ForegroundColor Cyan
    Write-Host ("=" * 55) -ForegroundColor Cyan
}

function Write-Issue { param([string]$msg)
    Write-Host "  [!] $msg" -ForegroundColor Red
}

function Write-Ok { param([string]$msg)
    Write-Host "  [OK] $msg" -ForegroundColor Green
}

function Write-Info { param([string]$msg)
    Write-Host "  [i] $msg" -ForegroundColor Gray
}

$issues = @()

Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host "   GOOGLE ACCOUNT AUDIT" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Analyzing Google accounts on this computer..." -ForegroundColor Gray
Write-Host ""

# ============================================================
# 1. CHROME PROFILES - DETAILED
# ============================================================
Write-Header "CHROME PROFILES"

$chromeUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data"
$allAccounts = @()

if (Test-Path $chromeUserData) {
    $profileDirs = Get-ChildItem $chromeUserData -Directory | Where-Object {
        $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$"
    }

    $profileNum = 0
    foreach ($profileDir in ($profileDirs | Sort-Object Name)) {
        $profileNum++
        $prefsFile = Join-Path $profileDir.FullName "Preferences"

        $profile = @{
            Number = $profileNum
            FolderName = $profileDir.Name
            DisplayName = "Unknown"
            Emails = @()
            SyncEnabled = $false
            SyncEmail = ""
            LastUsed = $profileDir.LastWriteTime
            BookmarkCount = 0
            PasswordCount = 0
            ExtensionCount = 0
        }

        if (Test-Path $prefsFile) {
            try {
                $prefs = Get-Content $prefsFile -Raw -ErrorAction Stop | ConvertFrom-Json

                # Display name
                if ($prefs.profile.name) {
                    $profile.DisplayName = $prefs.profile.name
                }

                # All signed-in accounts
                if ($prefs.account_info) {
                    $profile.Emails = @($prefs.account_info | ForEach-Object { $_.email } | Where-Object { $_ })
                }

                # Sync status
                if ($prefs.google.services.sync_enabled) {
                    $profile.SyncEnabled = $true
                }
                if ($prefs.account_info -and $prefs.account_info[0].email) {
                    $profile.SyncEmail = $prefs.account_info[0].email
                }

            } catch {}
        }

        # Count bookmarks
        $bookmarksFile = Join-Path $profileDir.FullName "Bookmarks"
        if (Test-Path $bookmarksFile) {
            try {
                $bookmarks = Get-Content $bookmarksFile -Raw | ConvertFrom-Json
                $profile.BookmarkCount = ($bookmarks | ConvertTo-Json -Depth 100 | Select-String -Pattern '"type":\s*"url"' -AllMatches).Matches.Count
            } catch {}
        }

        # Count extensions
        $extDir = Join-Path $profileDir.FullName "Extensions"
        if (Test-Path $extDir) {
            $profile.ExtensionCount = (Get-ChildItem $extDir -Directory -ErrorAction SilentlyContinue).Count
        }

        # Count saved passwords (approximate - can't read actual passwords)
        $loginData = Join-Path $profileDir.FullName "Login Data"
        if (Test-Path $loginData) {
            $profile.PasswordCount = "Has saved passwords"
        }

        # Display profile info
        Write-Host ""
        Write-Host "  PROFILE $($profile.Number): $($profile.DisplayName)" -ForegroundColor White
        Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
        Write-Host "    Folder:      $($profile.FolderName)"
        Write-Host "    Last used:   $($profile.LastUsed.ToString('yyyy-MM-dd HH:mm'))"

        if ($profile.Emails.Count -gt 0) {
            Write-Host "    Accounts:    " -NoNewline
            Write-Host ($profile.Emails -join ", ") -ForegroundColor Yellow
            $allAccounts += $profile.Emails
        } else {
            Write-Host "    Accounts:    " -NoNewline
            Write-Host "Not signed in" -ForegroundColor DarkGray
        }

        Write-Host "    Sync:        $(if ($profile.SyncEnabled) { 'ON - ' + $profile.SyncEmail } else { 'OFF' })"
        Write-Host "    Bookmarks:   $($profile.BookmarkCount)"
        Write-Host "    Extensions:  $($profile.ExtensionCount)"
    }

    # Summary
    $uniqueAccounts = $allAccounts | Select-Object -Unique
    Write-Host ""
    Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
    Write-Host "  SUMMARY:" -ForegroundColor White
    Write-Host "    Total profiles: $($profileDirs.Count)"
    Write-Host "    Unique Google accounts: $($uniqueAccounts.Count)"

    if ($uniqueAccounts.Count -gt 1) {
        Write-Host ""
        Write-Issue "MULTIPLE GOOGLE ACCOUNTS DETECTED!"
        Write-Host "    This can cause sync confusion. Accounts found:" -ForegroundColor Yellow
        $uniqueAccounts | ForEach-Object { Write-Host "      - $_" -ForegroundColor Yellow }
        $issues += "Multiple Google accounts in Chrome"
    }

} else {
    Write-Host "  Chrome is not installed or has never been used." -ForegroundColor Gray
}

# ============================================================
# 2. GOOGLE DRIVE SYNC
# ============================================================
Write-Header "GOOGLE DRIVE SYNC"

$driveForDesktop = "$env:ProgramFiles\Google\Drive File Stream"
$backupAndSync = "$env:LOCALAPPDATA\Google\Drive"
$driveFS = Get-Process -Name "GoogleDriveFS" -ErrorAction SilentlyContinue

# Check Drive for Desktop
if (Test-Path $driveForDesktop) {
    Write-Host ""
    Write-Host "  GOOGLE DRIVE FOR DESKTOP" -ForegroundColor White
    Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
    Write-Host "    Status: INSTALLED"
    Write-Host "    Running: $(if ($driveFS) { 'Yes' } else { 'No' })"

    # Find mounted drive letters
    $gdrives = Get-PSDrive -PSProvider FileSystem | Where-Object {
        $_.Description -match "Google" -or $_.Root -match "Google"
    }
    if ($gdrives) {
        Write-Host "    Mounted drives:"
        $gdrives | ForEach-Object { Write-Host "      $($_.Root)" }
    }

    # Check which account is syncing
    $drivePrefs = "$env:LOCALAPPDATA\Google\DriveFS\*\account_db*"
    $accountFiles = Get-ChildItem $drivePrefs -ErrorAction SilentlyContinue
    if ($accountFiles) {
        Write-Host "    Account data found in DriveFS folder" -ForegroundColor Gray
    }
}

# Check old Backup and Sync
if (Test-Path $backupAndSync) {
    Write-Host ""
    Write-Host "  BACKUP AND SYNC (DEPRECATED)" -ForegroundColor Red
    Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
    Write-Issue "Old 'Backup and Sync' is installed!"
    Write-Host "    This was replaced by 'Google Drive for Desktop'" -ForegroundColor Yellow
    Write-Host "    Having both can cause conflicts" -ForegroundColor Yellow
    $issues += "Deprecated Backup and Sync still installed"

    if ($Fix) {
        Write-Host ""
        $confirm = Read-Host "    Uninstall Backup and Sync? (y/N)"
        if ($confirm -eq "y") {
            Write-Host "    Please uninstall manually via Settings > Apps" -ForegroundColor Yellow
            Start-Process "ms-settings:appsfeatures"
        }
    }
}

# Find Google Drive folders
Write-Host ""
Write-Host "  GOOGLE DRIVE FOLDERS" -ForegroundColor White
Write-Host "  ----------------------------------------" -ForegroundColor DarkGray

$possibleDriveFolders = @(
    "$env:USERPROFILE\Google Drive"
    "$env:USERPROFILE\My Drive"
    "$env:USERPROFILE\GoogleDrive"
    "G:\My Drive"
    "G:\Shared drives"
)

$foundFolders = @()
foreach ($folder in $possibleDriveFolders) {
    if (Test-Path $folder) {
        $foundFolders += $folder
        $itemCount = (Get-ChildItem $folder -ErrorAction SilentlyContinue).Count
        Write-Host "    [FOUND] $folder ($itemCount items)"
    }
}

if ($foundFolders.Count -eq 0) {
    Write-Host "    No Google Drive folders found" -ForegroundColor Gray
}

if ($foundFolders.Count -gt 2) {
    Write-Issue "Multiple Drive folders found - may indicate account confusion"
    $issues += "Multiple Google Drive folders"
}

# ============================================================
# 3. GMAIL / GOOGLE APPS
# ============================================================
Write-Header "OTHER GOOGLE SERVICES"

# Check for Google apps
$googleApps = @(
    @{ Name = "Google Chrome"; Path = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe" },
    @{ Name = "Google Earth Pro"; Path = "$env:ProgramFiles\Google\Google Earth Pro\client\googleearth.exe" },
    @{ Name = "Google Photos Backup"; Path = "$env:LOCALAPPDATA\Google\Google Photos Backup\*" }
)

foreach ($app in $googleApps) {
    if (Test-Path $app.Path) {
        Write-Host "  [Installed] $($app.Name)" -ForegroundColor Green
    }
}

# ============================================================
# 4. RECOMMENDATIONS
# ============================================================
Write-Header "RECOMMENDATIONS"

if ($issues.Count -eq 0) {
    Write-Ok "No major issues found!"
    Write-Host ""
    Write-Host "  Your Google setup looks clean." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  Issues found: $($issues.Count)" -ForegroundColor Red
    Write-Host ""

    foreach ($issue in $issues) {
        Write-Host "  [!] $issue" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  SUGGESTED FIXES:" -ForegroundColor Cyan
    Write-Host ""

    if ($issues -contains "Multiple Google accounts in Chrome") {
        Write-Host "  1. ACCOUNT CONFUSION IN CHROME:" -ForegroundColor White
        Write-Host "     - Open Chrome and click your profile picture (top right)"
        Write-Host "     - Click 'Manage profiles'"
        Write-Host "     - Decide which account should be your 'main' profile"
        Write-Host "     - Sign out of other profiles or delete unused ones"
        Write-Host "     - In main profile: Settings > You and Google > Sync"
        Write-Host "       Make sure it's syncing to the correct account"
        Write-Host ""
    }

    if ($issues -contains "Deprecated Backup and Sync still installed") {
        Write-Host "  2. REMOVE OLD BACKUP AND SYNC:" -ForegroundColor White
        Write-Host "     - Open Settings > Apps > Apps & features"
        Write-Host "     - Search for 'Backup and Sync'"
        Write-Host "     - Click Uninstall"
        Write-Host "     - Install 'Google Drive for Desktop' instead"
        Write-Host "     - Download from: https://www.google.com/drive/download/"
        Write-Host ""
    }

    if ($issues -contains "Multiple Google Drive folders") {
        Write-Host "  3. CLEAN UP DRIVE FOLDERS:" -ForegroundColor White
        Write-Host "     - Open Google Drive for Desktop settings"
        Write-Host "     - Check which folders are being synced"
        Write-Host "     - Remove duplicate sync locations"
        Write-Host "     - Back up and delete old 'Google Drive' folders"
        Write-Host ""
    }
}

# ============================================================
# 5. QUICK LINKS
# ============================================================
Write-Header "USEFUL LINKS"

Write-Host "  - Google Account settings:  https://myaccount.google.com"
Write-Host "  - Check signed-in devices:  https://myaccount.google.com/device-activity"
Write-Host "  - Security checkup:         https://myaccount.google.com/security-checkup"
Write-Host "  - Google Drive storage:     https://drive.google.com/settings/storage"
Write-Host "  - Remove account access:    https://myaccount.google.com/permissions"
Write-Host ""

# Offer to open links
if (-not $Fix) {
    $open = Read-Host "Open Google Account settings in browser? (y/N)"
    if ($open -eq "y") {
        Start-Process "https://myaccount.google.com"
    }
}
