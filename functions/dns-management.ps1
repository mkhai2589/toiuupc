# ==========================================================
# PMK TOOLBOX - DNS MANAGEMENT (SIMPLE VERSION)
# Author : Minh Khai
# Compatible: Windows 10 / Windows 11 (PowerShell 5.1)
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

# ==========================================================
# GET ACTIVE NETWORK ADAPTER
# ==========================================================
function Get-ActiveAdapter {
    Get-NetAdapter |
        Where-Object {
            $_.Status -eq "Up" -and $_.HardwareInterface
        } |
        Sort-Object InterfaceMetric |
        Select-Object -First 1
}

# ==========================================================
# LOAD DNS CONFIG JSON
# ==========================================================
function Load-DnsConfig {
    $path = Join-Path $PSScriptRoot "..\config\dns.json"

    if (-not (Test-Path $path)) {
        Write-Host "LOI: Khong tim thay file dns.json!" -ForegroundColor Red
        return $null
    }

    try {
        return Get-Content $path -Raw | ConvertFrom-Json
    }
    catch {
        Write-Host "LOI: Dinh dang dns.json khong hop le!" -ForegroundColor Red
        return $null
    }
}

# ==========================================================
# APPLY DNS (IPv4 + IPv6 GỘP CHUNG)
# ==========================================================
function Apply-Dns {
    param(
        [string]$InterfaceAlias,
        [object]$Dns
    )

    $servers = @()

    if ($Dns.Primary)   { $servers += $Dns.Primary }
    if ($Dns.Secondary) { $servers += $Dns.Secondary }
    if ($Dns.Primary6)   { $servers += $Dns.Primary6 }
    if ($Dns.Secondary6) { $servers += $Dns.Secondary6 }

    if ($servers.Count -gt 0) {
        Set-DnsClientServerAddress `
            -InterfaceAlias $InterfaceAlias `
            -ServerAddresses $servers `
            -ErrorAction SilentlyContinue
    } else {
        # Nếu không có server nào (trường hợp Default DHCP) thì reset
        Set-DnsClientServerAddress `
            -InterfaceAlias $InterfaceAlias `
            -ResetServerAddresses `
            -ErrorAction SilentlyContinue
    }
}

# ==========================================================
# RESTORE DHCP
# ==========================================================
function Restore-Dhcp {
    param([string]$InterfaceAlias)

    Set-DnsClientServerAddress `
        -InterfaceAlias $InterfaceAlias `
        -ResetServerAddresses `
        -ErrorAction SilentlyContinue
}

# ==========================================================
# SHOW CURRENT DNS
# ==========================================================
function Show-CurrentDns {
    param([string]$InterfaceAlias)

    $dns = Get-DnsClientServerAddress `
        -InterfaceAlias $InterfaceAlias `
        -ErrorAction SilentlyContinue

    if (-not $dns.ServerAddresses -or $dns.ServerAddresses.Count -eq 0) {
        Write-Host "DNS hien tai : DHCP" -ForegroundColor Green
    }
    else {
        Write-Host "DNS hien tai : $($dns.ServerAddresses -join ', ')" -ForegroundColor Yellow
    }
}

# ==========================================================
# DNS MENU (MAIN)
# ==========================================================
function Invoke-DnsMenu {

    $config = Load-DnsConfig
    if (-not $config) {
        Write-Host "Khong the tai cau hinh DNS. Tro ve menu chinh." -ForegroundColor Red
        Pause
        return
    }

    $adapter = Get-ActiveAdapter
    if (-not $adapter) {
        Write-Host "Khong tim thay adapter mang dang hoat dong!" -ForegroundColor Red
        Pause
        return
    }

    $iface = $adapter.InterfaceAlias

    while ($true) {
        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "          QUAN LY DNS                   " -ForegroundColor White
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Adapter: $iface"
        Write-Host ""
        Show-CurrentDns -InterfaceAlias $iface
        Write-Host ""

        $map = @{}
        $i = 1

        foreach ($k in $config.PSObject.Properties.Name) {
            Write-Host (" [{0}] {1}" -f $i, $k)
            $map[$i] = $k
            $i++
        }

        Write-Host ""
        Write-Host " [0] Quay lai Menu Chinh"
        Write-Host ""

        $sel = Read-Host "Lua chon"

        if ($sel -eq "0") {
            return
        }

        if ($map.ContainsKey([int]$sel)) {
            $name = $map[[int]$sel]
            if ($name -eq "Default DHCP") {
                Restore-Dhcp -InterfaceAlias $iface
                Write-Host "Da khoi phuc DNS ve DHCP." -ForegroundColor Green
            }
            else {
                Apply-Dns -InterfaceAlias $iface -Dns $config.$name
                Write-Host "Da ap dung DNS: $name" -ForegroundColor Green
            }
            # Hiển thị lại DNS hiện tại sau khi áp dụng
            Write-Host ""
            Show-CurrentDns -InterfaceAlias $iface
            Write-Host ""
            Pause
        } else {
            Write-Host "Lua chon khong hop le!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
