# ==========================================================
# dns-management.ps1
# PMK Toolbox - DNS Manager (WinUtil Style)
# Windows 10 / 11
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ==========================================================
# HELPERS
# ==========================================================
function Get-ActiveAdapters {
    Get-NetAdapter |
        Where-Object { $_.Status -eq "Up" -and $_.HardwareInterface }
}

function Get-CurrentDns {
    param([string]$InterfaceAlias)

    try {
        (Get-DnsClientServerAddress `
            -InterfaceAlias $InterfaceAlias `
            -AddressFamily IPv4).ServerAddresses
    } catch {
        @()
    }
}

function Set-DnsServers {
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

function Reset-DnsAuto {
    param([string]$InterfaceAlias)

    Set-DnsClientServerAddress `
        -InterfaceAlias $InterfaceAlias `
        -ResetServerAddresses
}

# ==========================================================
# DNS STATE DETECTION
# ==========================================================
function Get-ActiveDnsIndex {
    param($Config)

    $ad = Get-ActiveAdapters | Select-Object -First 1
    if (-not $ad) { return -1 }

    $current = Get-CurrentDns $ad.Name
    if (-not $current) { return -1 }

    for ($i = 0; $i -lt $Config.dns.Count; $i++) {
        if (@($Config.dns[$i].ipv4) -join ',' -eq @($current) -join ',') {
            return $i
        }
    }
    return -1
}

# ==========================================================
# DNS LATENCY TEST
# ==========================================================
function Test-DnsLatency {
    param([string]$Server)

    try {
        $ping = Test-Connection -ComputerName $Server -Count 1 -Quiet:$false -ErrorAction Stop
        return $ping.ResponseTime
    } catch {
        return 9999
    }
}

function Measure-DnsProfiles {
    param($Config)

    foreach ($dns in $Config.dns) {
        $dns | Add-Member -NotePropertyName latency -NotePropertyValue 9999 -Force

        if ($dns.ipv4 -and $dns.ipv4.Count -gt 0) {
            $dns.latency = Test-DnsLatency $dns.ipv4[0]
        }
    }

    return $Config
}

function Get-FastestDnsIndex {
    param($Config)

    $min = 9999
    $idx = -1

    for ($i = 0; $i -lt $Config.dns.Count; $i++) {
        if ($Config.dns[$i].latency -lt $min) {
            $min = $Config.dns[$i].latency
            $idx = $i
        }
    }
    return $idx
}

# ==========================================================
# MAIN MENU
# ==========================================================
function Invoke-DnsMenu {
    param([string]$ConfigPath)

    Ensure-Admin

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "Khong tim thay file DNS config" -ForegroundColor Red
        return
    }

    $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $cfg = Measure-DnsProfiles $cfg

    $activeIndex  = Get-ActiveDnsIndex $cfg
    $fastestIndex = Get-FastestDnsIndex $cfg
    $adapters = Get-ActiveAdapters

    if (-not $adapters) {
        Write-Host "Khong tim thay card mang hoat dong" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "========== DNS MANAGEMENT =========="

    for ($i = 0; $i -lt $cfg.dns.Count; $i++) {

        $tag = ""
        if ($i -eq $activeIndex)  { $tag += " [Dang dung]" }
        if ($i -eq $fastestIndex) { $tag += " [Nhanh nhat]" }

        if ($tag) {
            Write-Host "$($i + 1). $($cfg.dns[$i].name) $tag" -ForegroundColor Green
        } else {
            Write-Host "$($i + 1). $($cfg.dns[$i].name)"
        }
    }

    Write-Host "R. Reset DNS ve tu dong"
    Write-Host "0. Thoat"

    $choice = Read-Host "Lua chon"

    if ($choice -eq "0") { return }

    if ($choice -eq "R") {
        foreach ($ad in $adapters) {
            Reset-DnsAuto $ad.Name
            Write-Log "Reset DNS auto tren $($ad.Name)"
        }
        Write-Host "Da reset DNS ve tu dong" -ForegroundColor Yellow
        return
    }

    if ($choice -notmatch '^\d+$') {
        Write-Host "Lua chon khong hop le"
        return
    }

    $index = [int]$choice - 1
    if ($index -lt 0 -or $index -ge $cfg.dns.Count) {
        Write-Host "Lua chon khong hop le"
        return
    }

    $dns = $cfg.dns[$index]

    $step = 0
    $total = $adapters.Count

    foreach ($ad in $adapters) {

        $percent = [int](($step / $total) * 100)

        Write-Progress `
            -Activity "Dang ap dung DNS" `
            -Status "Adapter: $($ad.Name)" `
            -PercentComplete $percent

        Set-DnsServers `
            -InterfaceAlias $ad.Name `
            -IPv4 $dns.ipv4 `
            -IPv6 $dns.ipv6

        Write-Log "Applied DNS $($dns.name) tren $($ad.Name)"
        $step++
    }

    Write-Progress -Activity "Dang ap dung DNS" -Completed
    Write-Host "Da ap dung DNS: $($dns.name)" -ForegroundColor Green
}
