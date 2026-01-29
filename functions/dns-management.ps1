# ===============================
# DNS Management - SAFE VERSION
# ===============================

function Start-DnsManager {

    param(
        [string]$ConfigPath
    )

    Clear-Host
    Write-Host "=== DNS Manager ===" -ForegroundColor Cyan

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "Khong tim thay file dns.json" -ForegroundColor Red
        Pause
        return
    }

    $dnsList = Get-Content $ConfigPath | ConvertFrom-Json

    $i = 1
    foreach ($dns in $dnsList) {
        Write-Host "$i. $($dns.name)"
        $i++
    }
    Write-Host "0. Thoat"

    $choice = Read-Host "Chon DNS"

    if ($choice -eq "0") { return }

    if ($choice -notmatch '^\d+$') {
        Write-Host "Lua chon khong hop le" -ForegroundColor Red
        Pause
        return
    }

    $index = [int]$choice - 1
    if ($index -lt 0 -or $index -ge $dnsList.Count) {
        Write-Host "Lua chon ngoai pham vi" -ForegroundColor Red
        Pause
        return
    }

    $selected = $dnsList[$index]

    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        Set-DnsClientServerAddress `
            -InterfaceIndex $_.InterfaceIndex `
            -ServerAddresses $selected.ipv4
    }

    Write-Host "Da ap dung DNS: $($selected.name)" -ForegroundColor Green
    Pause
}
