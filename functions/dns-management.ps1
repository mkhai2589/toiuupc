# dns-management.ps1 - Sửa lỗi DNS và quản lý màn hình
Set-StrictMode -Off
$ErrorActionPreference = 'SilentlyContinue'

function Get-ActiveAdapter {
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Sort-Object InterfaceMetric | Select-Object -First 1
}

function Load-DnsConfig {
    $path = Join-Path $PSScriptRoot "..\config\dns.json"
    if (-not (Test-Path $path)) {
        Write-Host "ERROR: dns.json not found!" -ForegroundColor Red
        return $null
    }
    try {
        return Get-Content $path -Raw | ConvertFrom-Json
    } catch {
        Write-Host "ERROR: Invalid dns.json format!" -ForegroundColor Red
        return $null
    }
}

function Apply-Dns {
    param([string]$InterfaceAlias, [object]$Dns)
    $servers = @()
    if ($Dns.Primary)   { $servers += $Dns.Primary }
    if ($Dns.Secondary) { $servers += $Dns.Secondary }
    if ($Dns.Primary6)  { $servers += $Dns.Primary6 }
    if ($Dns.Secondary6){ $servers += $Dns.Secondary6 }

    if ($servers.Count -gt 0) {
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $servers
    } else {
        # Nếu không có server nào (trường hợp DHCP) thì reset
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ResetServerAddresses
    }
}

function Restore-Dhcp {
    param([string]$InterfaceAlias)
    Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ResetServerAddresses
}

function Show-CurrentDns {
    param([string]$InterfaceAlias)
    $dns = Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias
    if (-not $dns.ServerAddresses -or $dns.ServerAddresses.Count -eq 0) {
        Write-Host "Current DNS : DHCP" -ForegroundColor Green
    } else {
        Write-Host "Current DNS : $($dns.ServerAddresses -join ', ')" -ForegroundColor Yellow
    }
}

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

    while ($true) {
        Clear-Host
        Write-Host "DNS MANAGEMENT" -ForegroundColor Cyan
        Write-Host "Adapter : $iface"
        Write-Host ""
        Show-CurrentDns -InterfaceAlias $iface
        Write-Host ""

        $map = @{}
        $i = 1
        foreach ($k in $config.PSObject.Properties.Name) {
            Write-Host "[$i] $k"
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
            } else {
                Apply-Dns -InterfaceAlias $iface -Dns $config.$name
                Write-Host "Applied DNS: $name" -ForegroundColor Green
            }
            Start-Sleep 1
        }
    }
}
