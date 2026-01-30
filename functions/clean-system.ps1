# ============================================================
# PMK TOOLBOX - CLEAN SYSTEM
# Author : Minh Khai
# Compatible: Windows 10 / Windows 11
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ------------------------------------------------------------
function Clear-TempFolders {

    Write-Host "[CLEAN] Temporary files" -ForegroundColor Cyan

    $paths = @(
        "$env:TEMP\*",
        "$env:LOCALAPPDATA\Temp\*",
        "$env:WINDIR\Temp\*"
    )

    foreach ($p in $paths) {
        try {
            Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
        } catch {}
    }
}

# ------------------------------------------------------------
function Clear-WindowsUpdateCache {

    Write-Host "[CLEAN] Windows Update cache" -ForegroundColor Cyan

    try {
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Stop-Service bits -Force -ErrorAction SilentlyContinue

        Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" `
            -Recurse -Force -ErrorAction SilentlyContinue

        Start-Service bits -ErrorAction SilentlyContinue
        Start-Service wuauserv -ErrorAction SilentlyContinue
    } catch {}
}

# ------------------------------------------------------------
function Clear-Prefetch {

    Write-Host "[CLEAN] Prefetch data" -ForegroundColor Cyan

    try {
        Remove-Item "$env:WINDIR\Prefetch\*" -Force -ErrorAction SilentlyContinue
    } catch {}
}

# ------------------------------------------------------------
function Clear-RecycleBin {

    Write-Host "[CLEAN] Recycle Bin" -ForegroundColor Cyan

    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    } catch {}
}

# ------------------------------------------------------------
function Clear-EventLogs {

    Write-Host "[CLEAN] Event Logs" -ForegroundColor Cyan

    try {
        wevtutil el | ForEach-Object {
            wevtutil cl "$_" 2>$null
        }
    } catch {}
}

# ------------------------------------------------------------
function Clear-DNSCache {

    Write-Host "[CLEAN] DNS Cache" -ForegroundColor Cyan

    try {
        ipconfig /flushdns | Out-Null
    } catch {}
}

# ------------------------------------------------------------
function Invoke-CleanSystem {

    Clear-Host
    Write-Host "+======================================================+" -ForegroundColor DarkGray
    Write-Host "| CLEAN SYSTEM                                          |" -ForegroundColor White
    Write-Host "+======================================================+" -ForegroundColor DarkGray
    Write-Host ""

    Clear-TempFolders
    Clear-WindowsUpdateCache
    Clear-Prefetch
    Clear-RecycleBin
    Clear-EventLogs
    Clear-DNSCache

    Write-Host ""
    Write-Host "[DONE] System cleanup completed." -ForegroundColor Green
    Write-Host ""

    Read-Host "Press Enter to return"
}
