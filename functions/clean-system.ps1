# clean-system.ps1
# Windows 10/11 Clean Engine
# No UI - WinUtil style

Set-StrictMode -Off

$Script:RootDir = Resolve-Path "$PSScriptRoot\.."
$Script:LogDir  = Join-Path $Script:RootDir "runtime\logs"
$Script:LogFile = Join-Path $Script:LogDir "clean.log"

if (-not (Test-Path $Script:LogDir)) {
    New-Item -ItemType Directory -Path $Script:LogDir | Out-Null
}

# =========================
# Logging
# =========================
function Write-CleanLog {
    param([string]$Message)
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$time | CLEAN | $Message" |
        Out-File -FilePath $Script:LogFile -Append -Encoding UTF8
}

# =========================
# Safe Remove Helper
# =========================
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
            }
            catch {
                Write-CleanLog "Failed: $p | $($_.Exception.Message)"
            }
        }
    }
}

# =========================
# Clean Actions
# =========================
function Clean-TempFiles {
    Write-CleanLog "Temp clean start"

    Remove-SafeItem -Recurse -Path @(
        "$env:TEMP\*",
        "$env:LOCALAPPDATA\Temp\*",
        "C:\Windows\Temp\*",
        "C:\Windows\Prefetch\*"
    )
}

function Clean-WindowsUpdateCache {
    Write-CleanLog "WU cache clean start"

    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service bits -Force -ErrorAction SilentlyContinue

    Remove-SafeItem -Recurse -Path "C:\Windows\SoftwareDistribution\Download\*"

    Start-Service bits -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
}

function Clean-SystemLogs {
    Write-CleanLog "System logs clean start"

    Remove-SafeItem -Recurse -Path @(
        "C:\Windows\Logs\CBS\*",
        "C:\Windows\Logs\DISM\*",
        "C:\Windows\Minidump\*",
        "C:\Windows\MEMORY.DMP"
    )
}

function Clean-RecycleBin {
    Write-CleanLog "Recycle bin clean"
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

function Clean-BrowserCache {
    Write-CleanLog "Browser cache clean"

    Remove-SafeItem -Recurse -Path @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
        "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\*"
    )
}

function Clean-WinSxS {
    Write-CleanLog "DISM StartComponentCleanup"

    Start-Process dism.exe `
        -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup" `
        -Wait -NoNewWindow
}

# =========================
# MAIN ENTRY
# =========================
function Invoke-CleanSystem {
    param(
        [switch]$Temp,
        [switch]$Update,
        [switch]$Logs,
        [switch]$RecycleBin,
        [switch]$Browser,
        [switch]$WinSxS,
        [switch]$All
    )

    Write-CleanLog "Invoke-CleanSystem START"

    if ($All -or $Temp)       { Clean-TempFiles }
    if ($All -or $Update)     { Clean-WindowsUpdateCache }
    if ($All -or $Logs)       { Clean-SystemLogs }
    if ($All -or $RecycleBin) { Clean-RecycleBin }
    if ($All -or $Browser)    { Clean-BrowserCache }
    if ($WinSxS)              { Clean-WinSxS }

    Write-CleanLog "Invoke-CleanSystem END"
}
