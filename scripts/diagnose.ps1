<#
.SYNOPSIS
    Comprehensive system diagnostic - run this FIRST to understand the situation.
.DESCRIPTION
    Collects:
    - System info (OS, RAM, disk space)
    - User accounts on this PC
    - Chrome/Edge profiles and signed-in Google accounts
    - Google Drive/Backup & Sync status
    - Browser extensions
    - Startup programs
    - Installed software
    - Recent activity
    - Network configuration
.PARAMETER OutputPath
    Where to save the report. Defaults to Desktop.
.PARAMETER Quick
    Skip slow operations (installed programs scan).
#>

param(
    [string]$OutputPath = "$env:USERPROFILE\Desktop",
    [switch]$Quick
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# --- Setup ---
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = Join-Path $OutputPath "TechSupport_Diagnostic_$timestamp.txt"
$reportData = [System.Collections.ArrayList]::new()

function Add-Section {
    param([string]$Title)
    $null = $reportData.Add("")
    $null = $reportData.Add(("=" * 60))
    $null = $reportData.Add("  $Title")
    $null = $reportData.Add(("=" * 60))
    Write-Host "[*] $Title..." -ForegroundColor Yellow
}

function Add-Line {
    param([string]$Line)
    $null = $reportData.Add($Line)
}

function Add-KeyValue {
    param([string]$Key, [string]$Value)
    $null = $reportData.Add("  $($Key.PadRight(25)): $Value")
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   TECH SUPPORT DIAGNOSTIC" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will take 1-2 minutes..." -ForegroundColor Gray
Write-Host ""

# ============================================================
# SYSTEM INFO
# ============================================================
Add-Section "SYSTEM INFORMATION"

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem

Add-KeyValue "Computer Name" $env:COMPUTERNAME
Add-KeyValue "Current User" $env:USERNAME
Add-KeyValue "OS" $os.Caption
Add-KeyValue "OS Version" $os.Version
Add-KeyValue "Architecture" $env:PROCESSOR_ARCHITECTURE
Add-KeyValue "RAM (GB)" ([math]::Round($cs.TotalPhysicalMemory / 1GB, 1))
Add-KeyValue "Manufacturer" $cs.Manufacturer
Add-KeyValue "Model" $cs.Model

# Uptime
$uptime = (Get-Date) - $os.LastBootUpTime
Add-KeyValue "Uptime" ("{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)

# ============================================================
# DISK SPACE
# ============================================================
Add-Section "DISK SPACE"

Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $free = [math]::Round($_.FreeSpace / 1GB, 1)
    $total = [math]::Round($_.Size / 1GB, 1)
    $used = $total - $free
    $pct = [math]::Round(($used / $total) * 100, 0)
    Add-Line ("  {0}  {1,6} GB free / {2,6} GB total  ({3}% used)" -f $_.DeviceID, $free, $total, $pct)

    if ($pct -gt 90) {
        Add-Line "     ^^^ WARNING: Low disk space!"
    }
}

# ============================================================
# LOCAL USER ACCOUNTS
# ============================================================
Add-Section "LOCAL USER ACCOUNTS"

Get-LocalUser | Where-Object { $_.Enabled } | ForEach-Object {
    $isAdmin = (Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue).Name -contains "$env:COMPUTERNAME\$($_.Name)"
    $adminTag = if ($isAdmin) { " [ADMIN]" } else { "" }
    Add-Line ("  - {0}{1}" -f $_.Name, $adminTag)
    Add-Line ("      Last logon: {0}" -f $(if ($_.LastLogon) { $_.LastLogon.ToString("yyyy-MM-dd HH:mm") } else { "Never" }))
}

# ============================================================
# CHROME PROFILES & GOOGLE ACCOUNTS
# ============================================================
Add-Section "CHROME PROFILES & GOOGLE ACCOUNTS"

$chromeUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data"
$chromeProfiles = @()

if (Test-Path $chromeUserData) {
    # Find all profile directories
    $profileDirs = Get-ChildItem $chromeUserData -Directory | Where-Object {
        $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$"
    }

    foreach ($profileDir in $profileDirs) {
        $prefsFile = Join-Path $profileDir.FullName "Preferences"
        $profileInfo = @{
            Name = $profileDir.Name
            Path = $profileDir.FullName
            GoogleEmail = "Not signed in"
            ProfileName = "Unknown"
            LastUsed = $null
        }

        if (Test-Path $prefsFile) {
            try {
                $prefs = Get-Content $prefsFile -Raw | ConvertFrom-Json

                # Get profile name
                if ($prefs.profile.name) {
                    $profileInfo.ProfileName = $prefs.profile.name
                }

                # Get signed-in Google account
                if ($prefs.account_info -and $prefs.account_info.Count -gt 0) {
                    $emails = $prefs.account_info | ForEach-Object { $_.email } | Where-Object { $_ }
                    if ($emails) {
                        $profileInfo.GoogleEmail = $emails -join ", "
                    }
                }

                # Alternative: check signin.allowed_username (older Chrome)
                if ($profileInfo.GoogleEmail -eq "Not signed in" -and $prefs.signin.allowed_username) {
                    $profileInfo.GoogleEmail = $prefs.signin.allowed_username
                }
            } catch {}
        }

        # Get last modified time of profile folder
        $profileInfo.LastUsed = $profileDir.LastWriteTime

        $chromeProfiles += $profileInfo
    }

    if ($chromeProfiles.Count -gt 0) {
        Add-Line "  Found $($chromeProfiles.Count) Chrome profile(s):"
        Add-Line ""

        foreach ($p in ($chromeProfiles | Sort-Object LastUsed -Descending)) {
            Add-Line ("  [{0}] {1}" -f $p.Name, $p.ProfileName)
            Add-Line ("      Google Account: {0}" -f $p.GoogleEmail)
            Add-Line ("      Last used: {0}" -f $p.LastUsed.ToString("yyyy-MM-dd HH:mm"))
            Add-Line ""
        }
    } else {
        Add-Line "  No Chrome profiles found"
    }
} else {
    Add-Line "  Chrome not installed or never used"
}

# ============================================================
# EDGE PROFILES
# ============================================================
Add-Section "EDGE PROFILES & MICROSOFT ACCOUNTS"

$edgeUserData = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"

if (Test-Path $edgeUserData) {
    $edgeProfiles = Get-ChildItem $edgeUserData -Directory | Where-Object {
        $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$"
    }

    foreach ($profileDir in $edgeProfiles) {
        $prefsFile = Join-Path $profileDir.FullName "Preferences"
        $profileName = $profileDir.Name
        $email = "Not signed in"

        if (Test-Path $prefsFile) {
            try {
                $prefs = Get-Content $prefsFile -Raw | ConvertFrom-Json
                if ($prefs.profile.name) { $profileName = $prefs.profile.name }
                if ($prefs.account_info -and $prefs.account_info.Count -gt 0) {
                    $emails = $prefs.account_info | ForEach-Object { $_.email } | Where-Object { $_ }
                    if ($emails) { $email = $emails -join ", " }
                }
            } catch {}
        }

        Add-Line ("  [{0}] {1}" -f $profileDir.Name, $profileName)
        Add-Line ("      Account: {0}" -f $email)
    }
} else {
    Add-Line "  Edge user data not found"
}

# ============================================================
# GOOGLE DRIVE / BACKUP & SYNC STATUS
# ============================================================
Add-Section "GOOGLE DRIVE SYNC STATUS"

# Check for Google Drive for Desktop (new)
$gdriveDesktop = "$env:ProgramFiles\Google\Drive File Stream"
$gdriveProcess = Get-Process -Name "GoogleDriveFS" -ErrorAction SilentlyContinue

# Check for old Backup and Sync
$backupSync = "$env:LOCALAPPDATA\Google\Drive"
$backupSyncProcess = Get-Process -Name "googledrivesync" -ErrorAction SilentlyContinue

if (Test-Path $gdriveDesktop) {
    Add-Line "  Google Drive for Desktop: INSTALLED"
    Add-Line ("      Running: {0}" -f $(if ($gdriveProcess) { "Yes" } else { "No" }))

    # Check mounted drives
    $gdrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Description -match "Google" }
    if ($gdrives) {
        Add-Line "      Mounted drives:"
        $gdrives | ForEach-Object { Add-Line "        - $($_.Root)" }
    }
}

if (Test-Path $backupSync) {
    Add-Line "  Backup and Sync (OLD): INSTALLED"
    Add-Line ("      Running: {0}" -f $(if ($backupSyncProcess) { "Yes" } else { "No" }))
    Add-Line "      NOTE: This is deprecated. Consider migrating to Drive for Desktop."
}

# Check for Google Drive folder in user profile
$gdriveFolders = @(
    "$env:USERPROFILE\Google Drive",
    "$env:USERPROFILE\My Drive",
    "$env:USERPROFILE\GoogleDrive"
)

$foundDriveFolders = $gdriveFolders | Where-Object { Test-Path $_ }
if ($foundDriveFolders) {
    Add-Line "  Google Drive folders found:"
    $foundDriveFolders | ForEach-Object {
        $size = (Get-ChildItem $_ -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $sizeGB = [math]::Round($size / 1GB, 2)
        Add-Line ("      {0} ({1} GB)" -f $_, $sizeGB)
    }
}

if (-not (Test-Path $gdriveDesktop) -and -not (Test-Path $backupSync) -and -not $foundDriveFolders) {
    Add-Line "  No Google Drive sync software detected"
}

# ============================================================
# GOOGLE ACCOUNTS IN CREDENTIAL MANAGER
# ============================================================
Add-Section "SAVED GOOGLE CREDENTIALS"

try {
    $creds = cmdkey /list 2>&1 | Out-String
    $googleCreds = ($creds -split "`n") | Where-Object { $_ -match "google|gmail|gaia" }

    if ($googleCreds) {
        Add-Line "  Found Google-related credentials:"
        $googleCreds | ForEach-Object { Add-Line ("    {0}" -f $_.Trim()) }
    } else {
        Add-Line "  No Google credentials in Windows Credential Manager"
    }
} catch {
    Add-Line "  Could not check credentials"
}

# ============================================================
# BROWSER EXTENSIONS
# ============================================================
Add-Section "BROWSER EXTENSIONS (Chrome)"

if (Test-Path $chromeUserData) {
    $defaultExtensions = "$chromeUserData\Default\Extensions"

    if (Test-Path $defaultExtensions) {
        $extensions = Get-ChildItem $defaultExtensions -Directory -ErrorAction SilentlyContinue

        # Known extension IDs (common ones)
        $knownExtensions = @{
            "cjpalhdlnbpafiamejdnhcphjbkeiagm" = "uBlock Origin"
            "gcbommkclmclpchllfjekcdonpmejbdp" = "HTTPS Everywhere"
            "hdokiejnpimakedhajhdlcegeplioahd" = "LastPass"
            "nngceckbapebfimnlniiiahkandclblb" = "Bitwarden"
            "aapbdbdomjkkjkaonfhkkikfgjllcleb" = "Google Translate"
            "ghbmnnjooekpmoecnnnilnnbdlolhkhi" = "Google Docs Offline"
            "aohghmighlieiainnegkcijnfilokake" = "Google Docs"
            "felcaaldnbdncclmgdcncolpebgiejap" = "Google Sheets"
            "apdfllckaahabafndbhieahigkjlhalf" = "Google Drive"
            "pjkljhegncpnkpknbcohdijeoejaedia" = "Gmail"
            "blpcfgokakmgnkcojhhkbfbldkacnbeo" = "YouTube"
            "coobgpohoikkiipiblmjeljniedjpjpf" = "Google Search"
            "kbfnbcaeplbcioakkpcpgfkobkghlhen" = "Grammarly"
            "bmnlcjabgnpnenekpadlanbbkooimhnj" = "Honey"
        }

        $extCount = 0
        $extList = @()

        foreach ($ext in $extensions) {
            $extId = $ext.Name
            $extName = if ($knownExtensions.ContainsKey($extId)) { $knownExtensions[$extId] } else { $extId }

            # Try to get actual name from manifest
            $manifestPaths = Get-ChildItem $ext.FullName -Filter "manifest.json" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($manifestPaths) {
                try {
                    $manifest = Get-Content $manifestPaths.FullName -Raw | ConvertFrom-Json
                    if ($manifest.name -and $manifest.name -notmatch "^__MSG_") {
                        $extName = $manifest.name
                    }
                } catch {}
            }

            $extList += $extName
            $extCount++
        }

        Add-Line "  Found $extCount extension(s):"
        $extList | Sort-Object | ForEach-Object { Add-Line "    - $_" }
    }
} else {
    Add-Line "  Chrome not found"
}

# ============================================================
# STARTUP PROGRAMS
# ============================================================
Add-Section "STARTUP PROGRAMS"

# Registry startup items
$startupPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
)

foreach ($path in $startupPaths) {
    if (Test-Path $path) {
        $items = Get-ItemProperty $path -ErrorAction SilentlyContinue
        $items.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" } | ForEach-Object {
            Add-Line "  - $($_.Name)"
            Add-Line "      $($_.Value)"
        }
    }
}

# Startup folder
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
if (Test-Path $startupFolder) {
    Get-ChildItem $startupFolder -ErrorAction SilentlyContinue | ForEach-Object {
        Add-Line ("  - {0} (Startup Folder)" -f $_.Name)
    }
}

# ============================================================
# INSTALLED SOFTWARE (Quick list)
# ============================================================
if (-not $Quick) {
    Add-Section "INSTALLED SOFTWARE (Selected)"

    $interestingSoftware = @(
        "*Google*", "*Chrome*", "*Firefox*", "*Edge*",
        "*Office*", "*Microsoft 365*",
        "*Dropbox*", "*OneDrive*", "*iCloud*",
        "*Norton*", "*McAfee*", "*Avast*", "*AVG*", "*Kaspersky*",
        "*TeamViewer*", "*AnyDesk*", "*RustDesk*",
        "*Zoom*", "*Teams*", "*Slack*",
        "*VPN*", "*NordVPN*", "*ExpressVPN*"
    )

    $apps = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
                             "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                             "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher -Unique |
            Sort-Object DisplayName

    $relevantApps = $apps | Where-Object {
        $name = $_.DisplayName
        $interestingSoftware | ForEach-Object { if ($name -like $_) { return $true } }
    }

    $relevantApps | ForEach-Object {
        Add-Line ("  - {0} v{1}" -f $_.DisplayName, $_.DisplayVersion)
    }
}

# ============================================================
# RECENT DOWNLOADS
# ============================================================
Add-Section "RECENT DOWNLOADS (Last 7 days)"

$downloads = "$env:USERPROFILE\Downloads"
if (Test-Path $downloads) {
    $recentFiles = Get-ChildItem $downloads -File -ErrorAction SilentlyContinue |
                   Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) } |
                   Sort-Object LastWriteTime -Descending |
                   Select-Object -First 15

    if ($recentFiles) {
        $recentFiles | ForEach-Object {
            Add-Line ("  {0}  {1}" -f $_.LastWriteTime.ToString("MM-dd HH:mm"), $_.Name)
        }
    } else {
        Add-Line "  No recent downloads"
    }
}

# ============================================================
# NETWORK INFO
# ============================================================
Add-Section "NETWORK CONFIGURATION"

# Get active network adapters
Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
    Add-Line ("  Adapter: {0}" -f $_.Name)

    $ipConfig = Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($ipConfig) {
        Add-Line ("      IP: {0}" -f $ipConfig.IPAddress)
    }
}

# Check for Tailscale
$tsExe = "$env:ProgramFiles\Tailscale\tailscale.exe"
if (Test-Path $tsExe) {
    $tsIP = & $tsExe ip -4 2>&1
    Add-Line ("  Tailscale IP: {0}" -f $tsIP)
}

# DNS servers
$dns = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses } | Select-Object -First 1
if ($dns) {
    Add-Line ("  DNS Servers: {0}" -f ($dns.ServerAddresses -join ", "))
}

# ============================================================
# POTENTIAL ISSUES DETECTED
# ============================================================
Add-Section "POTENTIAL ISSUES DETECTED"

$issues = @()

# Multiple Chrome profiles with different accounts
if ($chromeProfiles.Count -gt 1) {
    $signedInProfiles = $chromeProfiles | Where-Object { $_.GoogleEmail -ne "Not signed in" }
    $uniqueAccounts = $signedInProfiles.GoogleEmail | Select-Object -Unique
    if ($uniqueAccounts.Count -gt 1) {
        $issues += "Multiple Google accounts signed into Chrome - may cause sync confusion"
    }
}

# Both old and new Google Drive
if ((Test-Path $gdriveDesktop) -and (Test-Path $backupSync)) {
    $issues += "Both Google Drive for Desktop AND Backup & Sync installed - should only have one"
}

# Low disk space
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $pctUsed = [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 0)
    if ($pctUsed -gt 90) {
        $issues += "Low disk space on $($_.DeviceID) ($pctUsed% used)"
    }
}

# No antivirus (basic check)
$defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
if (-not $defender -or -not $defender.RealTimeProtectionEnabled) {
    $issues += "Windows Defender real-time protection may be disabled"
}

if ($issues.Count -gt 0) {
    $issues | ForEach-Object { Add-Line "  [!] $_" }
} else {
    Add-Line "  No obvious issues detected"
}

# ============================================================
# SAVE REPORT
# ============================================================
Add-Section "END OF REPORT"
Add-Line ("  Generated: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Add-Line ("  Computer: {0}" -f $env:COMPUTERNAME)

# Write to file
$reportData | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "   DIAGNOSTIC COMPLETE" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Report saved to:" -ForegroundColor Cyan
Write-Host "  $reportFile" -ForegroundColor White
Write-Host ""
Write-Host "Quick Summary:" -ForegroundColor Yellow

# Print summary to console
$chromeAccountCount = ($chromeProfiles | Where-Object { $_.GoogleEmail -ne "Not signed in" }).Count
Write-Host "  - Chrome profiles: $($chromeProfiles.Count) ($chromeAccountCount signed in)" -ForegroundColor White
Write-Host "  - Google Drive: $(if (Test-Path $gdriveDesktop) { 'Drive for Desktop' } elseif (Test-Path $backupSync) { 'Backup & Sync (old)' } else { 'Not installed' })" -ForegroundColor White
Write-Host "  - Issues found: $($issues.Count)" -ForegroundColor $(if ($issues.Count -gt 0) { "Red" } else { "Green" })

Write-Host ""
Write-Host "Press any key to open the report..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Open the report
Start-Process notepad.exe -ArgumentList $reportFile
