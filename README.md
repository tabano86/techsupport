# Tech Support Toolkit

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6.svg)](https://www.microsoft.com/windows)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/tabano86/techsupport.svg)](https://github.com/tabano86/techsupport/stargazers)

> **One-click remote tech support for family and friends. No more "can you come over and fix my computer?"**

```
[Their PC] ←──Tailscale VPN──→ [Your PC]
                (encrypted)

Result: ssh techsupport@100.x.y.z
```

## Table of Contents

- [Quick Start](#quick-start)
- [Features](#features)
- [Scripts Overview](#scripts-overview)
- [Typical Workflow](#typical-workflow)
- [Installation](#installation)
- [Usage Examples](#usage-examples)
- [Common Scenarios](#common-scenarios)
- [Security](#security)
- [Complementary Tools](#complementary-tools)
- [Documentation](#documentation)
- [Contributing](#contributing)

## Quick Start

### For the person you're helping (they run this):

```powershell
irm https://raw.githubusercontent.com/tabano86/techsupport/main/scripts/bootstrap.ps1 | iex
```

They send you the RustDesk ID and password. You connect.

### Once connected via RustDesk (you run this):

```powershell
irm https://raw.githubusercontent.com/tabano86/techsupport/main/scripts/setup.ps1 -OutFile setup.ps1
.\setup.ps1 -Interactive
```

### Done! Now you can SSH directly:

```bash
ssh techsupport@100.x.y.z
```

---

## Features

| Feature | Description |
|---------|-------------|
| 🚀 **One-Click Bootstrap** | Non-technical family runs one command |
| 🔐 **Secure Remote Access** | Tailscale VPN + SSH (no port forwarding) |
| 🔍 **System Diagnostics** | Full system analysis in seconds |
| 📧 **Google Account Audit** | Fix account confusion and sync issues |
| 💾 **Smart Backup** | Backup before making changes |
| 🧹 **Browser Cleanup** | Cache, profiles, saved passwords |
| 🛠️ **Windows Fixes** | Temp files, DNS, startup, updates |
| 🤖 **Claude Code Integration** | AI-assisted troubleshooting |

---

## Scripts Overview

### 🚀 Master Launcher (NEW in v1.1)

```powershell
.\Start-TechSupport.ps1
```

Interactive menu to run any script. No need to remember file names.

### Core Scripts

| Script | Purpose | Run By |
|--------|---------|--------|
| `bootstrap.ps1` | Install RustDesk, show ID | Them |
| `setup.ps1` | Full Tailscale + SSH setup | You |
| `verify.ps1` | Check everything works | You |

### Diagnostic Scripts

| Script | Purpose | One-Liner |
|--------|---------|-----------|
| `diagnose.ps1` | Full system diagnostic | `irm .../diagnose.ps1 \| iex` |
| `google-audit.ps1` | Google account audit | `irm .../google-audit.ps1 \| iex` |
| `backup.ps1` | Backup user data | `irm .../backup.ps1 \| iex` |

### Fix Scripts

| Script | Purpose | One-Liner |
|--------|---------|-----------|
| `browser-cleanup.ps1` | Clear cache, manage profiles | `irm .../browser-cleanup.ps1 \| iex` |
| `fix-common.ps1` | Windows fixes + WinUtil | `irm .../fix-common.ps1 \| iex` |
| `install-tools.ps1` | Install utilities | `irm .../install-tools.ps1 \| iex` |
| `winutil.ps1` | Launch WinUtil | `irm christitus.com/win \| iex` |

### Remote Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `claude-code.ps1` | Claude Code CLI | `-Action Install\|Login\|Logout\|Status` |

---

## Typical Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  1. BOOTSTRAP (5 min)                                       │
│     They run: irm .../bootstrap.ps1 | iex                   │
│     They send you: RustDesk ID + Password                   │
├─────────────────────────────────────────────────────────────┤
│  2. SETUP (10 min)                                          │
│     You connect via RustDesk                                │
│     You run: .\setup.ps1 -Interactive                       │
├─────────────────────────────────────────────────────────────┤
│  3. DIAGNOSE (2 min)                                        │
│     .\diagnose.ps1                                          │
├─────────────────────────────────────────────────────────────┤
│  4. BACKUP (5 min)                                          │
│     .\backup.ps1                                            │
├─────────────────────────────────────────────────────────────┤
│  5. FIX                                                     │
│     .\google-audit.ps1   # Account issues                   │
│     .\fix-common.ps1     # Windows issues                   │
│     .\browser-cleanup.ps1 # Browser issues                  │
├─────────────────────────────────────────────────────────────┤
│  6. VERIFY                                                  │
│     .\verify.ps1                                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Installation

### Prerequisites

**Your Machine:**
- [Tailscale](https://tailscale.com/download) installed
- [RustDesk](https://rustdesk.com) installed
- Tailscale auth key from [admin console](https://login.tailscale.com/admin/settings/keys)

**Their Machine:**
- Windows 10 or 11
- Internet connection
- Ability to run PowerShell as Admin

### Download All Scripts

```powershell
# Clone the repo
git clone https://github.com/tabano86/techsupport.git

# Or download scripts directly
$dest = "$env:USERPROFILE\Desktop\TechSupport"
New-Item -ItemType Directory -Path $dest -Force
$scripts = @(
    "Start-TechSupport.ps1",
    "scripts/bootstrap.ps1", "scripts/setup.ps1", "scripts/verify.ps1",
    "scripts/diagnose.ps1", "scripts/google-audit.ps1", "scripts/backup.ps1",
    "scripts/browser-cleanup.ps1", "scripts/fix-common.ps1", "scripts/install-tools.ps1",
    "scripts/claude-code.ps1", "scripts/winutil.ps1"
)
$base = "https://raw.githubusercontent.com/tabano86/techsupport/main"
$scripts | ForEach-Object {
    $url = "$base/$_"
    $file = Join-Path $dest (Split-Path $_ -Leaf)
    Invoke-WebRequest -Uri $url -OutFile $file
}
```

---

## Usage Examples

### Run the Master Launcher

```powershell
.\Start-TechSupport.ps1
```

### Run Specific Scripts

```powershell
# Diagnostic
.\Start-TechSupport.ps1 -Script diagnose

# Quick diagnostic
.\Start-TechSupport.ps1 -Quick

# Google audit
.\scripts\google-audit.ps1

# Install tools (list only)
.\scripts\install-tools.ps1 -List

# Install essential tools
.\scripts\install-tools.ps1 -Essential

# Claude Code
.\scripts\claude-code.ps1 -Action Status
.\scripts\claude-code.ps1 -Action Install
.\scripts\claude-code.ps1 -Action Logout  # ALWAYS when done!
```

### Remote Commands via SSH

```bash
# Run diagnostic remotely
ssh techsupport@100.x.y.z "powershell -File C:\TechSupport\scripts\diagnose.ps1"

# Interactive PowerShell
ssh techsupport@100.x.y.z "powershell"
```

---

## Common Scenarios

### 📧 Google Account Confusion

**Symptoms:** Wrong Gmail, files missing, sync issues

```powershell
.\scripts\google-audit.ps1
```

**What it checks:**
- Multiple Chrome profiles
- Which Google accounts are signed in
- Google Drive sync status
- Old vs new Drive apps

**Guide:** [GOOGLE-ACCOUNT-GUIDE.md](docs/GOOGLE-ACCOUNT-GUIDE.md)

### 🐌 Computer is Slow

```powershell
.\scripts\fix-common.ps1  # Select option 0 for WinUtil
# Or directly:
irm https://christitus.com/win | iex
```

### 🌐 Browser Issues

```powershell
.\scripts\browser-cleanup.ps1
```

Options:
1. Clear cache only (safe)
2. Clear cache + history
3. View Chrome profiles
4. Remove a profile
5. Nuclear reset (backup first!)

### 📡 Remote Access Not Working

```powershell
.\scripts\verify.ps1
```

---

## Security

| Feature | Implementation |
|---------|---------------|
| **Network** | All traffic via Tailscale (WireGuard encryption) |
| **Firewall** | SSH only from 100.64.0.0/10 (Tailscale IPs) |
| **Authentication** | Dedicated user + random password + optional SSH keys |
| **Service Recovery** | Auto-restart on failure |

### Claude Code Security

```powershell
# ALWAYS logout when done on someone else's machine
.\scripts\claude-code.ps1 -Action Logout
```

---

## Complementary Tools

We integrate with these excellent existing tools:

### [Chris Titus Tech's WinUtil](https://github.com/ChrisTitusTech/winutil)

The #1 PowerShell project on GitHub. Use for:
- Windows debloating
- One-click program installation
- System tweaks
- Windows Update fixes

```powershell
.\scripts\fix-common.ps1  # Option 0
# Or: irm https://christitus.com/win | iex
```

### [Joey305/tailscale-setup-windows](https://github.com/Joey305/tailscale-setup-windows)

We use their service recovery patterns.

---

## Documentation

| Document | Description |
|----------|-------------|
| [QUICKSTART.md](docs/QUICKSTART.md) | Copy-paste for family |
| [GOOGLE-ACCOUNT-GUIDE.md](docs/GOOGLE-ACCOUNT-GUIDE.md) | Google confusion fix |
| [CHEATSHEET.md](docs/CHEATSHEET.md) | Quick command reference |
| [CLAUDE.md](CLAUDE.md) | AI agent instructions |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

---

## File Structure

```
techsupport/
├── Start-TechSupport.ps1      # Master launcher (NEW)
├── CLAUDE.md                  # AI agent instructions
├── CHANGELOG.md               # Version history
├── README.md
├── LICENSE
│
├── scripts/
│   ├── bootstrap.ps1          # They run first
│   ├── setup.ps1              # Full remote setup
│   ├── verify.ps1             # Verify setup
│   ├── diagnose.ps1           # System diagnostic
│   ├── google-audit.ps1       # Google account audit
│   ├── backup.ps1             # Backup data
│   ├── browser-cleanup.ps1    # Browser cleanup
│   ├── fix-common.ps1         # Windows fixes
│   ├── install-tools.ps1      # Install utilities
│   ├── claude-code.ps1        # Claude Code manager
│   └── winutil.ps1            # WinUtil launcher
│
├── modules/
│   └── TechSupport.psm1       # Shared functions (NEW)
│
├── config/
│   ├── tools.json             # Tool definitions
│   └── settings.json          # Configuration (NEW)
│
├── docs/
│   ├── QUICKSTART.md
│   ├── GOOGLE-ACCOUNT-GUIDE.md
│   └── CHEATSHEET.md
│
└── .github/
    └── workflows/
        └── ci.yml             # Linting
```

---

## Testing

Test on a Windows VM before going to help someone:

1. Create Windows 10/11 VM
2. Run `bootstrap.ps1`
3. Connect via RustDesk
4. Run `setup.ps1` with test auth key
5. Verify SSH works

---

## Contributing

1. Fork the repo
2. Create a feature branch
3. Run PSScriptAnalyzer on changes
4. Submit PR

```powershell
# Lint your changes
Invoke-ScriptAnalyzer -Path .\scripts -Recurse
```

---

## License

MIT License - See [LICENSE](LICENSE)

---

<p align="center">
  <b>Made with ❤️ for everyone who's ever been the family IT department</b>
</p>
