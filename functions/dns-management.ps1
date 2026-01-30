# ==========================================================
# PMK TOOLBOX - DNS MANAGEMENT
# Author : Minh Khai
# Compatible: Windows 10 / Windows 11 (PowerShell 5.1)
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

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
        Write-Host "ERROR: dns.json not found!" -ForegroundColor Red
        Read-Host "Press Enter"
        return $null
    }

    try {
        return Get-Content $path -Raw | ConvertFrom-Json
    }
    catch {
        Write-Host "ERROR: Invalid dns.json format!" -ForegroundColor Red
        Read-Host "Press Enter"
        return $null
    }
}

# ==========================================================
# APPLY DNS (IPv4 + IPv6 SAFE)
# ==========================================================
function Apply-Dns {
    param(
        [string]$InterfaceAlias,
        [object]$Dns
    )

    $servers = @()

    if ($Dns.Primary)   { $servers += $Dns.Primary }
    if ($Dns.Secondary) { $servers += $Dns.Secondary }

    if ($servers.Count -gt 0) {
        Set-DnsClientServerAddress `
            -InterfaceAlias $InterfaceAlias `
            -ServerAddresses $servers `
            -ErrorAction SilentlyContinue
    }

    $servers6 = @()
    if ($Dns.Primary6)   { $servers6 += $Dns.Primary6 }
    if ($Dns.Secondary6) { $servers6 += $Dns.Secondary6 }

    if ($servers6.Count -gt 0) {
        Set-DnsClientServerAddress `
            -InterfaceAlias $InterfaceAlias `
            -ServerAddresses $servers6 `
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
        Write-Host "Current DNS : DHCP" -ForegroundColor Green
    }
    else {
        Write-Host "Current DNS : $($dns.ServerAddresses -join ', ')" -ForegroundColor Yellow
    }
}

# ==========================================================
# DRAW STATIC HEADER (NO REFRESH)
# ==========================================================
function Draw-DnsHeader {
    param([string]$InterfaceAlias)

    Clear-Host
    Write-Host "DNS MANAGEMENT" -ForegroundColor Cyan
    Write-Host "Adapter : $InterfaceAlias"
    Write-Host ""
}

# ==========================================================
# DNS MENU (MAIN)
# ==========================================================
function Invoke-DnsMenu {

    $config = Load-DnsConfig
    if (-not $config) { return }

    $adapter = Get-ActiveAdapter
    if (-not $adapter) {
        Write-Host "No active network adapter!" -ForegroundColor Red
        Read-Host "Press Enter"
        return
    }

    $iface = $adapter.InterfaceAlias

    # 👉 CLEAR + DRAW HEADER 1 LẦN DUY NHẤT
    Draw-DnsHeader -InterfaceAlias $iface

    while ($true) {

        Show-CurrentDns -InterfaceAlias $iface
        Write-Host ""

        $map = @{}
        $i = 1

        foreach ($k in $config.PSObject.Properties.Name) {
            Write-Host ("[{0}] {1}" -f $i, $k)
            $map[$i] = $k
            $i++
        }

        Write-Host ""
        Write-Host "[0] Back"
        Write-Host ""

        $sel = Read-Host "Select"

        if ($sel -eq "0") {
            return
        }

        if ($map.ContainsKey([int]$sel)) {

            $name = $map[[int]$sel]

            if ($name -eq "Default DHCP") {
                Restore-Dhcp -InterfaceAlias $iface
                Write-Host "Restored DHCP DNS" -ForegroundColor Green
            }
            else {
                Apply-Dns -InterfaceAlias $iface -Dns $config.$name
                Write-Host "Applied DNS: $name" -ForegroundColor Green
            }

            Start-Sleep 1
            Write-Host ""
        }
    }
}
