# ==========================================================
# dns-management.ps1 - DNS MANAGEMENT (FIXED)
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

function Get-ActiveNetworkAdapter {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    if ($adapters) {
        return $adapters | Sort-Object InterfaceMetric | Select-Object -First 1
    }
    return $null
}

function Show-DnsMenu {
    param($Config)
    
    $adapter = Get-ActiveNetworkAdapter
    if (-not $adapter) {
        Write-Status "Khong tim thay adapter mang dang hoat dong!" -Type 'ERROR'
        Pause
        return
    }
    
    while ($true) {
        # Get current DNS
        $currentDns = Get-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ErrorAction SilentlyContinue
        $currentServers = if ($currentDns.ServerAddresses) { $currentDns.ServerAddresses -join ', ' } else { "DHCP" }
        
        Show-Header -Title "QUAN LY DNS"
        Write-Host " Adapter hien tai: $($adapter.InterfaceAlias)" -ForegroundColor $global:UI_Colors.Value
        Write-Host " DNS hien tai: $currentServers" -ForegroundColor $global:UI_Colors.Highlight
        Write-Host ""
        
        # Build menu from DNS config
        $menuItems = @()
        $index = 1
        
        foreach ($dnsName in ($Config.PSObject.Properties.Name)) {
            $dnsConfig = $Config.$dnsName
            $primary = if ($dnsConfig.Primary) { $dnsConfig.Primary } else { "DHCP" }
            
            $menuItems += @{ 
                Key = "$index"; 
                Text = "$($dnsName.PadRight(25)) $primary"
            }
            $index++
        }
        
        $menuItems += @{ Key = "0"; Text = "Quay lai Menu Chinh" }
        
        Show-Menu -MenuItems $menuItems -Title "CHON DNS SERVER" -Prompt "Lua chon DNS (0 de quay lai): "
        
        $choice = Read-Host
        
        if ($choice -eq "0") {
            return
        }
        
        $dnsIndex = [int]$choice - 1
        $dnsNames = $Config.PSObject.Properties.Name
        if ($dnsIndex -ge 0 -and $dnsIndex -lt $dnsNames.Count) {
            $selectedDns = $dnsNames[$dnsIndex]
            $dnsConfig = $Config.$selectedDns
            
            Show-Header -Title "AP DUNG DNS"
            Write-Status "Dang ap dung DNS: $selectedDns" -Type 'INFO'
            
            # Collect all DNS addresses (IPv4 + IPv6)
            $servers = @()
            if ($dnsConfig.Primary)   { $servers += $dnsConfig.Primary }
            if ($dnsConfig.Secondary) { $servers += $dnsConfig.Secondary }
            if ($dnsConfig.Primary6)   { $servers += $dnsConfig.Primary6 }
            if ($dnsConfig.Secondary6) { $servers += $dnsConfig.Secondary6 }
            
            if ($servers.Count -gt 0) {
                # Apply all DNS servers in ONE command (FIXED)
                Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ServerAddresses $servers
                Write-Status "Da ap dung DNS servers: $($servers -join ', ')" -Type 'SUCCESS'
            } else {
                # Reset to DHCP
                Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ResetServerAddresses
                Write-Status "Da reset ve DHCP" -Type 'SUCCESS'
            }
            
            # Clear DNS cache
            ipconfig /flushdns | Out-Null
            Write-Status "Da xoa DNS cache" -Type 'INFO'
            
            Pause
        } else {
            Write-Status "Lua chon khong hop le!" -Type 'WARNING'
            Pause
        }
    }
}
