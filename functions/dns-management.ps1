# ==========================================================
# dns-management.ps1
# PMK Toolbox - DNS Management (FINAL)
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ==========================================================
# GET ACTIVE ADAPTER
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
# LOAD DNS JSON
# ==========================================================
function Load-DnsConfig {
    $path = Join-Path $Global:ConfigDir "dns.json"

    if (-not (Test-Path $path)) {
        Write-Host "dns.json not found!" -ForegroundColor Red
        Read-Host "Press Enter"
        return $null
    }

    try {
        return Get-Content $path -Raw | ConvertFrom-Json
    } catch {
        Write-Host "Invalid dns.json format!" -ForegroundColor Red
        Read-Host "Press Enter"
        return $null
    }
}

# ==========================================================
# APPLY DNS
# ==========================================================
function Apply-Dns {
    param(
        [string]$InterfaceAlias,
        [object]$Dns
    )

    # IPv4
    if ($Dns.Primary -or $Dns.Secondary) {
        $ipv4 = @()
        if ($Dns.Primary)   { $ipv4 += $Dns.Primary }
        if ($Dns.Secondary) { $ipv4 += $Dns.Secondary }

        Set-DnsClientServerAddress `
            -InterfaceAlias $InterfaceAlias `
            -AddressFamily IPv4 `
            -ServerAddresses $ipv4 `
            -ErrorAction SilentlyContinue
    }

    # IPv6
    if ($Dns.Primary6 -or $Dns.Secondary6) {
        $ipv6 = @()
        if ($Dns.Primary6)   { $ipv6 += $Dns.Primary6 }
        if ($Dns.Secondary6) { $ipv6 += $Dns.Secondary6 }

        Set-DnsClientServerAddress `
            -InterfaceAlias $InterfaceAlias `
            -AddressFamily IPv6 `
            -ServerAddresses $ipv6 `
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

    $v4 = (Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
    $v6 = (Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv6 -ErrorAction SilentlyContinue).ServerAddresses

    if (-not $v4 -and -not $v6) {
        Write-Host "Current DNS : DHCP" -ForegroundColor Green
    } else {
        if ($v4) { Write-Host "IPv4 : $($v4 -join ', ')" -ForegroundColor Yellow }
        if ($v6) { Write-Host "IPv6 : $($v6 -join ', ')" -ForegroundColor Yellow }
    }
}

# ==========================================================
# DNS MENU
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

    while ($true) {
        Clear-Host

        Write-Host "DNS MANAGEMENT" -ForegroundColor Cyan
        Write-Host "Adapter : $iface"
        Write-Host ""
        Show-CurrentDns $iface
        Write-Host ""

        $keys = $config.PSObject.Properties.Name
        $map  = @{}
        $i = 1

        foreach ($k in $keys) {
            Write-Host ("[{0}] {1}" -f $i, $k)
            $map[$i] = $k
            $i++
        }

        Write-Host ""
        Write-Host "[0] Back"
        Write-Host ""

        $sel = Read-Host "Select"

        if ($sel -eq "0") { break }

        if ($map.ContainsKey([int]$sel)) {
            $name = $map[[int]$sel]
            $dns  = $config.$name

            if ($name -eq "Default DHCP") {
                Restore-Dhcp $iface
                Write-Host "Restored DHCP DNS" -ForegroundColor Green
            } else {
                Apply-Dns -InterfaceAlias $iface -Dns $dns
                Write-Host "Applied DNS: $name" -ForegroundColor Green
            }

            Start-Sleep 1
        }
    }
}
