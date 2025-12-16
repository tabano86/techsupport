<#
.SYNOPSIS
    Install useful tools via winget.
.DESCRIPTION
    Installs a curated set of useful utilities:
    - Essential: 7-Zip, Notepad++, PowerShell 7
    - Browsers: Firefox (backup browser)
    - Utilities: Everything (file search), TreeSize, HWiNFO
    - Security: Bitwarden (password manager)
    - Remote: RustDesk, Tailscale
.PARAMETER Essential
    Only install essential tools.
.PARAMETER All
    Install everything without prompting.
.PARAMETER List
    Just list what would be installed.
#>

param(
    [switch]$Essential,
    [switch]$All,
    [switch]$List
)

$ErrorActionPreference = "Continue"

# Tool categories
$tools = @{
    "Essential" = @(
        @{ id = "7zip.7zip"; name = "7-Zip"; desc = "File compression" }
        @{ id = "Notepad++.Notepad++"; name = "Notepad++"; desc = "Text editor" }
        @{ id = "Microsoft.PowerShell"; name = "PowerShell 7"; desc = "Modern PowerShell" }
        @{ id = "Git.Git"; name = "Git"; desc = "Version control" }
    )
    "Utilities" = @(
        @{ id = "voidtools.Everything"; name = "Everything"; desc = "Instant file search" }
        @{ id = "JAMSoftware.TreeSize.Free"; name = "TreeSize Free"; desc = "Disk space analyzer" }
        @{ id = "REALiX.HWiNFO"; name = "HWiNFO"; desc = "Hardware info" }
        @{ id = "Microsoft.WindowsTerminal"; name = "Windows Terminal"; desc = "Modern terminal" }
        @{ id = "BleachBit.BleachBit"; name = "BleachBit"; desc = "System cleaner" }
    )
    "Browsers" = @(
        @{ id = "Mozilla.Firefox"; name = "Firefox"; desc = "Backup browser" }
    )
    "Security" = @(
        @{ id = "Bitwarden.Bitwarden"; name = "Bitwarden"; desc = "Password manager" }
        @{ id = "Malwarebytes.Malwarebytes"; name = "Malwarebytes"; desc = "Malware scanner" }
    )
    "Remote" = @(
        @{ id = "Tailscale.Tailscale"; name = "Tailscale"; desc = "VPN mesh network" }
        @{ id = "RustDesk.RustDesk"; name = "RustDesk"; desc = "Remote desktop" }
    )
    "Media" = @(
        @{ id = "VideoLAN.VLC"; name = "VLC"; desc = "Media player" }
        @{ id = "IrfanSkulski.IrfanView"; name = "IrfanView"; desc = "Image viewer" }
    )
}

function Write-Tool {
    param($Tool, [bool]$Installed)
    $status = if ($Installed) { "[OK]" } else { "[  ]" }
    $color = if ($Installed) { "Green" } else { "White" }
    Write-Host ("  {0} {1,-20} - {2}" -f $status, $Tool.name, $Tool.desc) -ForegroundColor $color
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   INSTALL USEFUL TOOLS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check for winget
$hasWinget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $hasWinget) {
    Write-Host "winget is not available on this system." -ForegroundColor Red
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  1. Update Windows (winget comes with App Installer)"
    Write-Host "  2. Install App Installer from Microsoft Store"
    Write-Host "  3. Download from: https://github.com/microsoft/winget-cli/releases"
    exit 1
}

# Get list of installed apps
Write-Host "Checking installed apps..." -ForegroundColor Gray
$installedList = winget list --accept-source-agreements 2>&1 | Out-String

function Test-Installed {
    param([string]$Id)
    return $installedList -match [regex]::Escape($Id)
}

# List mode
if ($List) {
    foreach ($category in $tools.Keys) {
        Write-Host ""
        Write-Host "$category" -ForegroundColor Yellow
        Write-Host ("-" * 40) -ForegroundColor DarkGray

        foreach ($tool in $tools[$category]) {
            $installed = Test-Installed $tool.id
            Write-Tool -Tool $tool -Installed $installed
        }
    }
    exit 0
}

# Selection
$toInstall = @()

if ($Essential) {
    $toInstall = $tools["Essential"]
} elseif ($All) {
    $toInstall = $tools.Values | ForEach-Object { $_ }
} else {
    # Interactive selection
    Write-Host "Select categories to install:" -ForegroundColor Yellow
    Write-Host ""

    $i = 1
    $categoryList = @($tools.Keys)
    foreach ($category in $categoryList) {
        $count = $tools[$category].Count
        Write-Host "  $i. $category ($count tools)"
        $i++
    }
    Write-Host "  A. All categories"
    Write-Host "  E. Essential only"
    Write-Host ""

    $selection = Read-Host "Enter choices (e.g., 1,2,3 or A)"

    if ($selection -eq "A") {
        $toInstall = $tools.Values | ForEach-Object { $_ }
    } elseif ($selection -eq "E") {
        $toInstall = $tools["Essential"]
    } else {
        $indices = $selection -split "," | ForEach-Object { $_.Trim() }
        foreach ($idx in $indices) {
            if ($idx -match "^\d+$") {
                $catIdx = [int]$idx - 1
                if ($catIdx -ge 0 -and $catIdx -lt $categoryList.Count) {
                    $toInstall += $tools[$categoryList[$catIdx]]
                }
            }
        }
    }
}

if ($toInstall.Count -eq 0) {
    Write-Host "Nothing selected." -ForegroundColor Gray
    exit 0
}

# Filter out already installed
$needsInstall = @()
Write-Host ""
Write-Host "Checking what needs to be installed..." -ForegroundColor Gray

foreach ($tool in $toInstall) {
    if (Test-Installed $tool.id) {
        Write-Host "  [SKIP] $($tool.name) (already installed)" -ForegroundColor DarkGray
    } else {
        $needsInstall += $tool
    }
}

if ($needsInstall.Count -eq 0) {
    Write-Host ""
    Write-Host "All selected tools are already installed!" -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "Will install $($needsInstall.Count) tool(s):" -ForegroundColor Yellow
$needsInstall | ForEach-Object { Write-Host "  - $($_.name)" }
Write-Host ""

if (-not $All) {
    $confirm = Read-Host "Continue? (Y/n)"
    if ($confirm -eq "n") { exit 0 }
}

# Install
Write-Host ""
$success = 0
$failed = 0

foreach ($tool in $needsInstall) {
    Write-Host "[*] Installing $($tool.name)..." -ForegroundColor Yellow

    $result = winget install --id $tool.id --accept-source-agreements --accept-package-agreements --silent 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] $($tool.name) installed" -ForegroundColor Green
        $success++
    } else {
        Write-Host "    [FAIL] $($tool.name)" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   INSTALLATION COMPLETE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Installed: $success" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "  Failed: $failed" -ForegroundColor Red
}
Write-Host ""
