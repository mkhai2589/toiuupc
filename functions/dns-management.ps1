# ==========================================================
# dns-management.ps1 - DNS MANAGEMENT (FIXED WITH IPv4/IPv6)
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

function Get-ActiveNetworkAdapter {
    $adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
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
        # Get current DNS với phân biệt IPv4/IPv6
        $currentDns = Get-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ErrorAction SilentlyContinue
        
        # Tách IPv4 và IPv6
        $ipv4Servers = @()
        $ipv6Servers = @()
        if ($currentDns -and $currentDns.ServerAddresses) {
            foreach ($addr in $currentDns.ServerAddresses) {
                if ($addr.Contains(':')) {
                    $ipv6Servers += $addr
                } else {
                    $ipv4Servers += $addr
                }
            }
        }
        
        $currentIPv4 = if ($ipv4Servers.Count -gt 0) { $ipv4Servers -join ', ' } else { "DHCP" }
        $currentIPv6 = if ($ipv6Servers.Count -gt 0) { $ipv6Servers -join ', ' } else { "DHCP" }
        
        Show-Header -Title "QUAN LY DNS"
        Write-Host " Adapter hien tai: $($adapter.InterfaceAlias)" -ForegroundColor $global:UI_Colors.Value
        Write-Host ""
        Write-Host " DNS HIEN TAI:" -ForegroundColor $global:UI_Colors.Title
        Write-Host "   IPv4: $currentIPv4" -ForegroundColor $global:UI_Colors.Highlight
        Write-Host "   IPv6: $currentIPv6" -ForegroundColor $global:UI_Colors.Highlight
        Write-Host ""
        Write-Host "─" * 40 -ForegroundColor $global:UI_Colors.Border
        Write-Host ""
        
        # Build menu từ DNS config
        $menuItems = @()
        $index = 1
        
        foreach ($dnsName in ($Config.PSObject.Properties.Name)) {
            $dnsConfig = $Config.$dnsName
            $primary = if ($dnsConfig.Primary) { $dnsConfig.Primary } else { "DHCP" }
            $primary6 = if ($dnsConfig.Primary6) { $dnsConfig.Primary6 } else { "" }
            
            $displayText = "$($dnsName.PadRight(20))"
            if ($primary -ne "DHCP") {
                $displayText += " IPv4: $primary"
                if ($primary6) {
                    $displayText += " IPv6: $primary6"
                }
            } else {
                $displayText += " (Reset to DHCP)"
            }
            
            $menuItems += @{ 
                Key = "$index"; 
                Text = $displayText
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
            
            # Thu thập tất cả địa chỉ DNS (IPv4 + IPv6)
            $servers = @()
            if ($dnsConfig.Primary)   { $servers += $dnsConfig.Primary }
            if ($dnsConfig.Secondary) { $servers += $dnsConfig.Secondary }
            if ($dnsConfig.Primary6)   { $servers += $dnsConfig.Primary6 }
            if ($dnsConfig.Secondary6) { $servers += $dnsConfig.Secondary6 }
            
            Write-Host ""
            if ($servers.Count -gt 0) {
                Write-Host " DNS servers:" -ForegroundColor $global:UI_Colors.Label
                foreach ($server in $servers) {
                    Write-Host "   - $server" -ForegroundColor $global:UI_Colors.Value
                }
                Write-Host ""
                
                # Áp dụng tất cả DNS servers trong MỘT lệnh (ĐÃ SỬA)
                Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ServerAddresses $servers
                Write-Status "Da ap dung DNS thanh cong!" -Type 'SUCCESS'
            } else {
                # Reset về DHCP
                Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ResetServerAddresses
                Write-Status "Da reset ve DHCP" -Type 'SUCCESS'
            }
            
            # Xóa DNS cache
            ipconfig /flushdns | Out-Null
            Write-Status "Da xoa DNS cache" -Type 'INFO'
            
            Write-Host ""
            Pause
        } else {
            Write-Status "Lua chon khong hop le!" -Type 'WARNING'
            Pause
        }
    }
}
