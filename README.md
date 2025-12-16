# Tech Support Toolkit

One-click remote tech support setup. Help family and friends without the headache.

## What This Does

1. **Bootstrap** - They run one script, you get RustDesk access
2. **Setup** - You connect via RustDesk and run the full setup
3. **Result** - Tailscale VPN + SSH access for automation (no more RustDesk babysitting)

```
[Their PC] <--Tailscale VPN--> [Your PC]
              (encrypted)

You can now: ssh techsupport@100.x.y.z
```

## Quick Start

### Prerequisites (Your Machine)

1. [Tailscale](https://tailscale.com/download) installed and logged in
2. [RustDesk](https://rustdesk.com) installed
3. A Tailscale auth key from [admin console](https://login.tailscale.com/admin/settings/keys)
   - Check "Reusable" and "Pre-authorized"

### Step 1: Get Initial Access

Send them this message:

> I need to help fix your computer. Do this:
> 1. Press Windows key, type "powershell", right-click "Run as administrator"
> 2. Paste this and press Enter:
> ```
> irm https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/bootstrap.ps1 | iex
> ```
> 3. Send me the ID and password it shows

### Step 2: Connect via RustDesk

1. Open RustDesk on your machine
2. Enter their ID and password
3. Accept when prompted

### Step 3: Run Full Setup

In an **Admin PowerShell** on their machine (through RustDesk):

```powershell
# Download and run setup
irm https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/setup.ps1 -OutFile setup.ps1
.\setup.ps1 -Interactive
```

It will ask for:
- Your Tailscale auth key
- (Optional) Your SSH public key

### Step 4: Done!

Save the password it generates. Now you can SSH directly:

```bash
ssh techsupport@100.x.y.z
```

## All Scripts

### Core Setup Scripts

| Script | Who Runs It | What It Does |
|--------|-------------|--------------|
| `bootstrap.ps1` | Them | Installs RustDesk, shows connection info |
| `setup.ps1` | You (via RustDesk) | Installs Tailscale, SSH, configures everything |
| `verify.ps1` | You | Checks all components are working |

### Diagnostic & Troubleshooting Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `diagnose.ps1` | Full system diagnostic | First thing to run - collects everything |
| `google-audit.ps1` | Audit Google accounts | When they have account confusion |
| `backup.ps1` | Backup important data | Before making any major changes |

### Fix & Cleanup Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `browser-cleanup.ps1` | Clear cache, manage profiles | Browser is slow or confused |
| `fix-common.ps1` | Common Windows fixes | Temp files, DNS, startup items |
| `install-tools.ps1` | Install useful utilities | Get their PC properly set up |

### Remote Work Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `claude-code.ps1` | Install/manage Claude Code CLI | When you want AI assistance |

## Typical Workflow

### 1. Get Access (5 min)
```powershell
# They run this
irm https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/bootstrap.ps1 | iex
# They send you the ID/password, you connect via RustDesk
```

### 2. Set Up Permanent Access (10 min)
```powershell
# You run this via RustDesk
irm https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/setup.ps1 -OutFile setup.ps1
.\setup.ps1 -Interactive
```

### 3. Diagnose (2 min)
```powershell
# Run diagnostic to understand their system
irm https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/diagnose.ps1 | iex
```

### 4. Backup Before Changes (5 min)
```powershell
# Always backup first!
irm https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/backup.ps1 | iex
```

### 5. Fix Issues
```powershell
# For Google account confusion
irm https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/google-audit.ps1 | iex

# For browser issues
irm https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/browser-cleanup.ps1 | iex

# For general Windows issues
irm https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/fix-common.ps1 | iex
```

### 6. Install Claude Code for AI Help
```powershell
# Install Claude Code CLI
irm https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/claude-code.ps1 -OutFile claude-code.ps1
.\claude-code.ps1 -Action Install
.\claude-code.ps1 -Action Login

# IMPORTANT: When done, always logout!
.\claude-code.ps1 -Action Logout
```

## What Gets Installed

### By setup.ps1
- **RustDesk** - Remote desktop (backup access)
- **Tailscale** - Private VPN network
- **OpenSSH Server** - For automation/scripting
- **7-Zip, Notepad++, PowerShell 7, Git** - Common utilities

### By install-tools.ps1 (optional)
- **Essential:** 7-Zip, Notepad++, PowerShell 7, Git
- **Utilities:** Everything (search), TreeSize, HWiNFO, Windows Terminal
- **Security:** Bitwarden, Malwarebytes
- **Remote:** Tailscale, RustDesk
- **Media:** VLC, IrfanView

## Complementary Tools We Leverage

This toolkit doesn't reinvent the wheel. We integrate with existing excellent tools:

### [Chris Titus Tech's WinUtil](https://github.com/ChrisTitusTech/winutil)
The #1 most starred PowerShell project on GitHub. Use it for:
- **Windows debloating** - Remove bloatware, disable telemetry
- **Program installation** - One-click bulk install
- **System tweaks** - Performance optimizations
- **Windows Update fixes** - Reset stuck updates

Launch it from our toolkit:
```powershell
.\fix-common.ps1  # Select option 0
# Or directly:
irm https://christitus.com/win | iex
```

### [Joey305/tailscale-setup-windows](https://github.com/Joey305/tailscale-setup-windows)
We borrowed service resilience patterns from this guide - auto-restart on failure.

### What's Unique to Our Toolkit
- **RustDesk bootstrap** - Get initial access without them knowing tech
- **Google account audit** - Specifically for account confusion
- **Claude Code integration** - AI-assisted troubleshooting
- **End-to-end workflow** - From zero access to full automation

## Security

- SSH is **only** accessible via Tailscale (firewall blocks all other IPs)
- Dedicated `techsupport` user with randomized password
- Optional SSH key authentication (recommended)
- All traffic encrypted via Tailscale

### Firewall Rule

The setup creates a firewall rule that only allows SSH from Tailscale's CGNAT range:

```
Allow TCP 22 from 100.64.0.0/10 only
```

### Claude Code Security

When using Claude Code on someone else's machine:
- **Always run** `.\claude-code.ps1 -Action Logout` when done
- This removes all credentials from the machine
- Never leave your account signed in on shared computers

## Documentation

| Doc | Description |
|-----|-------------|
| [QUICKSTART.md](docs/QUICKSTART.md) | Copy-paste message to send to family |
| [GOOGLE-ACCOUNT-GUIDE.md](docs/GOOGLE-ACCOUNT-GUIDE.md) | Step-by-step guide for Google account confusion |
| [CHEATSHEET.md](docs/CHEATSHEET.md) | Quick reference for common commands |

## Common Issues & Fixes

### Google Account Confusion

Run the Google audit:
```powershell
.\google-audit.ps1
```

This shows:
- All Chrome profiles and signed-in accounts
- Google Drive sync status
- Recommendations for cleanup

See [GOOGLE-ACCOUNT-GUIDE.md](docs/GOOGLE-ACCOUNT-GUIDE.md) for detailed instructions.

### Browser is Slow/Confused

```powershell
.\browser-cleanup.ps1
```

Options:
1. Clear cache only (safe)
2. Clear cache + history
3. View Chrome profiles
4. Remove a profile
5. Nuclear reset

### Computer is Slow

```powershell
.\fix-common.ps1
```

Options:
1. Clear temp files
2. Clear DNS cache
3. Reset network stack
4. Repair Windows files
5. Reset Windows Update
6. Disable startup bloat

### Can't Find Files

Usually a Google Drive sync issue:
```powershell
.\google-audit.ps1
```

Check:
- Which account is signed into Google Drive
- Where files are syncing to
- If there are multiple Drive folders

## File Structure

```
techsupport/
├── scripts/
│   ├── bootstrap.ps1       # They run this first
│   ├── setup.ps1           # Full remote access setup
│   ├── verify.ps1          # Verify setup worked
│   ├── diagnose.ps1        # Comprehensive diagnostic
│   ├── google-audit.ps1    # Google account audit
│   ├── backup.ps1          # Backup user data
│   ├── browser-cleanup.ps1 # Browser cache/profile cleanup
│   ├── install-tools.ps1   # Install useful utilities
│   ├── fix-common.ps1      # Common Windows fixes
│   └── claude-code.ps1     # Claude Code CLI manager
├── config/
│   └── tools.json          # Tools to install (customizable)
├── docs/
│   ├── QUICKSTART.md       # Copy-paste message for family
│   ├── GOOGLE-ACCOUNT-GUIDE.md  # Google account fix guide
│   └── CHEATSHEET.md       # Quick command reference
├── .github/
│   └── workflows/
│       └── ci.yml          # Linting and validation
├── LICENSE
└── README.md
```

## Testing Before You Go

Test the full flow on a Windows VM:

1. Create a Windows 10/11 VM (Hyper-V or VirtualBox)
2. Run `bootstrap.ps1` in the VM
3. Connect via RustDesk from your host
4. Run `setup.ps1` with a test Tailscale auth key
5. Verify you can SSH from host to VM via Tailscale IP

## Using with Claude/AI Agents

Once SSH is set up, you can run commands remotely:

```bash
# Run a command
ssh techsupport@100.x.y.z "powershell -Command Get-Process"

# Run a script
ssh techsupport@100.x.y.z "powershell -File C:\scripts\fix.ps1"

# Interactive session
ssh techsupport@100.x.y.z
```

Or install Claude Code directly on their machine:
```powershell
.\claude-code.ps1 -Action Install
.\claude-code.ps1 -Action Login
# Use Claude Code...
.\claude-code.ps1 -Action Logout  # ALWAYS logout when done!
```

This lets AI agents help fix issues programmatically instead of you clicking around in RustDesk.

## Advanced Usage

### Non-Interactive Setup

```powershell
.\setup.ps1 `
  -TailscaleAuthKey "tskey-auth-xxxxx" `
  -Hostname "aunt-laptop" `
  -SSHUser "support" `
  -SSHPublicKey "ssh-ed25519 AAAA..."
```

### Download All Scripts at Once

```powershell
$dest = "$env:USERPROFILE\Desktop\TechSupport"
New-Item -ItemType Directory -Path $dest -Force
@(
    "bootstrap.ps1", "setup.ps1", "verify.ps1", "diagnose.ps1",
    "google-audit.ps1", "backup.ps1", "browser-cleanup.ps1",
    "install-tools.ps1", "fix-common.ps1", "claude-code.ps1"
) | ForEach-Object {
    $url = "https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/$_"
    Invoke-WebRequest -Uri $url -OutFile "$dest\$_"
}
```

## Troubleshooting

### "Tailscale not connecting"

```powershell
# Check status
& "$env:ProgramFiles\Tailscale\tailscale.exe" status

# Re-authenticate
& "$env:ProgramFiles\Tailscale\tailscale.exe" up --auth-key=tskey-xxx
```

### "SSH connection refused"

```powershell
# Check if sshd is running
Get-Service sshd

# Check if port is open
Test-NetConnection localhost -Port 22

# Check firewall rule
Get-NetFirewallRule -DisplayName "OpenSSH-Tailscale-Only"
```

### "Permission denied"

```powershell
# Check SSH user exists
Get-LocalUser techsupport

# Reset password if needed
$pw = ConvertTo-SecureString "NewPassword123!" -AsPlainText -Force
Set-LocalUser -Name techsupport -Password $pw
```

### "Can't reach Tailscale IP"

Make sure Tailscale is running on **both** machines:

```bash
# Your machine
tailscale status
tailscale ping <their-hostname>
```

## License

MIT
