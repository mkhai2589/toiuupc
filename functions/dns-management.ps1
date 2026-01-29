# functions/dns-management.ps1

function Get-DnsProfiles {
    param([string]$ConfigPath)
    Get-Content $ConfigPath | ConvertFrom-Json
}

function Apply-DnsProfile {
    param(
        [string[]]$IPv4
    )

    Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
        Set-DnsClientServerAddress `
            -InterfaceIndex $_.InterfaceIndex `
            -ServerAddresses $IPv4
    }
}

function Start-DnsManager {
    param([string]$ConfigPath)

    $dns = Get-DnsProfiles $ConfigPath

    Clear-Host
    Write-Host "=== DNS Manager ==="

    for ($i=0; $i -lt $dns.Count; $i++) {
        Write-Host "$($i+1). $($dns[$i].name)"
    }
    Write-Host "0. Exit"

    $c = Read-Host "Select"

    if ($c -eq "0") { return }

    if (-not [int]::TryParse($c,[ref]$null)) {
        Write-Host "Invalid choice"; Pause; return
    }

    $i = [int]$c - 1
    if ($i -lt 0 -or $i -ge $dns.Count) {
        Write-Host "Out of range"; Pause; return
    }

    Apply-DnsProfile -IPv4 $dns[$i].ipv4
    Write-Host "DNS applied: $($dns[$i].name)"
    Pause
}
