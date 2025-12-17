<#
.SYNOPSIS
    Tech Support Toolkit - Master Launcher
.DESCRIPTION
    Interactive menu to launch any tech support script.
.EXAMPLE
    .\Start-TechSupport.ps1
    .\Start-TechSupport.ps1 -Script diagnose
#>

param(
    [ValidateSet("diagnose", "google", "backup", "browser", "tools", "fix", "claude", "verify", "setup", "winutil", "")]
    [string]$Script,
    [switch]$Quick,
    [switch]$Debug
)

$ErrorActionPreference = "Stop"

# Robust path resolution
$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
}
if (-not $scriptDir) {
    $scriptDir = (Get-Location).Path
}

$scriptsDir = Join-Path $scriptDir "scripts"

# Debug output
if ($Debug) {
    Write-Host "DEBUG: scriptDir = $scriptDir" -ForegroundColor Magenta
    Write-Host "DEBUG: scriptsDir = $scriptsDir" -ForegroundColor Magenta
    Write-Host "DEBUG: scriptsDir exists = $(Test-Path $scriptsDir)" -ForegroundColor Magenta
}

# Verify scripts directory exists
if (-not (Test-Path $scriptsDir)) {
    Write-Host ""
    Write-Host "[ERROR] Scripts directory not found: $scriptsDir" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure you're running from the techsupport folder," -ForegroundColor Yellow
    Write-Host "or that the 'scripts' subfolder exists." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Expected structure:" -ForegroundColor Gray
    Write-Host "  techsupport/" -ForegroundColor Gray
    Write-Host "    Start-TechSupport.ps1  <-- you are here" -ForegroundColor Gray
    Write-Host "    scripts/" -ForegroundColor Gray
    Write-Host "      diagnose.ps1" -ForegroundColor Gray
    Write-Host "      ..." -ForegroundColor Gray
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Script definitions
$scriptList = @{
    "1" = @{ Name = "diagnose"; File = "diagnose.ps1"; Desc = "Full System Diagnostic" }
    "2" = @{ Name = "google"; File = "google-audit.ps1"; Desc = "Google Account Audit" }
    "3" = @{ Name = "backup"; File = "backup.ps1"; Desc = "Backup User Data" }
    "4" = @{ Name = "browser"; File = "browser-cleanup.ps1"; Desc = "Browser Cleanup" }
    "5" = @{ Name = "tools"; File = "install-tools.ps1"; Desc = "Install Tools" }
    "6" = @{ Name = "fix"; File = "fix-common.ps1"; Desc = "Common Fixes + WinUtil" }
    "7" = @{ Name = "claude"; File = "claude-code.ps1"; Desc = "Claude Code Manager" }
    "8" = @{ Name = "verify"; File = "verify.ps1"; Desc = "Verify Remote Setup" }
    "9" = @{ Name = "setup"; File = "setup.ps1"; Desc = "Full Remote Setup" }
    "0" = @{ Name = "winutil"; File = "winutil.ps1"; Desc = "WinUtil Launcher" }
}

function Run-Script {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptFile,
        [array]$Arguments = @()
    )

    $fullPath = Join-Path $scriptsDir $ScriptFile

    if ($Debug) {
        Write-Host "DEBUG: Attempting to run: $fullPath" -ForegroundColor Magenta
    }

    if (-not (Test-Path $fullPath)) {
        Write-Host ""
        Write-Host "[ERROR] Script not found: $fullPath" -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to continue"
        return
    }

    Write-Host ""
    Write-Host "Running $ScriptFile..." -ForegroundColor Green
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    Write-Host ""

    try {
        & $fullPath @Arguments
    }
    catch {
        Write-Host ""
        Write-Host "[ERROR] Script failed: $_" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "Press Enter to return to menu"
}

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |         TECH SUPPORT TOOLKIT v1.1                         |" -ForegroundColor Cyan
    Write-Host "  |         Remote Family Tech Support Made Easy              |" -ForegroundColor Cyan
    Write-Host "  +-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  DIAGNOSTIC" -ForegroundColor Yellow
    Write-Host "    1. Full System Diagnostic        (diagnose.ps1)"
    Write-Host "    2. Google Account Audit          (google-audit.ps1)"
    Write-Host ""
    Write-Host "  BACKUP & CLEANUP" -ForegroundColor Yellow
    Write-Host "    3. Backup User Data              (backup.ps1)"
    Write-Host "    4. Browser Cleanup               (browser-cleanup.ps1)"
    Write-Host ""
    Write-Host "  FIXES & TOOLS" -ForegroundColor Yellow
    Write-Host "    5. Install Useful Tools          (install-tools.ps1)"
    Write-Host "    6. Common Fixes + WinUtil        (fix-common.ps1)"
    Write-Host "    0. Launch WinUtil Directly       (winutil.ps1)"
    Write-Host ""
    Write-Host "  REMOTE ACCESS" -ForegroundColor Yellow
    Write-Host "    7. Claude Code Manager           (claude-code.ps1)"
    Write-Host "    8. Verify Remote Setup           (verify.ps1)"
    Write-Host "    9. Full Remote Access Setup      (setup.ps1)"
    Write-Host ""
    Write-Host "  OTHER" -ForegroundColor Yellow
    Write-Host "    H. Help"
    Write-Host "    Q. Quit"
    Write-Host ""

    # Status line
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $adminText = if ($isAdmin) { "Yes" } else { "No (run as Admin for full features)" }
    Write-Host "  -----------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Computer: $env:COMPUTERNAME | Admin: $adminText" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Help {
    Clear-Host
    Write-Host ""
    Write-Host "  HELP - Tech Support Toolkit" -ForegroundColor Cyan
    Write-Host "  ===========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  WORKFLOW:" -ForegroundColor Yellow
    Write-Host "    1. Run diagnostic (option 1) first"
    Write-Host "    2. Backup data (option 3) before changes"
    Write-Host "    3. Fix issues (options 2, 4, 5, 6)"
    Write-Host "    4. Verify (option 8)"
    Write-Host ""
    Write-Host "  COMMON ISSUES:" -ForegroundColor Yellow
    Write-Host "    Google confusion  -> Option 2"
    Write-Host "    Slow computer     -> Option 6, then 0"
    Write-Host "    Browser problems  -> Option 4"
    Write-Host ""
    Write-Host "  DOCS: $scriptDir\docs\" -ForegroundColor Gray
    Write-Host ""
    Read-Host "Press Enter to return"
}

# === MAIN ===

# Direct script mode
if ($Script) {
    $found = $scriptList.Values | Where-Object { $_.Name -eq $Script } | Select-Object -First 1
    if ($found) {
        Run-Script -ScriptFile $found.File
    } else {
        Write-Host "Unknown script: $Script" -ForegroundColor Red
    }
    exit
}

# Quick mode
if ($Quick) {
    Run-Script -ScriptFile "diagnose.ps1" -Arguments @("-Quick")
    exit
}

# Interactive menu loop
while ($true) {
    Show-Menu

    $choice = Read-Host "  Select option"
    $choice = $choice.Trim().ToUpper()

    if ($Debug) {
        Write-Host "DEBUG: User entered: '$choice'" -ForegroundColor Magenta
        Write-Host "DEBUG: Key exists: $($scriptList.ContainsKey($choice))" -ForegroundColor Magenta
    }

    switch ($choice) {
        "Q" {
            Write-Host "`nGoodbye!`n" -ForegroundColor Cyan
            exit
        }
        "H" {
            Show-Help
        }
        default {
            if ($scriptList.ContainsKey($choice)) {
                $selected = $scriptList[$choice]

                # Handle special cases
                switch ($selected.Name) {
                    "claude" {
                        Write-Host ""
                        Write-Host "  Claude Code options:" -ForegroundColor Yellow
                        Write-Host "    1. Check Status"
                        Write-Host "    2. Install"
                        Write-Host "    3. Login"
                        Write-Host "    4. Logout"
                        Write-Host ""
                        $sub = Read-Host "  Select (1-4)"
                        $action = switch ($sub) {
                            "1" { "Status" }
                            "2" { "Install" }
                            "3" { "Login" }
                            "4" { "Logout" }
                            default { "Status" }
                        }
                        Run-Script -ScriptFile $selected.File -Arguments @("-Action", $action)
                    }
                    "tools" {
                        Write-Host ""
                        Write-Host "  Install options:" -ForegroundColor Yellow
                        Write-Host "    1. List what's installed"
                        Write-Host "    2. Install essential tools"
                        Write-Host "    3. Install all tools"
                        Write-Host "    4. Interactive selection"
                        Write-Host ""
                        $sub = Read-Host "  Select (1-4)"
                        $toolArgs = switch ($sub) {
                            "1" { @("-List") }
                            "2" { @("-Essential") }
                            "3" { @("-All") }
                            default { @() }
                        }
                        Run-Script -ScriptFile $selected.File -Arguments $toolArgs
                    }
                    "setup" {
                        Run-Script -ScriptFile $selected.File -Arguments @("-Interactive")
                    }
                    default {
                        Run-Script -ScriptFile $selected.File
                    }
                }
            }
            else {
                Write-Host ""
                Write-Host "  Invalid option: '$choice'" -ForegroundColor Red
                Write-Host "  Enter a number (0-9), H for help, or Q to quit." -ForegroundColor Yellow
                Write-Host ""
                Start-Sleep -Seconds 2
            }
        }
    }
}
