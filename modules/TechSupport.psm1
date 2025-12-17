#Requires -Version 5.1
<#
.SYNOPSIS
    Shared functions module for Tech Support Toolkit
.DESCRIPTION
    Common utilities used across all tech support scripts:
    - Logging
    - Output formatting
    - System checks
    - Progress indicators
    - Error handling
.NOTES
    Version: 1.1.0
    Author: Tech Support Toolkit
#>

# ============================================================
# CONFIGURATION
# ============================================================

$script:Config = @{
    LogDir = "$env:USERPROFILE\Desktop\TechSupport_Logs"
    LogFile = $null
    Verbose = $false
    Silent = $false
    NoColor = $false
    StartTime = $null
}

# ============================================================
# LOGGING FUNCTIONS
# ============================================================

function Initialize-TSLog {
    <#
    .SYNOPSIS
        Initialize logging for a tech support session
    #>
    param(
        [string]$ScriptName = "TechSupport",
        [string]$LogDir = $script:Config.LogDir
    )

    $script:Config.StartTime = Get-Date

    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $script:Config.LogFile = Join-Path $LogDir "${ScriptName}_${timestamp}.log"

    # Write header
    $header = @"
================================================================================
Tech Support Toolkit - $ScriptName
Started: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer: $env:COMPUTERNAME
User: $env:USERNAME
OS: $((Get-CimInstance Win32_OperatingSystem).Caption)
================================================================================

"@
    $header | Out-File -FilePath $script:Config.LogFile -Encoding UTF8

    return $script:Config.LogFile
}

function Write-TSLog {
    <#
    .SYNOPSIS
        Write to log file and optionally to console
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO",

        [switch]$NoConsole
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"

    # Write to log file
    if ($script:Config.LogFile) {
        $logLine | Out-File -FilePath $script:Config.LogFile -Append -Encoding UTF8
    }

    # Write to console unless silent
    if (-not $NoConsole -and -not $script:Config.Silent) {
        $color = switch ($Level) {
            "INFO"    { "White" }
            "WARN"    { "Yellow" }
            "ERROR"   { "Red" }
            "SUCCESS" { "Green" }
            "DEBUG"   { "Gray" }
            default   { "White" }
        }

        if ($script:Config.NoColor) {
            Write-Host $logLine
        } else {
            Write-Host $logLine -ForegroundColor $color
        }
    }
}

function Close-TSLog {
    <#
    .SYNOPSIS
        Finalize logging with summary
    #>
    $duration = (Get-Date) - $script:Config.StartTime
    $footer = @"

================================================================================
Completed: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Duration: $($duration.ToString("hh\:mm\:ss"))
Log saved to: $($script:Config.LogFile)
================================================================================
"@
    if ($script:Config.LogFile) {
        $footer | Out-File -FilePath $script:Config.LogFile -Append -Encoding UTF8
    }

    return $script:Config.LogFile
}

# ============================================================
# OUTPUT FORMATTING
# ============================================================

function Write-TSBanner {
    <#
    .SYNOPSIS
        Write a formatted banner/header
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [string]$Subtitle,

        [ValidateSet("Cyan", "Green", "Yellow", "Red", "Magenta")]
        [string]$Color = "Cyan"
    )

    $width = 50
    $line = "=" * $width

    Write-Host ""
    Write-Host $line -ForegroundColor $Color
    Write-Host ("  " + $Title) -ForegroundColor $Color
    if ($Subtitle) {
        Write-Host ("  " + $Subtitle) -ForegroundColor Gray
    }
    Write-Host $line -ForegroundColor $Color
    Write-Host ""

    Write-TSLog -Message "=== $Title ===" -Level INFO -NoConsole
}

function Write-TSSection {
    <#
    .SYNOPSIS
        Write a section header
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    Write-Host ""
    Write-Host ("--- " + $Title + " ---") -ForegroundColor Yellow
    Write-TSLog -Message "--- $Title ---" -Level INFO -NoConsole
}

function Write-TSStep {
    <#
    .SYNOPSIS
        Write a step indicator
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [int]$Step,
        [int]$Total
    )

    $prefix = if ($Step -and $Total) { "[$Step/$Total]" } else { "[*]" }
    Write-Host "$prefix $Message" -ForegroundColor Yellow
    Write-TSLog -Message "$prefix $Message" -Level INFO -NoConsole
}

function Write-TSSuccess {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
    Write-TSLog -Message $Message -Level SUCCESS -NoConsole
}

function Write-TSError {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Red
    Write-TSLog -Message $Message -Level ERROR -NoConsole
}

function Write-TSWarning {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
    Write-TSLog -Message $Message -Level WARN -NoConsole
}

function Write-TSInfo {
    param([string]$Message)
    Write-Host "[i] $Message" -ForegroundColor Cyan
    Write-TSLog -Message $Message -Level INFO -NoConsole
}

function Write-TSDebug {
    param([string]$Message)
    if ($script:Config.Verbose) {
        Write-Host "[DEBUG] $Message" -ForegroundColor Gray
    }
    Write-TSLog -Message $Message -Level DEBUG -NoConsole
}

# ============================================================
# PROGRESS INDICATORS
# ============================================================

function Show-TSProgress {
    <#
    .SYNOPSIS
        Show a progress bar
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Activity,

        [Parameter(Mandatory)]
        [int]$PercentComplete,

        [string]$Status,
        [int]$SecondsRemaining
    )

    $params = @{
        Activity = $Activity
        PercentComplete = [Math]::Min(100, [Math]::Max(0, $PercentComplete))
    }

    if ($Status) { $params.Status = $Status }
    if ($SecondsRemaining) { $params.SecondsRemaining = $SecondsRemaining }

    Write-Progress @params
}

function Show-TSSpinner {
    <#
    .SYNOPSIS
        Show a simple spinner animation
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [scriptblock]$ScriptBlock
    )

    $spinner = @('|', '/', '-', '\')
    $i = 0

    $job = Start-Job -ScriptBlock $ScriptBlock

    while ($job.State -eq 'Running') {
        Write-Host "`r$($spinner[$i % 4]) $Message" -NoNewline -ForegroundColor Yellow
        Start-Sleep -Milliseconds 100
        $i++
    }

    Write-Host "`r[+] $Message" -ForegroundColor Green
    Receive-Job $job
    Remove-Job $job
}

# ============================================================
# SYSTEM CHECKS
# ============================================================

function Test-TSAdmin {
    <#
    .SYNOPSIS
        Check if running as administrator
    #>
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-TSAdmin {
    <#
    .SYNOPSIS
        Require administrator privileges or exit
    #>
    param(
        [string]$Message = "This script requires Administrator privileges."
    )

    if (-not (Test-TSAdmin)) {
        Write-TSError $Message
        Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
        exit 1
    }
}

function Test-TSCommand {
    <#
    .SYNOPSIS
        Check if a command exists
    #>
    param([string]$Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Test-TSPath {
    <#
    .SYNOPSIS
        Check if a path exists with detailed info
    #>
    param([string]$Path)

    $result = @{
        Exists = Test-Path $Path
        Path = $Path
        Type = $null
        Size = $null
    }

    if ($result.Exists) {
        $item = Get-Item $Path
        $result.Type = if ($item.PSIsContainer) { "Directory" } else { "File" }
        if (-not $item.PSIsContainer) {
            $result.Size = $item.Length
        }
    }

    return $result
}

function Get-TSSystemInfo {
    <#
    .SYNOPSIS
        Get basic system information
    #>
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem

    return @{
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        OSName = $os.Caption
        OSVersion = $os.Version
        OSBuild = $os.BuildNumber
        Architecture = $env:PROCESSOR_ARCHITECTURE
        TotalRAM_GB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
        Manufacturer = $cs.Manufacturer
        Model = $cs.Model
        IsAdmin = Test-TSAdmin
        PSVersion = $PSVersionTable.PSVersion.ToString()
    }
}

function Get-TSDiskSpace {
    <#
    .SYNOPSIS
        Get disk space information
    #>
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        @{
            Drive = $_.DeviceID
            Label = $_.VolumeName
            TotalGB = [math]::Round($_.Size / 1GB, 1)
            FreeGB = [math]::Round($_.FreeSpace / 1GB, 1)
            UsedGB = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 1)
            PercentUsed = [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 0)
            IsLow = (($_.Size - $_.FreeSpace) / $_.Size) -gt 0.9
        }
    }
}

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

function Get-TSFolderSize {
    <#
    .SYNOPSIS
        Get folder size in MB
    #>
    param([string]$Path)

    if (-not (Test-Path $Path)) { return 0 }

    $size = (Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue |
             Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum

    return [math]::Round($size / 1MB, 1)
}

function New-TSRandomPassword {
    <#
    .SYNOPSIS
        Generate a random password
    #>
    param([int]$Length = 24)

    $chars = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%^&*"
    -join (1..$Length | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

function Invoke-TSWithRetry {
    <#
    .SYNOPSIS
        Execute a script block with retry logic
    #>
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 2,
        [string]$OperationName = "Operation"
    )

    $attempt = 0
    $success = $false

    while (-not $success -and $attempt -lt $MaxRetries) {
        $attempt++
        try {
            $result = & $ScriptBlock
            $success = $true
            return $result
        }
        catch {
            Write-TSWarning "$OperationName failed (attempt $attempt/$MaxRetries): $_"
            if ($attempt -lt $MaxRetries) {
                Start-Sleep -Seconds $DelaySeconds
            }
        }
    }

    if (-not $success) {
        throw "$OperationName failed after $MaxRetries attempts"
    }
}

function Confirm-TSAction {
    <#
    .SYNOPSIS
        Prompt for confirmation
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Default = "N"
    )

    $prompt = if ($Default -eq "Y") { "(Y/n)" } else { "(y/N)" }
    $response = Read-Host "$Message $prompt"

    if ([string]::IsNullOrWhiteSpace($response)) {
        $response = $Default
    }

    return $response -match "^[Yy]"
}

function Save-TSReport {
    <#
    .SYNOPSIS
        Save a report to the desktop
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Content,

        [string]$Extension = "txt"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $filename = "${Name}_${timestamp}.${Extension}"
    $path = Join-Path "$env:USERPROFILE\Desktop" $filename

    $Content | Out-File -FilePath $path -Encoding UTF8

    Write-TSInfo "Report saved to: $path"
    return $path
}

# ============================================================
# CHROME/BROWSER UTILITIES
# ============================================================

function Get-TSChromeProfiles {
    <#
    .SYNOPSIS
        Get all Chrome profiles with account information
    #>
    $chromeUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data"

    if (-not (Test-Path $chromeUserData)) {
        return @()
    }

    $profiles = @()

    Get-ChildItem $chromeUserData -Directory |
        Where-Object { $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$" } |
        ForEach-Object {
            $profileDir = $_
            $prefsFile = Join-Path $profileDir.FullName "Preferences"

            $profile = @{
                FolderName = $profileDir.Name
                Path = $profileDir.FullName
                DisplayName = $profileDir.Name
                Emails = @()
                SyncEnabled = $false
                LastUsed = $profileDir.LastWriteTime
            }

            if (Test-Path $prefsFile) {
                try {
                    $prefs = Get-Content $prefsFile -Raw | ConvertFrom-Json

                    if ($prefs.profile.name) {
                        $profile.DisplayName = $prefs.profile.name
                    }

                    if ($prefs.account_info) {
                        $profile.Emails = @($prefs.account_info |
                            ForEach-Object { $_.email } |
                            Where-Object { $_ })
                    }

                    if ($prefs.google.services.sync_enabled) {
                        $profile.SyncEnabled = $true
                    }
                } catch { }
            }

            $profiles += $profile
        }

    return $profiles
}

# ============================================================
# SERVICE UTILITIES
# ============================================================

function Test-TSService {
    <#
    .SYNOPSIS
        Check if a service exists and is running
    #>
    param([string]$Name)

    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue

    return @{
        Exists = $null -ne $service
        Running = $service -and $service.Status -eq 'Running'
        Status = if ($service) { $service.Status.ToString() } else { "NotFound" }
        StartType = if ($service) { $service.StartType.ToString() } else { "N/A" }
    }
}

function Set-TSServiceRecovery {
    <#
    .SYNOPSIS
        Configure service to auto-restart on failure
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,

        [int]$RestartDelayMs = 60000
    )

    $actions = "restart/$RestartDelayMs/restart/$RestartDelayMs/restart/$RestartDelayMs"
    sc.exe failure $ServiceName reset= 86400 actions= $actions | Out-Null

    Write-TSDebug "Configured $ServiceName to auto-restart on failure"
}

# ============================================================
# EXPORTS
# ============================================================

Export-ModuleMember -Function @(
    # Logging
    'Initialize-TSLog'
    'Write-TSLog'
    'Close-TSLog'

    # Output
    'Write-TSBanner'
    'Write-TSSection'
    'Write-TSStep'
    'Write-TSSuccess'
    'Write-TSError'
    'Write-TSWarning'
    'Write-TSInfo'
    'Write-TSDebug'

    # Progress
    'Show-TSProgress'
    'Show-TSSpinner'

    # System checks
    'Test-TSAdmin'
    'Assert-TSAdmin'
    'Test-TSCommand'
    'Test-TSPath'
    'Get-TSSystemInfo'
    'Get-TSDiskSpace'

    # Utilities
    'Get-TSFolderSize'
    'New-TSRandomPassword'
    'Invoke-TSWithRetry'
    'Confirm-TSAction'
    'Save-TSReport'

    # Browser
    'Get-TSChromeProfiles'

    # Services
    'Test-TSService'
    'Set-TSServiceRecovery'
)
