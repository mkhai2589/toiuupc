# dns-management.ps1
# DNS manager

Set-StrictMode -Off

function Get-NetworkAdapters {
    Get-NetAdapter |
        Where-Object { $_.Status -eq "Up" }
}

function Apply-Dns {
    param(
        [string]$InterfaceAlias,
        [string[]]$IPv4,
        [string[]]$IPv6
    )

    if ($IPv4) {
        Set-DnsClientServerAddress `
            -InterfaceAlias $InterfaceAlias `
            -ServerAddresses $IPv4 `
            -AddressFamily IPv4
    }

    if ($IPv6) {
        Set-DnsClientServerAddress `
            -InterfaceAlias $InterfaceAlias `
            -ServerAddresses $IPv6 `
            -AddressFamily IPv6
    }
}

function Start-DnsManager {
    param([string]$ConfigPath)

    Require-Admin

    $cfg = Read-JsonFile $ConfigPath
    $adapters = Get-NetworkAdapters

    Write-Host ""
    Write-Host "Chon DNS:"

    for ($i = 0; $i -lt $cfg.dns.Count; $i++) {
        Write-Host "$($i + 1). $($cfg.dns[$i].name)"
    }

    Write-Host "0. Huy"
    $choice = Read-Host "Lua chon"

    if ($choice -eq "0") { return }

    $index = [int]$choice - 1
    if ($index -lt 0 -or $index -ge $cfg.dns.Count) {
        Write-Host "Lua chon khong hop le"
        return
    }

    $dns = $cfg.dns[$index]

    foreach ($ad in $adapters) {
        Apply-Dns `
            -InterfaceAlias $ad.Name `
            -IPv4 $dns.ipv4 `
            -IPv6 $dns.ipv6

        Write-Log "dns" "Applied $($dns.name) to $($ad.Name)"
    }

    Write-Host "Da ap dung DNS: $($dns.name)"
}
