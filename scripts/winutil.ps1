<#
.SYNOPSIS
    Launch Chris Titus Tech's WinUtil - the most popular Windows utility on GitHub.
.DESCRIPTION
    WinUtil provides:
    - Program installation (one-click install multiple apps)
    - Windows debloating and optimization
    - System tweaks and fixes
    - Windows Update management
    - MicroWin (create minimal Windows ISO)

    This is complementary to our toolkit - WinUtil handles Windows optimization,
    we handle remote access setup and Google account issues.
.PARAMETER Dev
    Launch the development/pre-release version.
.LINK
    https://github.com/ChrisTitusTech/winutil
    https://christitus.com/windows-tool/
#>

param(
    [switch]$Dev
)

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   CHRIS TITUS TECH - WINUTIL" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "WinUtil is the #1 most starred PowerShell project on GitHub." -ForegroundColor Gray
Write-Host "It provides comprehensive Windows optimization and fixes." -ForegroundColor Gray
Write-Host ""
Write-Host "Features:" -ForegroundColor Yellow
Write-Host "  - Install programs (one-click bulk install)"
Write-Host "  - Windows debloating"
Write-Host "  - System tweaks and optimizations"
Write-Host "  - Fix Windows Update issues"
Write-Host "  - Remove telemetry"
Write-Host "  - Create minimal Windows ISO (MicroWin)"
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[!] WinUtil requires Administrator privileges." -ForegroundColor Red
    Write-Host "    Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""

    $elevate = Read-Host "Attempt to relaunch as Admin? (Y/n)"
    if ($elevate -ne "n") {
        $script = if ($Dev) { "irm https://christitus.com/windev | iex" } else { "irm https://christitus.com/win | iex" }
        Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -Command `"$script`""
        exit
    }
    exit 1
}

Write-Host "Launching WinUtil..." -ForegroundColor Green
Write-Host ""

if ($Dev) {
    Write-Host "Using DEVELOPMENT version (pre-release features)" -ForegroundColor Magenta
    Invoke-RestMethod https://christitus.com/windev | Invoke-Expression
} else {
    Write-Host "Using STABLE version" -ForegroundColor Green
    Invoke-RestMethod https://christitus.com/win | Invoke-Expression
}
