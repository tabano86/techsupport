<#
.SYNOPSIS
    Full remote tech support setup. Run this after connecting via RustDesk.
.DESCRIPTION
    Installs and configures:
    - Tailscale VPN (private network)
    - OpenSSH Server (for automation)
    - Common utilities (7-Zip, etc.)
    - Firewall rules (SSH only via Tailscale)
    - Dedicated admin user for remote access
.PARAMETER TailscaleAuthKey
    Your Tailscale auth key. Get one from: https://login.tailscale.com/admin/settings/keys
.PARAMETER Hostname
    Hostname for this machine on Tailscale. Defaults to computer name.
.PARAMETER SSHUser
    Username for SSH access. Defaults to 'techsupport'.
.PARAMETER SSHPublicKey
    Your SSH public key (contents of id_ed25519.pub or id_rsa.pub).
.PARAMETER SkipTools
    Skip installing common utilities.
.PARAMETER WhatIf
    Show what would be done without making changes.
.EXAMPLE
    .\setup.ps1 -TailscaleAuthKey "tskey-auth-xxx"
.EXAMPLE
    .\setup.ps1 -TailscaleAuthKey "tskey-auth-xxx" -SSHPublicKey "ssh-ed25519 AAAA..."
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$TailscaleAuthKey,

    [Parameter(Mandatory = $false)]
    [string]$Hostname = $env:COMPUTERNAME,

    [Parameter(Mandatory = $false)]
    [string]$SSHUser = "techsupport",

    [Parameter(Mandatory = $false)]
    [string]$SSHPublicKey,

    [switch]$SkipTools,
    [switch]$Interactive
)

#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# --- Helper Functions ---
function Write-Banner {
    param([string]$msg)
    Write-Host ""
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host "  $msg" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step { param([string]$msg) Write-Host "[*] $msg" -ForegroundColor Yellow }
function Write-Success { param([string]$msg) Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Info { param([string]$msg) Write-Host "[i] $msg" -ForegroundColor Cyan }
function Write-Warn { param([string]$msg) Write-Host "[!] $msg" -ForegroundColor Magenta }

function New-RandomPassword {
    param([int]$Length = 24)
    $chars = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%^&*"
    -join (1..$Length | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

function Test-Command {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# --- Interactive Mode ---
if ($Interactive -or (-not $TailscaleAuthKey)) {
    Write-Banner "REMOTE TECH SUPPORT - FULL SETUP"

    if (-not $TailscaleAuthKey) {
        Write-Host "You need a Tailscale auth key." -ForegroundColor Yellow
        Write-Host "Get one from: https://login.tailscale.com/admin/settings/keys" -ForegroundColor Cyan
        Write-Host "(Create a reusable key, check 'Pre-authorized')" -ForegroundColor Gray
        Write-Host ""
        $secKey = Read-Host "Paste Tailscale auth key (hidden)" -AsSecureString
        $TailscaleAuthKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secKey)
        )
    }

    if (-not $SSHPublicKey) {
        Write-Host ""
        Write-Host "SSH public key (optional but recommended):" -ForegroundColor Yellow
        Write-Host "On your machine, run: cat ~/.ssh/id_ed25519.pub" -ForegroundColor Gray
        $SSHPublicKey = Read-Host "Paste your public key (or press Enter to skip)"
    }
}

if (-not $TailscaleAuthKey) {
    throw "TailscaleAuthKey is required. Run with -Interactive or provide -TailscaleAuthKey"
}

# --- Summary ---
$summary = [ordered]@{
    "Hostname"       = $Hostname
    "SSH User"       = $SSHUser
    "SSH Key Auth"   = if ($SSHPublicKey) { "Yes" } else { "No (password only)" }
    "Install Tools"  = if ($SkipTools) { "No" } else { "Yes" }
}

Write-Banner "SETUP CONFIGURATION"
$summary.GetEnumerator() | ForEach-Object {
    Write-Host ("  {0,-15} : {1}" -f $_.Key, $_.Value)
}
Write-Host ""

if ($WhatIfPreference) {
    Write-Warn "WhatIf mode - no changes will be made"
    Write-Host ""
}

# ============================================================
# SECTION 1: TAILSCALE
# ============================================================
Write-Banner "INSTALLING TAILSCALE"

$tsExe = "$env:ProgramFiles\Tailscale\tailscale.exe"
$tsInstalled = Test-Path $tsExe

if (-not $tsInstalled) {
    Write-Step "Downloading Tailscale installer..."

    if ($PSCmdlet.ShouldProcess("Tailscale", "Download and install")) {
        # Fetch stable packages page to find latest MSI
        $stableUrl = "https://pkgs.tailscale.com/stable/"
        $html = (Invoke-WebRequest -Uri $stableUrl -UseBasicParsing).Content

        # Find amd64 MSI
        $arch = "amd64"
        if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { $arch = "arm64" }

        $msiPattern = "tailscale-setup-[\d\.]+-$arch\.msi"
        if ($html -match $msiPattern) {
            $msiName = $matches[0]
        } else {
            throw "Could not find Tailscale MSI for architecture: $arch"
        }

        $msiUrl = "$stableUrl$msiName"
        $msiPath = Join-Path $env:TEMP $msiName

        Write-Step "Downloading $msiName..."
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath

        Write-Step "Installing Tailscale..."
        Start-Process msiexec.exe -Wait -ArgumentList "/i `"$msiPath`" /qn /norestart"

        if (-not (Test-Path $tsExe)) {
            throw "Tailscale installation failed"
        }
        Write-Success "Tailscale installed"
    }
} else {
    Write-Success "Tailscale already installed"
}

# Connect to Tailscale
Write-Step "Connecting to Tailscale network..."

if ($PSCmdlet.ShouldProcess("Tailscale", "Connect with auth key")) {
    $tsArgs = @(
        "up",
        "--auth-key=$TailscaleAuthKey",
        "--unattended=true",
        "--hostname=$Hostname"
    )

    & $tsExe @tsArgs 2>&1 | Out-Null

    # Wait for connection
    $timeout = 30
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        $status = & $tsExe status --json 2>&1 | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($status.BackendState -eq "Running") {
            break
        }
        Start-Sleep -Seconds 2
        $elapsed += 2
    }

    $tsIP = & $tsExe ip -4 2>&1
    if ($tsIP -match "^100\.") {
        Write-Success "Tailscale connected!"
        Write-Info "Tailscale IP: $tsIP"
    } else {
        Write-Warn "Tailscale may not be fully connected. Check status manually."
    }
}

# ============================================================
# SECTION 2: OPENSSH SERVER
# ============================================================
Write-Banner "INSTALLING OPENSSH SERVER"

$sshdInstalled = Get-WindowsCapability -Online | Where-Object { $_.Name -like "OpenSSH.Server*" -and $_.State -eq "Installed" }

if (-not $sshdInstalled) {
    Write-Step "Installing OpenSSH Server..."

    if ($PSCmdlet.ShouldProcess("OpenSSH.Server", "Install Windows capability")) {
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
        Write-Success "OpenSSH Server installed"
    }
} else {
    Write-Success "OpenSSH Server already installed"
}

# Configure and start sshd service
Write-Step "Configuring SSH service..."

if ($PSCmdlet.ShouldProcess("sshd", "Configure and start service")) {
    Set-Service -Name sshd -StartupType Automatic
    Start-Service sshd -ErrorAction SilentlyContinue

    # Ensure ssh-agent is running
    Set-Service -Name ssh-agent -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service ssh-agent -ErrorAction SilentlyContinue

    # Configure service recovery - auto-restart on failure
    # Pattern from Joey305/tailscale-setup-windows
    sc.exe failure sshd reset= 86400 actions= restart/60000/restart/60000/restart/60000 | Out-Null
    sc.exe failure Tailscale reset= 86400 actions= restart/60000/restart/60000/restart/60000 | Out-Null

    Write-Success "SSH service configured and started"
    Write-Info "Services configured to auto-restart on failure"
}

# ============================================================
# SECTION 3: FIREWALL RULES
# ============================================================
Write-Banner "CONFIGURING FIREWALL"

$ruleName = "OpenSSH-Tailscale-Only"

Write-Step "Setting up firewall rules (SSH only via Tailscale)..."

if ($PSCmdlet.ShouldProcess($ruleName, "Configure firewall rule")) {
    # Remove default OpenSSH rule if it exists (too permissive)
    Get-NetFirewallRule -DisplayName "OpenSSH SSH Server (sshd)" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue

    # Remove our old rule if exists
    Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue

    # Create new restrictive rule - only allow from Tailscale CGNAT range
    New-NetFirewallRule `
        -DisplayName $ruleName `
        -Description "Allow SSH only from Tailscale network" `
        -Direction Inbound `
        -Action Allow `
        -Protocol TCP `
        -LocalPort 22 `
        -RemoteAddress "100.64.0.0/10" `
        -Enabled True | Out-Null

    Write-Success "Firewall configured - SSH only accessible via Tailscale"
}

# ============================================================
# SECTION 4: SSH USER
# ============================================================
Write-Banner "CREATING SSH USER"

$userExists = Get-LocalUser -Name $SSHUser -ErrorAction SilentlyContinue
$password = $null

if (-not $userExists) {
    Write-Step "Creating user '$SSHUser'..."

    if ($PSCmdlet.ShouldProcess($SSHUser, "Create local admin user")) {
        $password = New-RandomPassword
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force

        New-LocalUser `
            -Name $SSHUser `
            -Password $securePassword `
            -PasswordNeverExpires `
            -UserMayNotChangePassword `
            -Description "Remote tech support access" | Out-Null

        Add-LocalGroupMember -Group "Administrators" -Member $SSHUser -ErrorAction SilentlyContinue

        Write-Success "User '$SSHUser' created"
    }
} else {
    Write-Success "User '$SSHUser' already exists"
}

# ============================================================
# SECTION 5: SSH CONFIGURATION
# ============================================================
Write-Banner "CONFIGURING SSH"

$sshdConfigPath = "$env:ProgramData\ssh\sshd_config"

Write-Step "Configuring SSH daemon..."

if ($PSCmdlet.ShouldProcess($sshdConfigPath, "Update SSH configuration")) {
    if (Test-Path $sshdConfigPath) {
        $config = Get-Content $sshdConfigPath -Raw

        # Ensure only our user can login
        if ($config -notmatch "(?m)^AllowUsers\s+") {
            Add-Content -Path $sshdConfigPath -Value "`r`nAllowUsers $SSHUser"
        } else {
            $config = $config -replace "(?m)^AllowUsers\s+.*$", "AllowUsers $SSHUser"
            Set-Content -Path $sshdConfigPath -Value $config -Encoding ASCII
        }

        Write-Success "SSH restricted to user '$SSHUser'"
    }
}

# Configure SSH key authentication
if ($SSHPublicKey) {
    Write-Step "Setting up SSH key authentication..."

    if ($PSCmdlet.ShouldProcess("administrators_authorized_keys", "Configure SSH key")) {
        $authKeysPath = "$env:ProgramData\ssh\administrators_authorized_keys"

        # Create or overwrite the file
        Set-Content -Path $authKeysPath -Value $SSHPublicKey -Encoding ASCII

        # Fix permissions (critical for Windows OpenSSH)
        icacls.exe $authKeysPath /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F" | Out-Null

        Write-Success "SSH public key configured"
    }
}

# Restart SSH to apply changes
if ($PSCmdlet.ShouldProcess("sshd", "Restart service")) {
    Restart-Service sshd
}

# ============================================================
# SECTION 6: COMMON TOOLS
# ============================================================
if (-not $SkipTools) {
    Write-Banner "INSTALLING COMMON TOOLS"

    # Check for winget
    $hasWinget = Test-Command "winget"

    if ($hasWinget) {
        $tools = @(
            @{ id = "7zip.7zip"; name = "7-Zip" },
            @{ id = "Notepad++.Notepad++"; name = "Notepad++" },
            @{ id = "Microsoft.PowerShell"; name = "PowerShell 7" },
            @{ id = "Git.Git"; name = "Git" }
        )

        foreach ($tool in $tools) {
            Write-Step "Installing $($tool.name)..."

            if ($PSCmdlet.ShouldProcess($tool.name, "Install via winget")) {
                $result = winget install --id $tool.id --accept-source-agreements --accept-package-agreements --silent 2>&1
                if ($LASTEXITCODE -eq 0 -or $result -match "already installed") {
                    Write-Success "$($tool.name) installed"
                } else {
                    Write-Warn "Could not install $($tool.name)"
                }
            }
        }
    } else {
        Write-Warn "winget not available - skipping tool installation"
        Write-Info "You can install tools manually later"
    }
}

# ============================================================
# SECTION 7: VERIFY AND SUMMARY
# ============================================================
Write-Banner "SETUP COMPLETE"

# Get Tailscale IP
$tsIP = & $tsExe ip -4 2>&1
if ($tsIP -notmatch "^100\.") {
    $tsIP = "(check 'tailscale ip')"
}

Write-Host "CONNECTION INFO" -ForegroundColor Green
Write-Host "===============" -ForegroundColor Green
Write-Host ""
Write-Host "  Tailscale IP:  $tsIP" -ForegroundColor Cyan
Write-Host "  SSH User:      $SSHUser" -ForegroundColor Cyan
if ($password) {
    Write-Host "  SSH Password:  $password" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  SAVE THIS PASSWORD! It won't be shown again." -ForegroundColor Red
}
Write-Host ""
Write-Host "TO CONNECT FROM YOUR MACHINE:" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ""
if ($SSHPublicKey) {
    Write-Host "  ssh $SSHUser@$tsIP" -ForegroundColor White
} else {
    Write-Host "  ssh $SSHUser@$tsIP" -ForegroundColor White
    Write-Host "  (enter password when prompted)" -ForegroundColor Gray
}
Write-Host ""

# Save connection info to file
$infoPath = Join-Path $env:USERPROFILE "Desktop\REMOTE_ACCESS_INFO.txt"
if ($PSCmdlet.ShouldProcess($infoPath, "Save connection info")) {
    @"
REMOTE TECH SUPPORT - CONNECTION INFO
=====================================
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer: $env:COMPUTERNAME

Tailscale IP: $tsIP
SSH User: $SSHUser
$(if ($password) { "SSH Password: $password" } else { "SSH Auth: Key-based" })

TO CONNECT:
ssh $SSHUser@$tsIP

TROUBLESHOOTING:
- Ensure Tailscale is running on both machines
- Check: tailscale status
- Test port: Test-NetConnection $tsIP -Port 22
"@ | Set-Content -Path $infoPath -Encoding UTF8

    Write-Info "Connection info saved to Desktop\REMOTE_ACCESS_INFO.txt"
}

Write-Host ""
Write-Host "Run 'verify.ps1' to check everything is working." -ForegroundColor Gray
