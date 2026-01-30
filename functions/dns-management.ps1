# ==================================================
# dns-management.ps1 – DNS (FINAL)
# ==================================================

. "$PSScriptRoot\utils.ps1"

function Run-DNSManagement {

    Assert-Admin

    Write-Step 1 "Select DNS"
    Write-Host "1. Google DNS"
    Write-Host "2. Cloudflare DNS"
    Write-Host "3. Reset (DHCP)"

    $c = Read-Host "Choose"

    $iface = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1

    switch ($c) {
        "1" {
            Set-DnsClientServerAddress -InterfaceIndex $iface.ifIndex -ServerAddresses 8.8.8.8,8.8.4.4
            Write-OK "Google DNS applied"
        }
        "2" {
            Set-DnsClientServerAddress -InterfaceIndex $iface.ifIndex -ServerAddresses 1.1.1.1,1.0.0.1
            Write-OK "Cloudflare DNS applied"
        }
        "3" {
            Set-DnsClientServerAddress -InterfaceIndex $iface.ifIndex -ResetServerAddresses
            Write-OK "DNS reset"
        }
    }

    Pause-Tool
}
