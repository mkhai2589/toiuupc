# ==========================================================
# clean-system.ps1
# PMK Toolbox - Absolute Safe Disk Cleanup Engine
# Windows 10 / 11
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

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
# DISK SPACE HELPER (CHUAN NHAT)
# ==========================================================
function Get-FreeSpaceMB {
    try {
        $drive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        return [Math]::Round($drive.FreeSpace / 1MB, 2)
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
    Write-CleanLog "Clean TEMP"
    Remove-SafeItem -Recurse -Path @(
        "$env:TEMP\*",
        "$env:LOCALAPPDATA\Temp\*",
        "C:\Windows\Temp\*",
        "C:\Windows\Prefetch\*"
    )
}

function Clean-WindowsUpdate {
    Write-CleanLog "Clean Windows Update Cache"
    Stop-Service wuauserv,bits -Force -ErrorAction SilentlyContinue
    Remove-SafeItem -Recurse -Path "C:\Windows\SoftwareDistribution\Download\*"
    Start-Service bits,wuauserv -ErrorAction SilentlyContinue
}

function Clean-SystemLogs {
    Write-CleanLog "Clean System Logs"
    Remove-SafeItem -Recurse -Path @(
        "C:\Windows\Logs\CBS\*",
        "C:\Windows\Logs\DISM\*",
        "C:\Windows\Minidump\*",
        "C:\Windows\LiveKernelReports\*"
    )
}

function Clean-EventLogs {
    Write-CleanLog "Clear Event Viewer logs"
    try {
        wevtutil el | ForEach-Object {
            try { wevtutil cl $_ } catch {}
        }
    } catch {}
}

function Clean-Recycle {
    Write-CleanLog "Clean Recycle Bin"
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

function Clean-BrowserCache {
    Write-CleanLog "Clean Browser Cache"
    Remove-SafeItem -Recurse -Path @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\*\Cache\*",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\*\Cache\*",
        "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\*"
    )
}

function Clean-ShaderCache {
    Write-CleanLog "Clean Shader / DirectX Cache"
    Remove-SafeItem -Recurse -Path @(
        "$env:LOCALAPPDATA\Temp\D3DSCache\*",
        "$env:LOCALAPPDATA\Microsoft\DirectX Shader Cache\*"
    )
}

function Clean-DeliveryOptimization {
    Write-CleanLog "Clean Delivery Optimization Cache"
    Remove-SafeItem -Recurse -Path `
        "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\*"
}

function Clean-DefenderCache {
    Write-CleanLog "Clean Windows Defender Cache"
    Remove-SafeItem -Recurse -Path `
        "C:\ProgramData\Microsoft\Windows Defender\Scans\History\*"
}

function Clean-WinSxS {
    Write-CleanLog "DISM StartComponentCleanup"
    Start-Process dism.exe `
        -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup /ResetBase" `
        -Wait -NoNewWindow
}

# ==========================================================
# MAIN ENTRY (WINUTIL STYLE)
# ==========================================================
function Invoke-CleanSystem {

    Write-Host "`n🧹 Dang don dep he thong..." -ForegroundColor Cyan
    Write-CleanLog "=== CLEAN START ==="

    $beforeMB = Get-FreeSpaceMB
    Write-CleanLog "Free space before: $beforeMB MB"

    Clean-Temp
    Clean-WindowsUpdate
    Clean-SystemLogs
    Clean-EventLogs
    Clean-Recycle
    Clean-BrowserCache
    Clean-ShaderCache
    Clean-DeliveryOptimization
    Clean-DefenderCache
    Clean-WinSxS

    $afterMB = Get-FreeSpaceMB
    Write-CleanLog "Free space after: $afterMB MB"

    $freedMB = [Math]::Round(($afterMB - $beforeMB), 2)
    Write-CleanLog "Freed space: $freedMB MB"
    Write-CleanLog "=== CLEAN END ==="

    if ($freedMB -gt 1024) {
        $freedGB = [Math]::Round($freedMB / 1024, 2)
        Write-Host "✅ Da don duoc: $freedGB GB" -ForegroundColor Green
    } else {
        Write-Host "✅ Da don duoc: $freedMB MB" -ForegroundColor Green
    }
}
