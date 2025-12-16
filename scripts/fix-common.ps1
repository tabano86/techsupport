<#
.SYNOPSIS
    Fix common Windows issues with one click.
.DESCRIPTION
    Fixes:
    - Clears temp files and cache
    - Resets Windows Update
    - Clears DNS cache
    - Repairs Windows system files
    - Disables annoying startup programs
    - Fixes common network issues
.PARAMETER All
    Run all fixes automatically.
#>

param(
    [switch]$All
)

$ErrorActionPreference = "Continue"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function Write-Step { param([string]$msg) Write-Host "[*] $msg" -ForegroundColor Yellow }
function Write-Success { param([string]$msg) Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "[!] $msg" -ForegroundColor Red }
function Write-Info { param([string]$msg) Write-Host "[i] $msg" -ForegroundColor Cyan }

function Get-FolderSizeMB {
    param([string]$Path)
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        return [math]::Round($size / 1MB, 1)
    }
    return 0
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   COMMON FIXES" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if (-not $isAdmin) {
    Write-Warn "Some fixes require Administrator privileges!"
    Write-Host "Right-click PowerShell and 'Run as Administrator' for full functionality." -ForegroundColor Yellow
    Write-Host ""
}

# Menu
if (-not $All) {
    Write-Host "Available fixes:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  0. Launch WinUtil (Chris Titus Tech's comprehensive tool)" -ForegroundColor Cyan
    Write-Host "  1. Clear temp files and cache (safe, frees disk space)"
    Write-Host "  2. Clear DNS cache (fixes 'site not loading' issues)"
    Write-Host "  3. Reset network stack (fixes connectivity issues)"
    Write-Host "  4. Repair Windows system files (slow but thorough)"
    Write-Host "  5. Reset Windows Update (fixes stuck updates)"
    Write-Host "  6. Disable annoying startup programs"
    Write-Host "  7. Clear Windows Defender history"
    Write-Host "  8. Run all safe fixes (1, 2, 6)"
    Write-Host "  9. Exit"
    Write-Host ""
    Write-Host "TIP: Option 0 (WinUtil) is recommended for comprehensive fixes!" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select option (0-9)"
} else {
    $choice = "8"
}

switch ($choice) {
    "0" {
        # Launch WinUtil
        Write-Host ""
        Write-Host "Launching Chris Titus Tech's WinUtil..." -ForegroundColor Cyan
        Write-Host "This is a comprehensive Windows utility with:" -ForegroundColor Gray
        Write-Host "  - One-click program installation" -ForegroundColor Gray
        Write-Host "  - Windows debloating" -ForegroundColor Gray
        Write-Host "  - System tweaks and fixes" -ForegroundColor Gray
        Write-Host "  - Windows Update management" -ForegroundColor Gray
        Write-Host ""

        if (-not $isAdmin) {
            Write-Warn "WinUtil requires Administrator privileges."
            $elevate = Read-Host "Relaunch PowerShell as Admin and open WinUtil? (Y/n)"
            if ($elevate -ne "n") {
                Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -Command `"irm https://christitus.com/win | iex`""
            }
        } else {
            Invoke-RestMethod https://christitus.com/win | Invoke-Expression
        }
    }

    "1" {
        # Clear temp files
        Write-Host ""
        Write-Step "Clearing temporary files..."

        $tempPaths = @(
            @{ Path = "$env:TEMP"; Name = "User Temp" },
            @{ Path = "$env:WINDIR\Temp"; Name = "Windows Temp" },
            @{ Path = "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"; Name = "IE Cache" },
            @{ Path = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"; Name = "Explorer Cache" }
        )

        $totalFreed = 0

        foreach ($item in $tempPaths) {
            if (Test-Path $item.Path) {
                $sizeBefore = Get-FolderSizeMB $item.Path

                Get-ChildItem $item.Path -Recurse -Force -ErrorAction SilentlyContinue |
                    Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-1) } |
                    Remove-Item -Force -ErrorAction SilentlyContinue

                $sizeAfter = Get-FolderSizeMB $item.Path
                $freed = $sizeBefore - $sizeAfter

                if ($freed -gt 0) {
                    Write-Success "  $($item.Name): freed $freed MB"
                    $totalFreed += $freed
                } else {
                    Write-Host "  $($item.Name): already clean" -ForegroundColor Gray
                }
            }
        }

        # Windows Update cache
        if ($isAdmin) {
            $wuCache = "$env:WINDIR\SoftwareDistribution\Download"
            if (Test-Path $wuCache) {
                $sizeBefore = Get-FolderSizeMB $wuCache
                Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
                Get-ChildItem $wuCache -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                Start-Service wuauserv -ErrorAction SilentlyContinue
                $freed = $sizeBefore - (Get-FolderSizeMB $wuCache)
                if ($freed -gt 0) {
                    Write-Success "  Windows Update cache: freed $freed MB"
                    $totalFreed += $freed
                }
            }
        }

        Write-Host ""
        Write-Success "Total freed: $totalFreed MB"
    }

    "2" {
        # Clear DNS
        Write-Host ""
        Write-Step "Clearing DNS cache..."

        if ($isAdmin) {
            ipconfig /flushdns | Out-Null
            Write-Success "DNS cache cleared"
            Write-Info "This can fix 'site not loading' errors"
        } else {
            Write-Warn "Requires Administrator privileges"
        }
    }

    "3" {
        # Reset network
        Write-Host ""
        Write-Step "Resetting network stack..."

        if ($isAdmin) {
            Write-Info "This will temporarily disconnect you from the network"
            $confirm = Read-Host "Continue? (y/N)"

            if ($confirm -eq "y") {
                Write-Step "Releasing IP address..."
                ipconfig /release | Out-Null

                Write-Step "Flushing DNS..."
                ipconfig /flushdns | Out-Null

                Write-Step "Resetting Winsock..."
                netsh winsock reset | Out-Null

                Write-Step "Resetting IP stack..."
                netsh int ip reset | Out-Null

                Write-Step "Renewing IP address..."
                ipconfig /renew | Out-Null

                Write-Success "Network stack reset complete"
                Write-Info "A restart is recommended for full effect"
            }
        } else {
            Write-Warn "Requires Administrator privileges"
        }
    }

    "4" {
        # Repair Windows
        Write-Host ""
        Write-Step "Repairing Windows system files..."
        Write-Info "This may take 10-30 minutes"

        if ($isAdmin) {
            $confirm = Read-Host "Continue? (y/N)"
            if ($confirm -eq "y") {
                Write-Step "Running System File Checker (SFC)..."
                sfc /scannow

                Write-Step "Running DISM repair..."
                DISM /Online /Cleanup-Image /RestoreHealth

                Write-Success "System repair complete"
            }
        } else {
            Write-Warn "Requires Administrator privileges"
        }
    }

    "5" {
        # Reset Windows Update
        Write-Host ""
        Write-Step "Resetting Windows Update..."

        if ($isAdmin) {
            Write-Info "This will stop update services and clear the cache"
            $confirm = Read-Host "Continue? (y/N)"

            if ($confirm -eq "y") {
                Write-Step "Stopping Windows Update services..."
                Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
                Stop-Service cryptSvc -Force -ErrorAction SilentlyContinue
                Stop-Service bits -Force -ErrorAction SilentlyContinue
                Stop-Service msiserver -Force -ErrorAction SilentlyContinue

                Write-Step "Clearing update cache..."
                Remove-Item "$env:WINDIR\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item "$env:WINDIR\System32\catroot2\*" -Recurse -Force -ErrorAction SilentlyContinue

                Write-Step "Starting services..."
                Start-Service wuauserv -ErrorAction SilentlyContinue
                Start-Service cryptSvc -ErrorAction SilentlyContinue
                Start-Service bits -ErrorAction SilentlyContinue
                Start-Service msiserver -ErrorAction SilentlyContinue

                Write-Success "Windows Update reset complete"
                Write-Info "Try checking for updates again"
            }
        } else {
            Write-Warn "Requires Administrator privileges"
        }
    }

    "6" {
        # Disable startup programs
        Write-Host ""
        Write-Step "Analyzing startup programs..."

        # Common bloatware startup items
        $bloatware = @(
            "*Spotify*",
            "*Discord*",
            "*Steam*",
            "*Epic*",
            "*Origin*",
            "*Adobe*Update*",
            "*iTunes*Helper*",
            "*OneDrive*",
            "*Cortana*",
            "*Skype*"
        )

        # Get startup items from registry
        $startupItems = @()

        $regPaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
        )

        foreach ($path in $regPaths) {
            if (Test-Path $path) {
                $props = Get-ItemProperty $path -ErrorAction SilentlyContinue
                $props.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" } | ForEach-Object {
                    $isBloat = $false
                    foreach ($pattern in $bloatware) {
                        if ($_.Name -like $pattern -or $_.Value -like $pattern) {
                            $isBloat = $true
                            break
                        }
                    }

                    $startupItems += @{
                        Name = $_.Name
                        Value = $_.Value
                        Path = $path
                        IsBloat = $isBloat
                    }
                }
            }
        }

        if ($startupItems.Count -eq 0) {
            Write-Host "  No startup items found" -ForegroundColor Gray
        } else {
            Write-Host ""
            Write-Host "Current startup programs:" -ForegroundColor Yellow
            Write-Host ""

            $i = 1
            foreach ($item in $startupItems) {
                $bloatTag = if ($item.IsBloat) { " [CAN DISABLE]" } else { "" }
                $color = if ($item.IsBloat) { "Yellow" } else { "White" }
                Write-Host ("  {0}. {1}{2}" -f $i, $item.Name, $bloatTag) -ForegroundColor $color
                $i++
            }

            Write-Host ""
            $selection = Read-Host "Enter numbers to disable (e.g., 1,3,5) or 'A' for all suggested"

            $toDisable = @()
            if ($selection -eq "A") {
                $toDisable = $startupItems | Where-Object { $_.IsBloat }
            } elseif ($selection) {
                $indices = $selection -split "," | ForEach-Object { [int]$_.Trim() - 1 }
                $toDisable = $indices | ForEach-Object { $startupItems[$_] } | Where-Object { $_ }
            }

            foreach ($item in $toDisable) {
                try {
                    Remove-ItemProperty -Path $item.Path -Name $item.Name -ErrorAction Stop
                    Write-Success "Disabled: $($item.Name)"
                } catch {
                    Write-Warn "Could not disable: $($item.Name)"
                }
            }
        }
    }

    "7" {
        # Clear Defender history
        Write-Host ""
        Write-Step "Clearing Windows Defender history..."

        if ($isAdmin) {
            $defenderPath = "$env:ProgramData\Microsoft\Windows Defender\Scans\History"
            if (Test-Path $defenderPath) {
                Get-ChildItem $defenderPath -Recurse -Force -ErrorAction SilentlyContinue |
                    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                Write-Success "Defender history cleared"
            }

            # Also clear detection history
            Remove-MpThreat -ErrorAction SilentlyContinue
            Write-Success "Threat history cleared"
        } else {
            Write-Warn "Requires Administrator privileges"
        }
    }

    "8" {
        # All safe fixes
        Write-Host ""
        Write-Step "Running all safe fixes..."

        # Temp files
        & $PSCommandPath -choice 1

        # DNS
        if ($isAdmin) {
            ipconfig /flushdns | Out-Null
            Write-Success "DNS cache cleared"
        }

        Write-Host ""
        Write-Success "Safe fixes complete!"
    }

    "9" {
        Write-Host "Bye!" -ForegroundColor Gray
    }

    default {
        Write-Host "Invalid option" -ForegroundColor Red
    }
}

Write-Host ""
