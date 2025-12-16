<#
.SYNOPSIS
    One-click bootstrap for remote tech support. Run this first.
.DESCRIPTION
    Downloads and installs RustDesk, then displays the connection info.
    Send the ID and password to whoever is helping you.
.NOTES
    This script requires Administrator privileges.
    Run: powershell -ExecutionPolicy Bypass -File bootstrap.ps1
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   REMOTE TECH SUPPORT - BOOTSTRAP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Helper Functions ---
function Write-Step { param([string]$msg) Write-Host "[*] $msg" -ForegroundColor Yellow }
function Write-Success { param([string]$msg) Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Info { param([string]$msg) Write-Host "[i] $msg" -ForegroundColor Cyan }

# --- Install RustDesk ---
Write-Step "Checking for RustDesk..."

$rustdeskExe = "$env:ProgramFiles\RustDesk\rustdesk.exe"
$rustdeskInstalled = Test-Path $rustdeskExe

if (-not $rustdeskInstalled) {
    Write-Step "Downloading RustDesk..."

    # Get latest release from GitHub
    $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/rustdesk/rustdesk/releases/latest"
    $asset = $releases.assets | Where-Object { $_.name -match "x86_64\.exe$" -and $_.name -notmatch "portable" } | Select-Object -First 1

    if (-not $asset) {
        throw "Could not find RustDesk installer on GitHub releases"
    }

    $installerPath = Join-Path $env:TEMP $asset.name
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installerPath

    Write-Step "Installing RustDesk (this may take a minute)..."
    Start-Process -FilePath $installerPath -ArgumentList "--silent-install" -Wait

    # Wait for installation to complete
    $timeout = 60
    $elapsed = 0
    while (-not (Test-Path $rustdeskExe) -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds 2
        $elapsed += 2
    }

    if (-not (Test-Path $rustdeskExe)) {
        throw "RustDesk installation failed or timed out"
    }

    Write-Success "RustDesk installed!"
} else {
    Write-Success "RustDesk already installed"
}

# --- Start RustDesk service ---
Write-Step "Starting RustDesk service..."
$service = Get-Service -Name "RustDesk" -ErrorAction SilentlyContinue
if ($service) {
    if ($service.Status -ne "Running") {
        Start-Service -Name "RustDesk"
    }
} else {
    # Start the app if service doesn't exist yet
    Start-Process -FilePath $rustdeskExe
    Start-Sleep -Seconds 3
}

# --- Get RustDesk ID ---
Write-Step "Getting your RustDesk ID..."

# RustDesk stores config in different locations
$configPaths = @(
    "$env:APPDATA\RustDesk\config\RustDesk.toml",
    "$env:ProgramData\RustDesk\config\RustDesk.toml",
    "$env:USERPROFILE\.config\rustdesk\RustDesk.toml"
)

$rustdeskId = $null
foreach ($path in $configPaths) {
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        if ($content -match 'id\s*=\s*[''"]?(\d+)[''"]?') {
            $rustdeskId = $matches[1]
            break
        }
    }
}

# Also try the ID file
$idFilePaths = @(
    "$env:APPDATA\RustDesk\config\id",
    "$env:ProgramData\RustDesk\config\id"
)

if (-not $rustdeskId) {
    foreach ($path in $idFilePaths) {
        if (Test-Path $path) {
            $rustdeskId = (Get-Content $path -Raw).Trim()
            break
        }
    }
}

# --- Display Results ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   SETUP COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

if ($rustdeskId) {
    Write-Host "Your RustDesk ID: " -NoNewline
    Write-Host $rustdeskId -ForegroundColor Yellow -BackgroundColor DarkBlue
} else {
    Write-Host "RustDesk ID: " -NoNewline
    Write-Host "(Check the RustDesk window)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Open RustDesk (should be open now)" -ForegroundColor White
Write-Host "2. Find your ID and Password in the RustDesk window" -ForegroundColor White
Write-Host "3. Send BOTH to whoever is helping you" -ForegroundColor White
Write-Host "4. When they connect, click 'Accept'" -ForegroundColor White
Write-Host ""

# Open RustDesk if not already running
$rustdeskProcess = Get-Process -Name "rustdesk" -ErrorAction SilentlyContinue
if (-not $rustdeskProcess) {
    Write-Info "Opening RustDesk..."
    Start-Process -FilePath $rustdeskExe
}

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
