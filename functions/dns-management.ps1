# ==========================================================
# dns-management.ps1 - DNS MANAGEMENT (FIXED VERSION)
# ==========================================================
# Author: Minh Khai
# Version: 2.0.0
# Description: DNS management module
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
    
    if (-not $Config) {
        Write-Status "Khong co cau hinh DNS!" -Type 'ERROR'
        Pause
        return
    }
    
    $adapter = Get-ActiveNetworkAdapter
    if (-not $adapter) {
        Write-Status "Khong tim thay adapter mang dang hoat dong!" -Type 'ERROR'
        Pause
        return
    }
    
    while ($true) {
        # Get current DNS - HIỆN CẢ IPV4 VÀ IPV6
        $currentDns = Get-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ErrorAction SilentlyContinue
        
        $currentIPv4 = "DHCP"
        $currentIPv6 = "DHCP"
        
        if ($currentDns -and $currentDns.ServerAddresses) {
            $ipv4Servers = @()
            $ipv6Servers = @()
            
            foreach ($addr in $currentDns.ServerAddresses) {
                if ($addr.Contains(':')) {
                    $ipv6Servers += $addr
                } else {
                    $ipv4Servers += $addr
                }
            }
            
            if ($ipv4Servers.Count -gt 0) {
                $currentIPv4 = $ipv4Servers -join ', '
            }
            
            if ($ipv6Servers.Count -gt 0) {
                $currentIPv6 = $ipv6Servers -join ', '
            }
        }
        
        Show-Header -Title "QUAN LY DNS"
        Write-Host " Thong tin adapter mang:" -ForegroundColor White
        Write-Host "   Adapter: $($adapter.InterfaceAlias)" -ForegroundColor $global:UI_Colors.Label
        Write-Host "   Ten: $($adapter.Name)" -ForegroundColor $global:UI_Colors.Label
        Write-Host "   MAC: $($adapter.MacAddress)" -ForegroundColor $global:UI_Colors.Label
        Write-Host ""
        
        Write-Host " DNS HIEN TAI:" -ForegroundColor White
        Write-Host "   IPv4: $currentIPv4" -ForegroundColor $global:UI_Colors.Value
        Write-Host "   IPv6: $currentIPv6" -ForegroundColor $global:UI_Colors.Value
        Write-Host ""
        Write-Host "--------------------------------------------------" -ForegroundColor $global:UI_Colors.Border
        Write-Host ""
        
        # Build menu tu DNS config
        $menuItems = @()
        $index = 1
        
        foreach ($dnsName in ($Config.PSObject.Properties.Name)) {
            $dnsConfig = $Config.$dnsName
            $primary = if ($dnsConfig.Primary) { $dnsConfig.Primary } else { "DHCP" }
            
            $displayText = "$($dnsName) - $primary"
            
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
            Write-Host "   Mo ta: $($dnsConfig.Description)" -ForegroundColor $global:UI_Colors.Label
            Write-Host ""
            
            # Thu thap tat ca dia chi DNS
            $servers = @()
            if ($dnsConfig.Primary)   { $servers += $dnsConfig.Primary }
            if ($dnsConfig.Secondary) { $servers += $dnsConfig.Secondary }
            
            Write-Host " DNS servers se duoc ap dung:" -ForegroundColor $global:UI_Colors.Label
            foreach ($server in $servers) {
                Write-Host "   - $server" -ForegroundColor $global:UI_Colors.Value
            }
            Write-Host ""
            
            # Ap dung DNS
            try {
                if ($servers.Count -gt 0) {
                    Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ServerAddresses $servers -ErrorAction Stop
                    Write-Status "Da ap dung DNS thanh cong!" -Type 'SUCCESS'
                } else {
                    # Reset ve DHCP
                    Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ResetServerAddresses -ErrorAction Stop
                    Write-Status "Da reset ve DHCP" -Type 'SUCCESS'
                }
                
                # Xoa DNS cache
                ipconfig /flushdns 2>&1 | Out-Null
                Write-Status "Da xoa DNS cache" -Type 'INFO'
                
            } catch {
                Write-Status "Loi khi ap dung DNS: $_" -Type 'ERROR'
                Write-Host "   Vui long kiem tra quyen Administrator" -ForegroundColor $global:UI_Colors.Warning
            }
            
            Write-Host ""
            Pause
        } else {
            Write-Status "Lua chon khong hop le!" -Type 'WARNING'
            Pause
        }
    }
}
