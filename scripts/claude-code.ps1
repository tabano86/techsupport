<#
.SYNOPSIS
    Install and manage Claude Code CLI for remote tech support sessions.
.DESCRIPTION
    Actions:
    - Install: Sets up Node.js and Claude Code CLI
    - Login: Authenticate with your Anthropic account
    - Logout: Sign out and clean up credentials (important for shared/family PCs!)
    - Uninstall: Remove Claude Code completely
.PARAMETER Action
    What to do: Install, Login, Logout, Uninstall, Status
.EXAMPLE
    .\claude-code.ps1 -Action Install
    .\claude-code.ps1 -Action Logout  # ALWAYS do this when done!
#>

param(
    [ValidateSet("Install", "Login", "Logout", "Uninstall", "Status")]
    [string]$Action = "Status"
)

$ErrorActionPreference = "Continue"

function Write-Step { param([string]$msg) Write-Host "[*] $msg" -ForegroundColor Yellow }
function Write-Success { param([string]$msg) Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "[!] $msg" -ForegroundColor Red }
function Write-Info { param([string]$msg) Write-Host "[i] $msg" -ForegroundColor Cyan }

# Paths
$claudeConfigDir = "$env:USERPROFILE\.claude"
$claudeCredentials = "$claudeConfigDir\credentials.json"
$claudeSettings = "$claudeConfigDir\settings.json"

function Test-NodeInstalled {
    $node = Get-Command node -ErrorAction SilentlyContinue
    return $null -ne $node
}

function Test-ClaudeInstalled {
    $claude = Get-Command claude -ErrorAction SilentlyContinue
    return $null -ne $claude
}

function Test-ClaudeLoggedIn {
    if (Test-Path $claudeCredentials) {
        $creds = Get-Content $claudeCredentials -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        return $null -ne $creds
    }
    return $false
}

function Show-Status {
    Write-Host ""
    Write-Host "Claude Code Status" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    Write-Host ""

    # Node.js
    $nodeInstalled = Test-NodeInstalled
    if ($nodeInstalled) {
        $nodeVersion = node --version
        Write-Host "  Node.js:     " -NoNewline
        Write-Host "Installed ($nodeVersion)" -ForegroundColor Green
    } else {
        Write-Host "  Node.js:     " -NoNewline
        Write-Host "Not installed" -ForegroundColor Red
    }

    # Claude Code
    $claudeInstalled = Test-ClaudeInstalled
    if ($claudeInstalled) {
        $claudeVersion = claude --version 2>&1 | Select-Object -First 1
        Write-Host "  Claude Code: " -NoNewline
        Write-Host "Installed ($claudeVersion)" -ForegroundColor Green
    } else {
        Write-Host "  Claude Code: " -NoNewline
        Write-Host "Not installed" -ForegroundColor Red
    }

    # Login status
    $loggedIn = Test-ClaudeLoggedIn
    Write-Host "  Logged in:   " -NoNewline
    if ($loggedIn) {
        Write-Host "Yes" -ForegroundColor Green
        Write-Host ""
        Write-Warn "REMINDER: Run 'claude-code.ps1 -Action Logout' when done!"
    } else {
        Write-Host "No" -ForegroundColor Gray
    }

    Write-Host ""
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   CLAUDE CODE MANAGER" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

switch ($Action) {
    "Status" {
        Show-Status
    }

    "Install" {
        Write-Host ""
        Write-Step "Installing Claude Code..."

        # Check/Install Node.js
        if (-not (Test-NodeInstalled)) {
            Write-Step "Installing Node.js via winget..."

            $hasWinget = Get-Command winget -ErrorAction SilentlyContinue
            if ($hasWinget) {
                winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements --silent

                # Refresh PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

                if (Test-NodeInstalled) {
                    Write-Success "Node.js installed"
                } else {
                    Write-Warn "Node.js installation may require a restart"
                    Write-Host "  Please restart PowerShell and run this script again" -ForegroundColor Yellow
                    exit 1
                }
            } else {
                Write-Warn "winget not available. Please install Node.js manually:"
                Write-Host "  https://nodejs.org/en/download/" -ForegroundColor Cyan
                exit 1
            }
        } else {
            Write-Success "Node.js already installed"
        }

        # Install Claude Code CLI
        if (-not (Test-ClaudeInstalled)) {
            Write-Step "Installing Claude Code CLI..."

            npm install -g @anthropic-ai/claude-code 2>&1 | Out-Null

            # Refresh PATH again
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

            if (Test-ClaudeInstalled) {
                Write-Success "Claude Code installed!"
            } else {
                Write-Warn "Claude Code installation failed"
                Write-Host "  Try manually: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
                exit 1
            }
        } else {
            Write-Success "Claude Code already installed"
        }

        Write-Host ""
        Write-Success "Installation complete!"
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Run: claude-code.ps1 -Action Login" -ForegroundColor White
        Write-Host "  2. Or just run: claude" -ForegroundColor White
        Write-Host ""
    }

    "Login" {
        Write-Host ""

        if (-not (Test-ClaudeInstalled)) {
            Write-Warn "Claude Code is not installed. Run: .\claude-code.ps1 -Action Install"
            exit 1
        }

        if (Test-ClaudeLoggedIn) {
            Write-Warn "Already logged in!"
            $confirm = Read-Host "Log out first and re-login? (y/N)"
            if ($confirm -ne "y") { exit 0 }

            # Clear existing credentials
            if (Test-Path $claudeCredentials) {
                Remove-Item $claudeCredentials -Force
            }
        }

        Write-Step "Starting Claude Code authentication..."
        Write-Host ""
        Write-Host "This will open a browser to authenticate with Anthropic." -ForegroundColor Gray
        Write-Host "After logging in, you'll be able to use Claude Code." -ForegroundColor Gray
        Write-Host ""

        # Run claude which will trigger auth flow
        Write-Host "Running 'claude' to start authentication..." -ForegroundColor Yellow
        Write-Host "(Follow the prompts in the terminal)" -ForegroundColor Gray
        Write-Host ""

        # Start claude in current terminal
        & claude

        Write-Host ""
        if (Test-ClaudeLoggedIn) {
            Write-Success "Login successful!"
        }

        Write-Host ""
        Write-Warn "IMPORTANT: Remember to logout when you're done!"
        Write-Host "  Run: .\claude-code.ps1 -Action Logout" -ForegroundColor Yellow
        Write-Host ""
    }

    "Logout" {
        Write-Host ""
        Write-Step "Logging out and cleaning up credentials..."

        $cleaned = $false

        # Remove credentials file
        if (Test-Path $claudeCredentials) {
            Remove-Item $claudeCredentials -Force
            Write-Success "Removed credentials file"
            $cleaned = $true
        }

        # Remove auth tokens from config
        if (Test-Path $claudeSettings) {
            try {
                $settings = Get-Content $claudeSettings -Raw | ConvertFrom-Json
                if ($settings.authToken) {
                    $settings.PSObject.Properties.Remove('authToken')
                    $settings | ConvertTo-Json -Depth 10 | Set-Content $claudeSettings
                    Write-Success "Removed auth token from settings"
                    $cleaned = $true
                }
            } catch {}
        }

        # Clear any API keys from environment
        if ($env:ANTHROPIC_API_KEY) {
            [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $null, "User")
            $env:ANTHROPIC_API_KEY = $null
            Write-Success "Cleared ANTHROPIC_API_KEY environment variable"
            $cleaned = $true
        }

        # Also check for Claude-related items in Windows Credential Manager
        try {
            $claudeCreds = cmdkey /list 2>&1 | Select-String -Pattern "claude|anthropic" -CaseSensitive:$false
            if ($claudeCreds) {
                Write-Info "Found Claude-related credentials in Windows Credential Manager"
                Write-Host "  You may want to remove them manually via Credential Manager" -ForegroundColor Gray
            }
        } catch {}

        if ($cleaned) {
            Write-Host ""
            Write-Success "Logout complete! Credentials have been removed."
        } else {
            Write-Host ""
            Write-Info "No credentials found to remove (already logged out)"
        }

        Write-Host ""
    }

    "Uninstall" {
        Write-Host ""
        Write-Warn "This will completely remove Claude Code from this computer."
        $confirm = Read-Host "Continue? (y/N)"

        if ($confirm -ne "y") {
            Write-Host "Cancelled." -ForegroundColor Gray
            exit 0
        }

        # First logout
        Write-Step "Removing credentials..."
        if (Test-Path $claudeConfigDir) {
            Remove-Item $claudeConfigDir -Recurse -Force
            Write-Success "Removed Claude config directory"
        }

        # Uninstall npm package
        if (Test-ClaudeInstalled) {
            Write-Step "Uninstalling Claude Code npm package..."
            npm uninstall -g @anthropic-ai/claude-code 2>&1 | Out-Null
            Write-Success "Claude Code uninstalled"
        }

        # Clear environment variables
        if ($env:ANTHROPIC_API_KEY) {
            [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $null, "User")
        }

        Write-Host ""
        Write-Success "Claude Code has been completely removed."
        Write-Host ""
        Write-Host "Note: Node.js was NOT uninstalled (other apps may need it)" -ForegroundColor Gray
        Write-Host "To remove Node.js: winget uninstall OpenJS.NodeJS.LTS" -ForegroundColor Gray
        Write-Host ""
    }
}
