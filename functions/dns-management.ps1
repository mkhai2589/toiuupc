# ==============================
# PMK ToiUuPC – DNS Management
# ==============================

$ErrorActionPreference = "Stop"

# ---------- Load dns.json ----------
function Load-DnsConfig {
    $path = Join-Path $PSScriptRoot "..\config\dns.json"
    if (-not (Test-Path $path)) {
        throw "Không tìm thấy dns.json"
    }
    return Get-Content $path -Raw | ConvertFrom-Json
}

# ---------- Lấy adapter đang hoạt động ----------
function Get-ActiveAdapters {
    Get-NetAdapter |
        Where-Object {
            $_.Status -eq "Up" -and
            $_.HardwareInterface -eq $true
        }
}

# ---------- Kiểm tra DNS hiện tại ----------
function Test-DnsMatch {
    param (
        [string]$InterfaceAlias,
        [array]$ExpectedV4,
        [array]$ExpectedV6
    )

    $current = Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias

    $v4ok = @($current.ServerAddresses | Where-Object { $_ -match '\.' }) -join ',' `
            -eq ($ExpectedV4 -join ',')

    $v6ok = @($current.ServerAddresses | Where-Object { $_ -match ':' }) -join ',' `
            -eq ($ExpectedV6 -join ',')

    return ($v4ok -and $v6ok)
}

# ---------- Set DNS ----------
function Apply-Dns {
    param (
        [string]$Name,
        [pscustomobject]$Dns
    )

    $adapters = Get-ActiveAdapters
    if ($adapters.Count -eq 0) {
        Write-Host "❌ Không tìm thấy card mạng đang hoạt động." -ForegroundColor Red
        return
    }

    foreach ($adapter in $adapters) {

        if ([string]::IsNullOrWhiteSpace($Dns.Primary)) {
            Write-Host "↩ Khôi phục DHCP DNS cho $($adapter.Name)" -ForegroundColor Yellow
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ResetServerAddresses
            continue
        }

        $v4 = @($Dns.Primary, $Dns.Secondary) | Where-Object { $_ }
        $v6 = @($Dns.Primary6, $Dns.Secondary6) | Where-Object { $_ }

        if (Test-DnsMatch -InterfaceAlias $adapter.Name -ExpectedV4 $v4 -ExpectedV6 $v6) {
            Write-Host "✔ $($adapter.Name): DNS đã đúng, bỏ qua" -ForegroundColor DarkGray
            continue
        }

        Write-Host "➡ Áp dụng DNS [$Name] cho $($adapter.Name)" -ForegroundColor Cyan

        Set-DnsClientServerAddress `
            -InterfaceAlias $adapter.Name `
            -ServerAddresses ($v4 + $v6)
    }
}

# ---------- Menu ----------
function Show-DnsMenu {
    param (
        [pscustomobject]$Config
    )

    Clear-Host
    Write-Host "===== QUẢN LÝ DNS =====" -ForegroundColor Cyan
    Write-Host "Chọn DNS muốn áp dụng" -ForegroundColor DarkGray
    Write-Host ""

    $keys = $Config.PSObject.Properties.Name
    for ($i = 0; $i -lt $keys.Count; $i++) {
        Write-Host ("{0,2}. {1}" -f ($i + 1), $keys[$i])
    }

    Write-Host ""
    $choice = Read-Host "Nhập số (ENTER để thoát)"

    if ([string]::IsNullOrWhiteSpace($choice)) {
        return $null
    }

    if ($choice -match '^\d+$') {
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $keys.Count) {
            return $keys[$index]
        }
    }

    return $null
}

# ---------- MAIN ----------
function Start-DnsManager {

    $config = Load-DnsConfig

    while ($true) {
        $selected = Show-DnsMenu -Config $config
        if (-not $selected) { break }

        Apply-Dns -Name $selected -Dns $config.$selected

        Write-Host "`n✅ Hoàn tat. Nhan phim bat ky de tiep tuc..." -ForegroundColor Green
        [void][System.Console]::ReadKey($true)
    }
}

# ---------- Run ----------
Start-DnsManager
