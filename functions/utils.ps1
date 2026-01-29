Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# =====================================================
# GLOBAL PATHS
# =====================================================
$Global:ToiUuPC_Root = Join-Path $env:TEMP "ToiUuPC"
$Global:RuntimeDir  = Join-Path $Global:ToiUuPC_Root "runtime"
$Global:LogDir      = Join-Path $Global:RuntimeDir "logs"
$Global:LogFile     = Join-Path $Global:LogDir "toiuupc.log"
$Global:BackupDir   = Join-Path $Global:RuntimeDir "backups"

# =====================================================
# INITIALIZE ENVIRONMENT
# =====================================================
function Initialize-ToiUuPCEnvironment {
    foreach ($dir in @(
        $Global:ToiUuPC_Root,
        $Global:RuntimeDir,
        $Global:LogDir,
        $Global:BackupDir
    )) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    if (-not (Test-Path $Global:LogFile)) {
        New-Item -ItemType File -Path $Global:LogFile -Force | Out-Null
    }
}

# =====================================================
# ADMIN CHECK
# =====================================================
function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p  = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}

function Ensure-Admin {
    if (-not (Test-IsAdmin)) {
        Write-Host "Vui long chay PowerShell bang quyen Administrator" -ForegroundColor Red
        exit 1
    }
}

# =====================================================
# LOGGING
# =====================================================
function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level = "INFO"
    )

    Initialize-ToiUuPCEnvironment

    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$ts [$Level] $Message" |
        Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
}

# =====================================================
# COLOR HELPER
# =====================================================
function Get-UsageColor {
    param([double]$Percent)

    if ($Percent -ge 80) { return "Red" }
    elseif ($Percent -ge 60) { return "Orange" }
    else { return "LimeGreen" }
}

# =====================================================
# PROGRESS BAR
# =====================================================
function Set-Progress {
    param($ProgressBar,[int]$Current,[int]$Total)

    if (-not $ProgressBar -or $Total -le 0) { return }

    $ProgressBar.Value = [Math]::Min(
        100,
        [Math]::Round(($Current / $Total) * 100)
    )

    if ([System.Windows.Forms.Application]::MessageLoop) {
        [System.Windows.Forms.Application]::DoEvents()
    }
}

# =====================================================
# SMOOTH PROGRESS ANIMATION
# =====================================================
function Set-ProgressSmooth {
    param(
        $ProgressBar,
        [double]$TargetValue,
        [int]$DurationMs = 400
    )

    if (-not $ProgressBar) { return }

    try {
        Add-Type -AssemblyName PresentationFramework

        $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
        $anim.From = $ProgressBar.Value
        $anim.To   = [Math]::Min(100, $TargetValue)
        $anim.Duration = [TimeSpan]::FromMilliseconds($DurationMs)
        $anim.EasingFunction = New-Object `
            System.Windows.Media.Animation.CubicEase -Property @{ EasingMode = "EaseOut" }

        $ProgressBar.BeginAnimation(
            [System.Windows.Controls.ProgressBar]::ValueProperty,
            $anim
        )
    } catch {
        $ProgressBar.Value = $TargetValue
    }
}

# =====================================================
# SYSTEM INFO (DASHBOARD)
# =====================================================
function Get-SystemInfo {

    # CPU
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time'
    $cpuLoad = [Math]::Round($cpu.CounterSamples[0].CookedValue,1)

    # RAM
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRam = [Math]::Round($os.TotalVisibleMemorySize / 1MB,1)
    $freeRam  = [Math]::Round($os.FreePhysicalMemory / 1MB,1)
    $usedRam  = $totalRam - $freeRam
    $ramPct   = [Math]::Round(($usedRam / $totalRam) * 100,1)

    # DISK
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
        ForEach-Object {
            $freePct = [Math]::Round(($_.FreeSpace / $_.Size) * 100,1)
            [PSCustomObject]@{
                Drive       = $_.DeviceID
                FreeGB      = [Math]::Round($_.FreeSpace / 1GB,1)
                TotalGB     = [Math]::Round($_.Size / 1GB,1)
                FreePercent = $freePct
                UsedPercent = 100 - $freePct
                Color       = Get-UsageColor (100 - $freePct)
                Warning     = if ($freePct -lt 8) { "CRITICAL" }
                              elseif ($freePct -lt 15) { "LOW SPACE" }
                              else { "" }
            }
        }

    return [PSCustomObject]@{
        CPU  = @{
            LoadPercent = $cpuLoad
            Color       = Get-UsageColor $cpuLoad
        }
        RAM  = @{
            TotalGB     = $totalRam
            UsedGB      = $usedRam
            UsedPercent = $ramPct
            Color       = Get-UsageColor $ramPct
        }
        Disk = $disks
    }
}
