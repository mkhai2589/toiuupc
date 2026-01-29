# clean-system.ps1
# Windows 10/11 Clean Engine
# Không UI – gọi từ ToiUuPC.ps1

$Script:RootDir = Resolve-Path "$PSScriptRoot\.."
$Script:LogFile = Join-Path $Script:RootDir "logs\apps.log"

# =========================
# Logging
# =========================
function Write-CleanLog {
    param([string]$Message)
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$time | CLEAN | $Message" | Out-File -FilePath $Script:LogFile -Append -Encoding UTF8
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
            } catch {
                Write-CleanLog "Failed: $p | $($_.Exception.Message)"
            }
        }
    }
}

# =========================
# TEMP / CACHE
# =========================
function Clean-TempFiles {
    Write-Host "🧹 TEMP & cache..." -ForegroundColor Cyan
    Write-CleanLog "Temp clean start"

    Remove-SafeItem -Recurse -Path @(
        "$env:TEMP\*",
        "$env:LOCALAPPDATA\Temp\*",
        "C:\Windows\Temp\*",
        "C:\Windows\Prefetch\*"
    )
}

# =========================
# Windows Update Cache
# =========================
function Clean-WindowsUpdateCache {
    Write-Host "🧹 Windows Update cache..." -ForegroundColor Cyan
    Write-CleanLog "WU cache clean start"

    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service bits -Force -ErrorAction SilentlyContinue

    Remove-SafeItem -Recurse -Path "C:\Windows\SoftwareDistribution\Download\*"

    Start-Service bits -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
}

# =========================
# Logs / Dumps
# =========================
function Clean-SystemLogs {
    Write-Host "🧹 System logs & dumps..." -ForegroundColor Cyan
    Write-CleanLog "Logs clean start"

    Remove-SafeItem -Recurse -Path @(
        "C:\Windows\Logs\CBS\*",
        "C:\Windows\Logs\DISM\*",
        "C:\Windows\Minidump\*",
        "C:\Windows\MEMORY.DMP"
    )
}

# =========================
# Recycle Bin
# =========================
function Clean-RecycleBin {
    Write-Host "🧹 Recycle Bin..." -ForegroundColor Cyan
    Write-CleanLog "Recycle bin clean"

    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

# =========================
# Browser Cache
# =========================
function Clean-BrowserCache {
    Write-Host "🧹 Browser cache..." -ForegroundColor Cyan
    Write-CleanLog "Browser cache clean"

    Remove-SafeItem -Recurse -Path @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
        "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\*"
    )
}

# =========================
# DISM (Dangerous)
# =========================
function Clean-WinSxS {
    Write-Host "⚠ WinSxS (Advanced)..." -ForegroundColor Yellow
    Write-CleanLog "DISM StartComponentCleanup"

    Start-Process dism.exe `
        -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup /ResetBase" `
        -Wait -NoNewWindow
}

# =========================
# MAIN
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

    if ($WinSxS) {
        Write-Host "⚠ Không nên chạy WinSxS thường xuyên" -ForegroundColor Yellow
        Clean-WinSxS
    }

    Write-CleanLog "Invoke-CleanSystem END"
    Write-Host "✅ Clean complete!" -ForegroundColor Green
}
