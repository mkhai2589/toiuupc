# ==========================================================
# PMK TOOLBOX - DNS MANAGEMENT (WIN10/11 SAFE)
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

function Get-ActiveAdapter {
    Get-NetAdapter |
        Where-Object { $_.Status -eq "Up" -and $_.HardwareInterface } |
        Sort-Object InterfaceMetric |
        Select-Object -First 1
}

function Load-DnsConfig {
    $path = Join-Path $PSScriptRoot "..\config\dns.json"
    if (-not (Test-Path $path)) { return $null }
    Get-Content $path -Raw | ConvertFrom-Json
}

function Restore-Dhcp {
    param($Iface)
    Set-DnsClientServerAddress -InterfaceAlias $Iface -ResetServerAddresses
}

function Apply-Dns {
    param($Iface, $Dns)

    $servers = @()
    if ($Dns.Primary)   { $servers += $Dns.Primary }
    if ($Dns.Secondary) { $servers += $Dns.Secondary }

    if ($servers.Count -eq 0) { return }

    Set-DnsClientServerAddress `
        -InterfaceAlias $Iface `
        -ServerAddresses $servers
}

function Show-CurrentDns {
    param($Iface)
    $dns = (Get-DnsClientServerAddress -InterfaceAlias $Iface).ServerAddresses
    if (-not $dns) {
        Write-Host "Current DNS : DHCP" -ForegroundColor Green
    } else {
        Write-Host "DNS : $($dns -join ', ')" -ForegroundColor Yellow
    }
}

function Invoke-DnsMenu {
    $config = Load-DnsConfig
    if (-not $config) { return }

    $adapter = Get-ActiveAdapter
    if (-not $adapter) { return }

    $iface = $adapter.InterfaceAlias

    while ($true) {
        Clear-Host
        Write-Host "DNS MANAGEMENT" -ForegroundColor Cyan
        Write-Host "Adapter: $iface`n"
        Show-CurrentDns $iface
        Write-Host ""

        $map = @{}
        $i = 1
        foreach ($k in $config.PSObject.Properties.Name) {
            Write-Host "[$i] $k"
            $map[$i] = $k
            $i++
        }
        Write-Host "`n[0] Back"

        $sel = Read-Host "Select"
        if ($sel -eq "0") { return }

        if ($map.ContainsKey([int]$sel)) {
            $name = $map[[int]$sel]
            if ($name -eq "Default DHCP") {
                Restore-Dhcp $iface
            } else {
                Apply-Dns $iface $config.$name
            }
            Write-Host "Applied DNS: $name" -ForegroundColor Green
            Start-Sleep 1
        }
    }
}
