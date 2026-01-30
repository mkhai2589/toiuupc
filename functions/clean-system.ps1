# ============================================================
# PMK TOOLBOX - CLEAN SYSTEM
# Author : Minh Khai
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

function Clear-TempFolders {
    Write-Host "[CLEAN] Temp files"
    Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue
    Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force -EA SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -EA SilentlyContinue
}

function Clear-WindowsUpdateCache {
    Write-Host "[CLEAN] Windows Update cache"
    Stop-Service wuauserv,bits -Force -EA SilentlyContinue
    Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -EA SilentlyContinue
    Start-Service bits,wuauserv -EA SilentlyContinue
}

function Clear-RecycleBin {
    Write-Host "[CLEAN] Recycle Bin"
    Clear-RecycleBin -Force -EA SilentlyContinue
}

function Clear-DNSCache {
    Write-Host "[CLEAN] DNS cache"
    ipconfig /flushdns | Out-Null
}

function Invoke-CleanSystem {
    Clear-Host
    Write-Host "CLEAN SYSTEM" -ForegroundColor Cyan
    Write-Host "---------------------------------"

    Clear-TempFolders
    Clear-WindowsUpdateCache
    Clear-RecycleBin
    Clear-DNSCache

    Write-Host "`n[DONE] Cleanup completed" -ForegroundColor Green
    Read-Host "Press Enter"
}
