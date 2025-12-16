<#
.SYNOPSIS
    Verify remote tech support setup is working correctly.
.DESCRIPTION
    Checks:
    - Tailscale is connected and has an IP
    - SSH server is running
    - Port 22 is listening
    - Firewall rules are correct
    - SSH user exists
#>

$ErrorActionPreference = "Continue"

function Write-Check {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Detail = ""
    )

    if ($Passed) {
        Write-Host "[PASS] " -ForegroundColor Green -NoNewline
    } else {
        Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
    }
    Write-Host $Name -NoNewline
    if ($Detail) {
        Write-Host " - $Detail" -ForegroundColor Gray
    } else {
        Write-Host ""
    }
    return $Passed
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   REMOTE TECH SUPPORT - VERIFICATION" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$allPassed = $true

# --- Check 1: Tailscale installed ---
$tsExe = "$env:ProgramFiles\Tailscale\tailscale.exe"
$tsInstalled = Test-Path $tsExe
$allPassed = (Write-Check "Tailscale installed" $tsInstalled $tsExe) -and $allPassed

# --- Check 2: Tailscale running ---
$tsRunning = $false
$tsIP = ""
if ($tsInstalled) {
    try {
        $status = & $tsExe status --json 2>&1 | ConvertFrom-Json
        $tsRunning = $status.BackendState -eq "Running"
        if ($tsRunning) {
            $tsIP = (& $tsExe ip -4 2>&1).Trim()
        }
    } catch {}
}
$allPassed = (Write-Check "Tailscale connected" $tsRunning $(if ($tsIP) { "IP: $tsIP" } else { "" })) -and $allPassed

# --- Check 3: OpenSSH Server installed ---
$sshdCapability = Get-WindowsCapability -Online | Where-Object { $_.Name -like "OpenSSH.Server*" -and $_.State -eq "Installed" }
$sshdInstalled = $null -ne $sshdCapability
$allPassed = (Write-Check "OpenSSH Server installed" $sshdInstalled) -and $allPassed

# --- Check 4: SSHD service running ---
$sshdService = Get-Service -Name sshd -ErrorAction SilentlyContinue
$sshdRunning = $sshdService -and $sshdService.Status -eq "Running"
$allPassed = (Write-Check "SSHD service running" $sshdRunning $(if ($sshdService) { $sshdService.Status } else { "not found" })) -and $allPassed

# --- Check 5: Port 22 listening ---
$port22 = Get-NetTCPConnection -LocalPort 22 -State Listen -ErrorAction SilentlyContinue
$port22Listening = $null -ne $port22
$allPassed = (Write-Check "Port 22 listening" $port22Listening) -and $allPassed

# --- Check 6: Firewall rule exists ---
$fwRule = Get-NetFirewallRule -DisplayName "OpenSSH-Tailscale-Only" -ErrorAction SilentlyContinue
$fwRuleExists = $null -ne $fwRule -and $fwRule.Enabled -eq "True"
$allPassed = (Write-Check "Firewall rule configured" $fwRuleExists "OpenSSH-Tailscale-Only") -and $allPassed

# --- Check 7: Firewall restricts to Tailscale ---
$fwRestricted = $false
if ($fwRule) {
    $filter = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $fwRule
    $fwRestricted = $filter.RemoteAddress -contains "100.64.0.0/10"
}
$allPassed = (Write-Check "Firewall restricts to Tailscale" $fwRestricted "100.64.0.0/10") -and $allPassed

# --- Check 8: SSH user exists ---
$sshUser = Get-LocalUser -Name "techsupport" -ErrorAction SilentlyContinue
$sshUserExists = $null -ne $sshUser
$allPassed = (Write-Check "SSH user 'techsupport' exists" $sshUserExists) -and $allPassed

# --- Check 9: SSH user is admin ---
$sshUserAdmin = $false
if ($sshUserExists) {
    $adminGroup = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
    $sshUserAdmin = $adminGroup.Name -contains "$env:COMPUTERNAME\techsupport"
}
$allPassed = (Write-Check "SSH user is administrator" $sshUserAdmin) -and $allPassed

# --- Check 10: RustDesk installed ---
$rustdeskExe = "$env:ProgramFiles\RustDesk\rustdesk.exe"
$rustdeskInstalled = Test-Path $rustdeskExe
$allPassed = (Write-Check "RustDesk installed (backup)" $rustdeskInstalled $rustdeskExe) -and $allPassed

# --- Summary ---
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan

if ($allPassed) {
    Write-Host "   ALL CHECKS PASSED" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "You can connect with:" -ForegroundColor White
    Write-Host "  ssh techsupport@$tsIP" -ForegroundColor Yellow
} else {
    Write-Host "   SOME CHECKS FAILED" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Run setup.ps1 again to fix issues." -ForegroundColor Yellow
}

Write-Host ""

# --- Detailed System Info ---
Write-Host "SYSTEM INFO:" -ForegroundColor Gray
Write-Host "  Computer:    $env:COMPUTERNAME" -ForegroundColor Gray
Write-Host "  OS:          $((Get-CimInstance Win32_OperatingSystem).Caption)" -ForegroundColor Gray
Write-Host "  Tailscale:   $tsIP" -ForegroundColor Gray
Write-Host ""

return $allPassed
