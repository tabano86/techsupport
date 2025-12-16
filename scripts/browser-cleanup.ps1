<#
.SYNOPSIS
    Clean up browser data and reset profiles.
.DESCRIPTION
    Options:
    - Clear cache and temp files (keeps bookmarks/passwords)
    - Clear all browsing data
    - Remove specific Chrome profiles
    - Reset browser to clean state
.PARAMETER Browser
    Which browser to clean: Chrome, Edge, All
.PARAMETER CacheOnly
    Only clear cache, keep bookmarks and passwords.
#>

param(
    [ValidateSet("Chrome", "Edge", "All")]
    [string]$Browser = "All",

    [switch]$CacheOnly
)

$ErrorActionPreference = "Continue"

function Write-Step { param([string]$msg) Write-Host "[*] $msg" -ForegroundColor Yellow }
function Write-Success { param([string]$msg) Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "[!] $msg" -ForegroundColor Red }

function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
        return [math]::Round($size / 1MB, 1)
    }
    return 0
}

function Stop-BrowserProcesses {
    param([string]$BrowserName)

    $processes = @{
        "Chrome" = @("chrome", "GoogleUpdate")
        "Edge" = @("msedge", "MicrosoftEdgeUpdate")
    }

    $toStop = if ($BrowserName -eq "All") {
        $processes.Values | ForEach-Object { $_ }
    } else {
        $processes[$BrowserName]
    }

    $toStop | ForEach-Object {
        Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   BROWSER CLEANUP" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Show current cache sizes
Write-Host "Current browser data sizes:" -ForegroundColor Yellow
Write-Host ""

$chromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
$chromeCodeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache"
$edgeCache = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"

$chromeCacheSize = (Get-FolderSize $chromeCache) + (Get-FolderSize $chromeCodeCache)
$edgeCacheSize = Get-FolderSize $edgeCache

Write-Host "  Chrome cache: $chromeCacheSize MB"
Write-Host "  Edge cache: $edgeCacheSize MB"
Write-Host ""

# Menu
Write-Host "What do you want to do?" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Clear cache only (keeps bookmarks, passwords, history)"
Write-Host "  2. Clear cache + history (keeps bookmarks, passwords)"
Write-Host "  3. View Chrome profiles"
Write-Host "  4. Remove a Chrome profile"
Write-Host "  5. Nuclear option - complete browser reset"
Write-Host "  6. Exit"
Write-Host ""

$choice = Read-Host "Select option (1-6)"

switch ($choice) {
    "1" {
        # Clear cache only
        Write-Host ""
        Write-Step "Closing browsers..."
        Stop-BrowserProcesses -BrowserName $Browser

        Write-Step "Clearing cache..."

        if ($Browser -in @("Chrome", "All")) {
            $chromePaths = @(
                "$env:LOCALAPPDATA\Google\Chrome\User Data\*\Cache",
                "$env:LOCALAPPDATA\Google\Chrome\User Data\*\Code Cache",
                "$env:LOCALAPPDATA\Google\Chrome\User Data\*\GPUCache"
            )

            foreach ($path in $chromePaths) {
                Get-ChildItem $path -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
            Write-Success "Chrome cache cleared"
        }

        if ($Browser -in @("Edge", "All")) {
            $edgePaths = @(
                "$env:LOCALAPPDATA\Microsoft\Edge\User Data\*\Cache",
                "$env:LOCALAPPDATA\Microsoft\Edge\User Data\*\Code Cache",
                "$env:LOCALAPPDATA\Microsoft\Edge\User Data\*\GPUCache"
            )

            foreach ($path in $edgePaths) {
                Get-ChildItem $path -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
            Write-Success "Edge cache cleared"
        }

        $newChromeSize = (Get-FolderSize $chromeCache) + (Get-FolderSize $chromeCodeCache)
        $saved = $chromeCacheSize - $newChromeSize + $edgeCacheSize - (Get-FolderSize $edgeCache)
        Write-Host ""
        Write-Success "Freed approximately $saved MB"
    }

    "2" {
        # Clear cache + history
        Write-Warn "This will clear your browsing history!"
        $confirm = Read-Host "Continue? (y/N)"

        if ($confirm -eq "y") {
            Write-Step "Closing browsers..."
            Stop-BrowserProcesses -BrowserName $Browser

            if ($Browser -in @("Chrome", "All")) {
                $chromePaths = @(
                    "$env:LOCALAPPDATA\Google\Chrome\User Data\*\Cache",
                    "$env:LOCALAPPDATA\Google\Chrome\User Data\*\Code Cache",
                    "$env:LOCALAPPDATA\Google\Chrome\User Data\*\History",
                    "$env:LOCALAPPDATA\Google\Chrome\User Data\*\History-journal",
                    "$env:LOCALAPPDATA\Google\Chrome\User Data\*\Visited Links"
                )

                foreach ($path in $chromePaths) {
                    Get-ChildItem $path -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                }
                Write-Success "Chrome cache + history cleared"
            }

            if ($Browser -in @("Edge", "All")) {
                $edgePaths = @(
                    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\*\Cache",
                    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\*\Code Cache",
                    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\*\History",
                    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\*\History-journal"
                )

                foreach ($path in $edgePaths) {
                    Get-ChildItem $path -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                }
                Write-Success "Edge cache + history cleared"
            }
        }
    }

    "3" {
        # View Chrome profiles
        Write-Host ""
        Write-Host "Chrome Profiles:" -ForegroundColor Yellow
        Write-Host ""

        $chromeUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data"
        if (Test-Path $chromeUserData) {
            $profiles = Get-ChildItem $chromeUserData -Directory | Where-Object {
                $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$"
            }

            foreach ($profile in $profiles) {
                $prefsFile = Join-Path $profile.FullName "Preferences"
                $displayName = $profile.Name
                $email = "Not signed in"

                if (Test-Path $prefsFile) {
                    try {
                        $prefs = Get-Content $prefsFile -Raw | ConvertFrom-Json
                        if ($prefs.profile.name) { $displayName = $prefs.profile.name }
                        if ($prefs.account_info -and $prefs.account_info[0].email) {
                            $email = $prefs.account_info[0].email
                        }
                    } catch {}
                }

                $size = Get-FolderSize $profile.FullName
                Write-Host "  [$($profile.Name)] $displayName"
                Write-Host "      Account: $email"
                Write-Host "      Size: $size MB"
                Write-Host ""
            }
        }
    }

    "4" {
        # Remove Chrome profile
        Write-Host ""
        Write-Warn "WARNING: This permanently deletes a Chrome profile!"
        Write-Host ""

        $chromeUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data"
        $profiles = Get-ChildItem $chromeUserData -Directory | Where-Object {
            $_.Name -match "^Profile \d+$"  # Don't show Default
        }

        if ($profiles.Count -eq 0) {
            Write-Host "No additional profiles to remove (only Default exists)" -ForegroundColor Gray
        } else {
            Write-Host "Removable profiles:" -ForegroundColor Yellow
            $i = 1
            foreach ($profile in $profiles) {
                $prefsFile = Join-Path $profile.FullName "Preferences"
                $displayName = $profile.Name

                if (Test-Path $prefsFile) {
                    try {
                        $prefs = Get-Content $prefsFile -Raw | ConvertFrom-Json
                        if ($prefs.profile.name) { $displayName = $prefs.profile.name }
                    } catch {}
                }

                Write-Host "  $i. [$($profile.Name)] $displayName"
                $i++
            }

            Write-Host ""
            $selection = Read-Host "Enter number to delete (or press Enter to cancel)"

            if ($selection -and $selection -match "^\d+$") {
                $idx = [int]$selection - 1
                if ($idx -ge 0 -and $idx -lt $profiles.Count) {
                    $toDelete = $profiles[$idx]

                    $confirm = Read-Host "Delete '$($toDelete.Name)'? Type 'DELETE' to confirm"
                    if ($confirm -eq "DELETE") {
                        Stop-BrowserProcesses -BrowserName "Chrome"
                        Remove-Item $toDelete.FullName -Recurse -Force
                        Write-Success "Profile deleted"
                    }
                }
            }
        }
    }

    "5" {
        # Nuclear option
        Write-Host ""
        Write-Warn "!!! NUCLEAR OPTION !!!"
        Write-Warn "This will completely reset your browser(s) to factory state!"
        Write-Warn "ALL bookmarks, passwords, history, and extensions will be DELETED!"
        Write-Host ""
        Write-Host "Make sure you have:" -ForegroundColor Yellow
        Write-Host "  - Exported bookmarks" -ForegroundColor Yellow
        Write-Host "  - Exported passwords (or use a password manager)" -ForegroundColor Yellow
        Write-Host "  - Run backup.ps1" -ForegroundColor Yellow
        Write-Host ""

        $confirm = Read-Host "Type 'RESET' to continue"

        if ($confirm -eq "RESET") {
            Write-Step "Closing browsers..."
            Stop-BrowserProcesses -BrowserName "All"

            Write-Step "Deleting Chrome user data..."
            $chromeUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data"
            if (Test-Path $chromeUserData) {
                # Backup Local State (needed for encryption)
                $localState = "$chromeUserData\Local State"
                $localStateBackup = "$env:TEMP\chrome_localstate_backup"
                if (Test-Path $localState) {
                    Copy-Item $localState -Destination $localStateBackup -Force
                }

                Remove-Item "$chromeUserData\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Success "Chrome reset"
            }

            Write-Step "Deleting Edge user data..."
            $edgeUserData = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
            if (Test-Path $edgeUserData) {
                Remove-Item "$edgeUserData\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Success "Edge reset"
            }

            Write-Host ""
            Write-Success "Browser reset complete. Restart your browser to set it up fresh."
        }
    }

    "6" {
        Write-Host "Bye!" -ForegroundColor Gray
    }

    default {
        Write-Host "Invalid option" -ForegroundColor Red
    }
}
