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

Run `verify.ps1` to check everything is working:

```powershell
irm https://raw.githubusercontent.com/YOUR_USERNAME/techsupport/main/scripts/verify.ps1 | iex
```

## Scripts

| Script | Who Runs It | What It Does |
|--------|-------------|--------------|
| `bootstrap.ps1` | Them | Installs RustDesk, shows connection info |
| `setup.ps1` | You (via RustDesk) | Installs Tailscale, SSH, configures everything |
| `verify.ps1` | You | Checks all components are working |

## What Gets Installed

- **RustDesk** - Remote desktop (backup access)
- **Tailscale** - Private VPN network
- **OpenSSH Server** - For automation/scripting
- **7-Zip, Notepad++, PowerShell 7, Git** - Common utilities

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

## Advanced Usage

### Non-Interactive Setup

```powershell
.\setup.ps1 `
  -TailscaleAuthKey "tskey-auth-xxxxx" `
  -Hostname "aunt-laptop" `
  -SSHUser "support" `
  -SSHPublicKey "ssh-ed25519 AAAA..."
```

### Skip Tool Installation

```powershell
.\setup.ps1 -TailscaleAuthKey "tskey-auth-xxxxx" -SkipTools
```

### Dry Run (WhatIf)

```powershell
.\setup.ps1 -TailscaleAuthKey "tskey-auth-xxxxx" -WhatIf
```

### Custom Hostname

```powershell
.\setup.ps1 -TailscaleAuthKey "tskey-auth-xxxxx" -Hostname "mom-desktop"
```

## Testing Before You Go

Test the full flow on a Windows VM:

1. Create a Windows 10/11 VM (Hyper-V or VirtualBox)
2. Run `bootstrap.ps1` in the VM
3. Connect via RustDesk from your host
4. Run `setup.ps1` with a test Tailscale auth key
5. Verify you can SSH from host to VM via Tailscale IP

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

## File Structure

```
techsupport/
├── scripts/
│   ├── bootstrap.ps1    # They run this first
│   ├── setup.ps1        # You run after connecting
│   └── verify.ps1       # Check everything works
├── config/
│   └── tools.json       # Tools to install (customizable)
├── docs/
│   └── QUICKSTART.md    # Copy-paste message for family
├── .github/
│   └── workflows/
│       └── ci.yml       # Linting and validation
├── LICENSE
└── README.md
```

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

This lets AI agents (like Claude Code) help fix issues programmatically instead of you clicking around in RustDesk.

## License

MIT
