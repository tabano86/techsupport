# Claude Code Instructions for Tech Support Toolkit

This file provides instructions for Claude Code (or any AI agent) on how to use this toolkit effectively for remote tech support.

## Overview

This toolkit enables remote tech support for family/friends who aren't tech-savvy. The workflow is:

1. **Bootstrap** - They run one command, you get RustDesk access
2. **Setup** - You configure Tailscale + SSH for permanent access
3. **Diagnose** - Understand what's wrong
4. **Fix** - Apply targeted fixes
5. **Verify** - Confirm everything works

## Critical Safety Rules

### ALWAYS Do These First

1. **Run `diagnose.ps1`** before making any changes - understand the system first
2. **Run `backup.ps1`** before any destructive operations
3. **Get explicit permission** before deleting files or changing settings
4. **Document what you change** so it can be reverted

### NEVER Do These

1. Never delete Chrome profiles without backing up bookmarks first
2. Never uninstall software without asking
3. Never change passwords without writing them down for the user
4. Never leave Claude Code logged in - always run `.\claude-code.ps1 -Action Logout`
5. Never commit auth keys, passwords, or credentials to the repo

## Standard Diagnostic Workflow

When starting a tech support session, follow this sequence:

### Step 1: Initial Assessment

```powershell
# Run full diagnostic - this is always the first step
.\diagnose.ps1

# Review the output for:
# - Disk space issues (>90% used = problem)
# - Multiple Chrome profiles with different accounts
# - Old Backup & Sync vs new Google Drive
# - Startup bloat
# - System issues
```

### Step 2: Targeted Diagnostics

Based on the issue reported:

**For Google/Account Confusion:**
```powershell
.\google-audit.ps1
# Look for:
# - Multiple Google accounts in one Chrome profile
# - Different accounts in different profiles
# - Old Backup & Sync installed alongside Drive for Desktop
# - Multiple Google Drive folders
```

**For Slow Computer:**
```powershell
.\fix-common.ps1
# Check options 1 (temp files) and 6 (startup programs)
# Consider option 0 (WinUtil) for comprehensive optimization
```

**For Browser Issues:**
```powershell
.\browser-cleanup.ps1
# Start with option 1 (cache only) - safest
# Progress to more aggressive options if needed
```

### Step 3: Verify Remote Access

```powershell
.\verify.ps1
# Ensure all checks pass:
# - Tailscale connected with IP
# - SSH running and accessible
# - Firewall properly configured
```

## Script Reference

### Diagnostic Scripts (Safe to Run Anytime)

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `diagnose.ps1` | Full system diagnostic | FIRST - always run this |
| `google-audit.ps1` | Google account audit | Account confusion, Drive sync issues |
| `verify.ps1` | Check remote access setup | After setup, or to troubleshoot access |
| `install-tools.ps1 -List` | Show installed tools | Before installing anything |

### Action Scripts (May Make Changes)

| Script | Purpose | Backup First? |
|--------|---------|---------------|
| `backup.ps1` | Backup user data | N/A - this IS the backup |
| `browser-cleanup.ps1` | Clean browser data | Yes, for options 2+ |
| `fix-common.ps1` | Common Windows fixes | Yes, for options 3+ |
| `install-tools.ps1` | Install utilities | No |
| `setup.ps1` | Full remote access setup | No |

### Management Scripts

| Script | Purpose | Notes |
|--------|---------|-------|
| `claude-code.ps1` | Manage Claude Code CLI | ALWAYS logout when done |
| `winutil.ps1` | Launch Chris Titus WinUtil | Requires admin |
| `bootstrap.ps1` | Initial RustDesk setup | They run this, not you |

## Common Scenarios

### Scenario: Google Account Confusion

**Symptoms:** Files missing, wrong Gmail inbox, sync issues

**Diagnostic:**
```powershell
.\diagnose.ps1    # Get overview
.\google-audit.ps1 # Deep dive on Google
```

**What to Look For:**
1. Multiple accounts in Chrome profiles
2. Sync enabled on wrong account
3. Multiple Google Drive folders
4. Old "Backup and Sync" installed

**Fix Strategy:**
1. Identify which account has their important data
2. Document all accounts found
3. Help them choose ONE primary account
4. Clean up other profiles/accounts
5. Ensure Drive syncs to correct account

**Commands:**
```powershell
# Show Chrome profiles
.\google-audit.ps1

# If they need to see their Google account settings
Start-Process "https://myaccount.google.com"

# If they need to check Drive storage
Start-Process "https://drive.google.com/settings/storage"
```

### Scenario: Computer is Slow

**Diagnostic:**
```powershell
.\diagnose.ps1  # Check disk space, startup items
```

**Fix Strategy:**
1. Clear temp files (safe, immediate impact)
2. Disable startup bloat
3. For comprehensive fix, use WinUtil

**Commands:**
```powershell
# Quick fixes
.\fix-common.ps1  # Option 1 for temp, 6 for startup

# Comprehensive (launches GUI)
.\fix-common.ps1  # Option 0 for WinUtil
# Or directly:
irm https://christitus.com/win | iex
```

### Scenario: Browser Problems

**Symptoms:** Slow, wrong accounts, can't find bookmarks

**Diagnostic:**
```powershell
.\google-audit.ps1  # See all profiles
.\diagnose.ps1      # Check extensions count
```

**Fix Strategy:**
1. Start with cache clear (preserves data)
2. Review profiles - consolidate if needed
3. Nuclear reset only as last resort

**Commands:**
```powershell
.\browser-cleanup.ps1
# Option 1: Cache only (safe)
# Option 2: Cache + history
# Option 3: View profiles
# Option 4: Remove a profile (careful!)
# Option 5: Nuclear reset (backup first!)
```

### Scenario: Setting Up New Machine

**Commands:**
```powershell
# 1. Run full diagnostic
.\diagnose.ps1

# 2. Install essential tools
.\install-tools.ps1 -Essential

# 3. Or install everything
.\install-tools.ps1 -All

# 4. Run WinUtil for Windows optimization
.\fix-common.ps1  # Option 0
```

### Scenario: Remote Access Not Working

**Diagnostic:**
```powershell
.\verify.ps1
```

**Check Each Component:**
```powershell
# Tailscale
& "$env:ProgramFiles\Tailscale\tailscale.exe" status
& "$env:ProgramFiles\Tailscale\tailscale.exe" ip -4

# SSH
Get-Service sshd
Test-NetConnection localhost -Port 22

# Firewall
Get-NetFirewallRule -DisplayName "OpenSSH-Tailscale-Only"

# User
Get-LocalUser techsupport
```

**Fixes:**
```powershell
# Re-run setup if needed
.\setup.ps1 -Interactive

# Or fix individual components
Start-Service sshd
& "$env:ProgramFiles\Tailscale\tailscale.exe" up
```

## Working with Claude Code

### Installing on Remote Machine

```powershell
.\claude-code.ps1 -Action Install  # Installs Node.js + Claude Code
.\claude-code.ps1 -Action Login    # Authenticate
```

### Using Claude Code for Fixes

Once logged in, Claude Code can:
- Read and analyze files
- Run PowerShell commands
- Edit configuration files
- Debug issues interactively

### CRITICAL: Always Logout

```powershell
.\claude-code.ps1 -Action Logout
```

This removes all credentials. Never leave logged in on someone else's machine.

## Command Patterns

### Running Scripts Remotely via SSH

```bash
# From your machine
ssh techsupport@100.x.y.z "powershell -ExecutionPolicy Bypass -File C:\path\to\script.ps1"

# Interactive PowerShell
ssh techsupport@100.x.y.z "powershell"
```

### Downloading Scripts on Remote Machine

```powershell
# Download single script
irm https://raw.githubusercontent.com/tabano86/techsupport/main/scripts/diagnose.ps1 | iex

# Download to file first (for scripts needing parameters)
irm https://raw.githubusercontent.com/tabano86/techsupport/main/scripts/setup.ps1 -OutFile setup.ps1
.\setup.ps1 -Interactive
```

### Checking Script Syntax

```powershell
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile("script.ps1", [ref]$null, [ref]$errors)
$errors  # Should be empty
```

## Escalation Path

If you can't fix something:

1. **Document what you tried** in detail
2. **Save diagnostic output** to a file
3. **Check WinUtil** - it has more advanced fixes
4. **Search the issue** - common problems have known solutions
5. **Ask the user** if they have a tech-savvy friend locally

## Output Locations

Scripts save output to predictable locations:

| Script | Output Location |
|--------|-----------------|
| `diagnose.ps1` | `Desktop\TechSupport_Diagnostic_*.txt` |
| `backup.ps1` | `Desktop\Backup_COMPUTERNAME_*\` or external drive |
| `setup.ps1` | `Desktop\REMOTE_ACCESS_INFO.txt` |

## Environment Assumptions

Scripts assume:
- Windows 10 or 11
- PowerShell 5.1+ (built-in) or PowerShell 7
- Internet connectivity
- Administrator access for most operations
- winget available (Windows 10 1809+ or Windows 11)

## Debugging Tips

### Script Won't Run
```powershell
# Check execution policy
Get-ExecutionPolicy

# Bypass for single script
powershell -ExecutionPolicy Bypass -File script.ps1
```

### Can't Find Chrome Data
```powershell
# Chrome profile locations
"$env:LOCALAPPDATA\Google\Chrome\User Data"

# List profiles
Get-ChildItem "$env:LOCALAPPDATA\Google\Chrome\User Data" -Directory |
    Where-Object { $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$" }
```

### Service Won't Start
```powershell
# Check service status
Get-Service servicename | Format-List *

# Check Windows Event Log
Get-EventLog -LogName System -Source "Service Control Manager" -Newest 20
```

### Network Issues
```powershell
# Quick network test
Test-NetConnection google.com
Test-NetConnection 8.8.8.8 -Port 53

# DNS test
Resolve-DnsName google.com
```

## Version History

- **v1.0** - Initial release with core scripts
- **v1.1** - Added WinUtil integration, Google account guide, service resilience
