<#
.SYNOPSIS
    Tech Support Toolkit - Master Launcher
.DESCRIPTION
    Interactive menu to launch any tech support script.
    One script to rule them all.
.PARAMETER Script
    Directly run a specific script: diagnose, google, backup, browser, tools, fix, claude, verify, setup, winutil
.PARAMETER Quick
    Run quick diagnostic without menu
.EXAMPLE
    .\Start-TechSupport.ps1
    .\Start-TechSupport.ps1 -Script diagnose
    .\Start-TechSupport.ps1 -Quick
#>

param(
    [ValidateSet("diagnose", "google", "backup", "browser", "tools", "fix", "claude", "verify", "setup", "winutil", "")]
    [string]$Script,

    [switch]$Quick
)

$ErrorActionPreference = "Continue"
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$scriptsDir = Join-Path $scriptDir "scripts"

# Import module if available
$modulePath = Join-Path $scriptDir "modules\TechSupport.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force -ErrorAction SilentlyContinue
}

# Color helpers (fallback if module not loaded)
if (-not (Get-Command Write-TSBanner -ErrorAction SilentlyContinue)) {
    function Write-TSBanner { param([string]$Title) Write-Host "`n=== $Title ===`n" -ForegroundColor Cyan }
    function Write-TSSuccess { param([string]$Message) Write-Host "[+] $Message" -ForegroundColor Green }
    function Write-TSError { param([string]$Message) Write-Host "[!] $Message" -ForegroundColor Red }
    function Write-TSInfo { param([string]$Message) Write-Host "[i] $Message" -ForegroundColor Cyan }
}

# Script mapping
$scripts = @{
    "1" = @{ Name = "diagnose"; File = "diagnose.ps1"; Desc = "Full System Diagnostic"; Icon = "🔍" }
    "2" = @{ Name = "google"; File = "google-audit.ps1"; Desc = "Google Account Audit"; Icon = "📧" }
    "3" = @{ Name = "backup"; File = "backup.ps1"; Desc = "Backup User Data"; Icon = "💾" }
    "4" = @{ Name = "browser"; File = "browser-cleanup.ps1"; Desc = "Browser Cleanup"; Icon = "🌐" }
    "5" = @{ Name = "tools"; File = "install-tools.ps1"; Desc = "Install Tools"; Icon = "🔧" }
    "6" = @{ Name = "fix"; File = "fix-common.ps1"; Desc = "Common Fixes & WinUtil"; Icon = "🔨" }
    "7" = @{ Name = "claude"; File = "claude-code.ps1"; Desc = "Claude Code Manager"; Icon = "🤖" }
    "8" = @{ Name = "verify"; File = "verify.ps1"; Desc = "Verify Remote Access"; Icon = "✅" }
    "9" = @{ Name = "setup"; File = "setup.ps1"; Desc = "Full Remote Setup"; Icon = "⚙️" }
    "0" = @{ Name = "winutil"; File = "winutil.ps1"; Desc = "Chris Titus WinUtil"; Icon = "🛠️" }
}

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                           ║" -ForegroundColor Cyan
    Write-Host "  ║           TECH SUPPORT TOOLKIT v1.1                       ║" -ForegroundColor Cyan
    Write-Host "  ║           Remote Family Tech Support Made Easy            ║" -ForegroundColor Cyan
    Write-Host "  ║                                                           ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
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
    Write-Host "    Q. Quit"
    Write-Host "    H. Help / Documentation"
    Write-Host ""

    # Show system status
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $adminStatus = if ($isAdmin) { "Yes" } else { "No (some features limited)" }
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  Computer: $env:COMPUTERNAME | Admin: $adminStatus" -ForegroundColor DarkGray
    Write-Host ""
}

function Invoke-Script {
    param([string]$ScriptFile, [array]$Arguments)

    $path = Join-Path $scriptsDir $ScriptFile

    if (-not (Test-Path $path)) {
        Write-TSError "Script not found: $path"
        return
    }

    Write-Host ""
    Write-Host "Running $ScriptFile..." -ForegroundColor Green
    Write-Host ("─" * 60) -ForegroundColor DarkGray
    Write-Host ""

    try {
        if ($Arguments) {
            & $path @Arguments
        } else {
            & $path
        }
    }
    catch {
        Write-TSError "Script error: $_"
    }

    Write-Host ""
    Write-Host ("─" * 60) -ForegroundColor DarkGray
    Write-Host "Press any key to return to menu..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Help {
    Clear-Host
    Write-TSBanner "HELP & DOCUMENTATION"

    Write-Host @"
RECOMMENDED WORKFLOW
────────────────────
1. Run DIAGNOSTIC first (option 1) to understand the system
2. Run BACKUP (option 3) before making changes
3. Use targeted fixes based on the issue
4. Run VERIFY (option 8) to confirm remote access works

COMMON SCENARIOS
────────────────
• Google account confusion → Option 2 (Google Audit)
• Computer is slow → Option 6 (Common Fixes) or Option 0 (WinUtil)
• Browser issues → Option 4 (Browser Cleanup)
• Setting up remote access → Option 9 (Full Setup)

KEYBOARD SHORTCUTS
──────────────────
• Run directly: .\Start-TechSupport.ps1 -Script diagnose
• Quick diagnostic: .\Start-TechSupport.ps1 -Quick

MORE HELP
─────────
• README: $scriptDir\README.md
• Google Guide: $scriptDir\docs\GOOGLE-ACCOUNT-GUIDE.md
• Cheatsheet: $scriptDir\docs\CHEATSHEET.md
• Claude Guide: $scriptDir\CLAUDE.md

"@ -ForegroundColor White

    Write-Host "Press any key to return to menu..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ============================================================
# MAIN
# ============================================================

# Direct script execution
if ($Script) {
    $match = $scripts.Values | Where-Object { $_.Name -eq $Script }
    if ($match) {
        Invoke-Script -ScriptFile $match.File
        exit
    }
}

# Quick mode
if ($Quick) {
    Invoke-Script -ScriptFile "diagnose.ps1" -Arguments @("-Quick")
    exit
}

# Interactive menu
while ($true) {
    Show-Menu

    $choice = Read-Host "  Select option"

    switch ($choice.ToUpper()) {
        "Q" { Write-Host "`nGoodbye!`n" -ForegroundColor Cyan; exit }
        "H" { Show-Help }
        default {
            if ($scripts.ContainsKey($choice)) {
                $script = $scripts[$choice]

                # Special handling for certain scripts
                switch ($script.Name) {
                    "claude" {
                        Write-Host ""
                        Write-Host "Claude Code options:" -ForegroundColor Yellow
                        Write-Host "  1. Check Status"
                        Write-Host "  2. Install"
                        Write-Host "  3. Login"
                        Write-Host "  4. Logout"
                        $subChoice = Read-Host "Select"
                        $action = switch ($subChoice) {
                            "1" { "Status" }
                            "2" { "Install" }
                            "3" { "Login" }
                            "4" { "Logout" }
                            default { "Status" }
                        }
                        Invoke-Script -ScriptFile $script.File -Arguments @("-Action", $action)
                    }
                    "tools" {
                        Write-Host ""
                        Write-Host "Install options:" -ForegroundColor Yellow
                        Write-Host "  1. List installed vs available"
                        Write-Host "  2. Install essential tools"
                        Write-Host "  3. Install all tools"
                        Write-Host "  4. Interactive selection"
                        $subChoice = Read-Host "Select"
                        $args = switch ($subChoice) {
                            "1" { @("-List") }
                            "2" { @("-Essential") }
                            "3" { @("-All") }
                            default { @() }
                        }
                        Invoke-Script -ScriptFile $script.File -Arguments $args
                    }
                    "setup" {
                        Invoke-Script -ScriptFile $script.File -Arguments @("-Interactive")
                    }
                    default {
                        Invoke-Script -ScriptFile $script.File
                    }
                }
            }
            else {
                Write-Host "`n  Invalid option. Try again.`n" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}
