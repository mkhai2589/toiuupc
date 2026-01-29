function Set-DNSServer {
    param([string]$DNSServerName)

    $dnsJson = Get-Content "$PSScriptRoot\..\config\dns.json" -Raw | ConvertFrom-Json
    $dnsConfig = $dnsJson.$DNSServerName

    try {
        if ($DNSServerName -eq "Default DHCP") {
            Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
                Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
            }
            Clear-DnsClientCache -ErrorAction SilentlyContinue
            return "✅ Reset DNS to DHCP"
        }

        if ($dnsConfig) {
            $dnsAddresses = @($dnsConfig.Primary, $dnsConfig.Secondary) | Where-Object { $_ }
            $dnsAddresses6 = @($dnsConfig.Primary6, $dnsConfig.Secondary6) | Where-Object { $_ }
            Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
                Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ServerAddresses ($dnsAddresses + $dnsAddresses6) -ErrorAction Stop
            }
            Clear-DnsClientCache -ErrorAction SilentlyContinue
            return "✅ Set DNS: $DNSServerName (IPv4/IPv6)"
        } else {
            return "❌ DNS config not found"
        }
    } catch {
        return "❌ Error: $_"
    }
}

function Set-DNSServerMenu {
    $dnsJson = Get-Content "$PSScriptRoot\..\config\dns.json" -Raw | ConvertFrom-Json
    $servers = $dnsJson.PSObject.Properties.Name
    Write-Host "Available DNS: $($servers -join ', ')"
    Write-Host "Chọn DNS (e.g. Google):"
    $selected = Read-Host
    if ($servers -contains $selected) {
        Set-DNSServer -DNSServerName $selected
    } else {
        Write-Host "Sai tên DNS!" -ForegroundColor $ERROR_COLOR
    }
}