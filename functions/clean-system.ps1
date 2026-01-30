# ============================================================
# PMK TOOLBOX - CLEAN SYSTEM (SIMPLE VERSION)
# Author : Minh Khai
# Target : Windows 10 / Windows 11
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# CLEAN TEMP FILES
# ============================================================
function Clear-TempFolders {

    Write-Host "[DANG DON DEP] Cac file tam thoi..." -ForegroundColor Cyan

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

# ============================================================
# CLEAN WINDOWS UPDATE CACHE
# ============================================================
function Clear-WindowsUpdateCache {

    Write-Host "[DANG DON DEP] Cache Windows Update..." -ForegroundColor Cyan

    try {
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Stop-Service bits -Force -ErrorAction SilentlyContinue

        Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" `
            -Recurse -Force -ErrorAction SilentlyContinue

        Start-Service bits -ErrorAction SilentlyContinue
        Start-Service wuauserv -ErrorAction SilentlyContinue
    } catch {}
}

# ============================================================
# CLEAN PREFETCH
# ============================================================
function Clear-Prefetch {

    Write-Host "[DANG DON DEP] Du lieu Prefetch..." -ForegroundColor Cyan

    try {
        Remove-Item "$env:WINDIR\Prefetch\*" `
            -Recurse -Force -ErrorAction SilentlyContinue
    } catch {}
}

# ============================================================
# CLEAN RECYCLE BIN
# ============================================================
function Clear-RecycleBinData {

    Write-Host "[DANG DON DEP] Thung rac (Recycle Bin)..." -ForegroundColor Cyan

    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    } catch {}
}

# ============================================================
# CLEAN EVENT LOGS
# ============================================================
function Clear-EventLogs {

    Write-Host "[DANG DON DEP] Event Logs..." -ForegroundColor Cyan

    try {
        wevtutil el | ForEach-Object {
            wevtutil cl "$_" 2>$null
        }
    } catch {}
}

# ============================================================
# CLEAN DNS CACHE
# ============================================================
function Clear-DNSCache {

    Write-Host "[DANG XOA] DNS Cache..." -ForegroundColor Cyan

    try {
        ipconfig /flushdns | Out-Null
    } catch {}
}

# ============================================================
# MAIN ENTRY - CALLED BY ToiUuPC.ps1 (TÊN CHUẨN)
# ============================================================
function Invoke-CleanSystem {

    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         DON DEP HE THONG               " -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    Clear-TempFolders
    Clear-WindowsUpdateCache
    Clear-Prefetch
    Clear-RecycleBinData
    Clear-EventLogs
    Clear-DNSCache

    Write-Host ""
    Write-Host "Da hoan tat don dep he thong!" -ForegroundColor Green
    Write-Host ""

    Pause
}
