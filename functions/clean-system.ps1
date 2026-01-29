# ==========================================================
# clean-system.ps1
# PMK Toolbox - Safe System Cleaner (Background + Dashboard)
# Windows 10 / 11
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ==========================================================
# SHARED STATE (DASHBOARD REALTIME)
# ==========================================================
if (-not $Global:CleanState) {
    $Global:CleanState = @{
        Running  = $false
        Step     = ""
        Percent  = 0
        FreedMB  = 0
    }
}

# ==========================================================
# PATHS
# ==========================================================
$Script:RootDir = Resolve-Path "$PSScriptRoot\.."
$Script:LogDir  = Join-Path $Script:RootDir "runtime\logs"
$Script:LogFile = Join-Path $Script:LogDir "clean.log"

if (-not (Test-Path $Script:LogDir)) {
    New-Item -ItemType Directory -Path $Script:LogDir -Force | Out-Null
}

# ==========================================================
# LOGGING
# ==========================================================
function Write-CleanLog {
    param([string]$Message)

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time | CLEAN | $Message" |
        Out-File -FilePath $Script:LogFile -Append -Encoding UTF8
}

# ==========================================================
# DISK SPACE HELPER
# ==========================================================
function Get-FreeSpaceMB {
    try {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        return [Math]::Round($disk.FreeSpace / 1MB, 2)
    } catch {
        return 0
    }
}

# ==========================================================
# SAFE REMOVE
# ==========================================================
function Remove-SafeItem {
    param(
        [string[]]$Path,
        [switch]$Recurse
    )

    foreach ($p in $Path) {
        if (Test-Path $p) {
            try {
                Remove-Item $p -Force -Recurse:$Recurse -ErrorAction Stop
                Write-CleanLog "Removed: $p"
            } catch {
                Write-CleanLog "Failed: $p | $($_.Exception.Message)"
            }
        }
    }
}

# ==========================================================
# CLEAN MODULES (SAFE ONLY)
# ==========================================================
function Clean-Temp {
    Remove-SafeItem -Recurse -Path @(
        "$env:TEMP\*",
        "$env:LOCALAPPDATA\Temp\*",
        "C:\Windows\Temp\*",
        "C:\Windows\Prefetch\*"
    )
}

function Clean-WindowsUpdate {
    Stop-Service wuauserv,bits -Force -ErrorAction SilentlyContinue
    Remove-SafeItem -Recurse -Path "C:\Windows\SoftwareDistribution\Download\*"
    Start-Service bits,wuauserv -ErrorAction SilentlyContinue
}

function Clean-SystemLogs {
    Remove-SafeItem -Recurse -Path @(
        "C:\Windows\Logs\CBS\*",
        "C:\Windows\Logs\DISM\*",
        "C:\Windows\Minidump\*",
        "C:\Windows\LiveKernelReports\*"
    )
}

function Clean-EventLogs {
    try {
        wevtutil el | ForEach-Object {
            try { wevtutil cl $_ } catch {}
        }
    } catch {}
}

function Clean-Recycle {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

function Clean-BrowserCache {
    Remove-SafeItem -Recurse -Path @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\*\Cache\*",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\*\Cache\*",
        "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\*"
    )
}

function Clean-ShaderCache {
    Remove-SafeItem -Recurse -Path @(
        "$env:LOCALAPPDATA\Temp\D3DSCache\*",
        "$env:LOCALAPPDATA\Microsoft\DirectX Shader Cache\*"
    )
}

function Clean-DeliveryOptimization {
    Remove-SafeItem -Recurse -Path `
        "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\*"
}

function Clean-DefenderCache {
    Remove-SafeItem -Recurse -Path `
        "C:\ProgramData\Microsoft\Windows Defender\Scans\History\*"
}

function Clean-WinSxS {
    Start-Process dism.exe `
        -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup /ResetBase" `
        -Wait -NoNewWindow
}

# ==========================================================
# CORE CLEAN ENGINE (BACKGROUND SAFE)
# ==========================================================
function Invoke-CleanSystem {

    if ($Global:CleanState.Running) { return }

    $Global:CleanState.Running = $true
    $Global:CleanState.Percent = 0
    $Global:CleanState.Step    = "Starting"
    $Global:CleanState.FreedMB = 0

    Write-CleanLog "=== CLEAN START ==="
    $beforeMB = Get-FreeSpaceMB

    $steps = @(
        @{ name="Temp"; action={ Clean-Temp } },
        @{ name="Windows Update"; action={ Clean-WindowsUpdate } },
        @{ name="System Logs"; action={ Clean-SystemLogs } },
        @{ name="Event Logs"; action={ Clean-EventLogs } },
        @{ name="Recycle Bin"; action={ Clean-Recycle } },
        @{ name="Browser Cache"; action={ Clean-BrowserCache } },
        @{ name="Shader Cache"; action={ Clean-ShaderCache } },
        @{ name="Delivery Optimization"; action={ Clean-DeliveryOptimization } },
        @{ name="Defender Cache"; action={ Clean-DefenderCache } },
        @{ name="WinSxS"; action={ Clean-WinSxS } }
    )

    $total = $steps.Count
    $i = 0

    foreach ($s in $steps) {
        $i++
        $Global:CleanState.Step = $s.name
        $Global:CleanState.Percent = [Math]::Round(($i / $total) * 100)

        Write-CleanLog "Clean: $($s.name)"
        & $s.action
    }

    $afterMB = Get-FreeSpaceMB
    $freed = [Math]::Round(($afterMB - $beforeMB), 2)

    $Global:CleanState.FreedMB = $freed
    $Global:CleanState.Step   = "Done"
    $Global:CleanState.Percent = 100
    $Global:CleanState.Running = $false

    Write-CleanLog "Freed: $freed MB"
    Write-CleanLog "=== CLEAN END ==="
}

# ==========================================================
# BACKGROUND WRAPPER (MENU / DASHBOARD CALL)
# ==========================================================
function Invoke-CleanMenu {

    if ($Global:CleanState.Running) {
        Write-Host "⚠ Dang don dep..." -ForegroundColor Yellow
        return
    }

    Start-Job -ScriptBlock {
        Import-Module "$PSScriptRoot\clean-system.ps1" -Force
        Invoke-CleanSystem
    } | Out-Null

    Write-Host "🧹 Bat dau don dep (chay nen)..." -ForegroundColor Cyan
}
