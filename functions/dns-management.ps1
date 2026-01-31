# ==========================================================
# dns-management.ps1 - DNS MANAGEMENT
# ==========================================================

function Get-ActiveNetworkAdapter {
    $adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
    if ($adapters) {
        return $adapters | Sort-Object InterfaceMetric | Select-Object -First 1
    }
    return $null
}

function Get-CurrentDnsInfo {
    $adapter = Get-ActiveNetworkAdapter
    if (-not $adapter) {
        return $null
    }
    
    $dnsInfo = @{
        AdapterName = $adapter.InterfaceAlias
        AdapterDescription = $adapter.InterfaceDescription
        IPv4 = @()
        IPv6 = @()
    }
    
    $currentDns = Get-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ErrorAction SilentlyContinue
    
    if ($currentDns -and $currentDns.ServerAddresses) {
        foreach ($addr in $currentDns.ServerAddresses) {
            if ($addr -match ':') {
                $dnsInfo.IPv6 += $addr
            } else {
                $dnsInfo.IPv4 += $addr
            }
        }
    }
    
    return $dnsInfo
}

function Show-DnsMenu {
    param($Config)
    
    if (-not $Config) {
        Write-Status "Khong co cau hinh DNS!" -Type 'ERROR'
        Pause
        return
    }
    
    while ($true) {
        $dnsInfo = Get-CurrentDnsInfo
        
        Show-Header -Title "QUAN LY DNS"
        
        if ($dnsInfo) {
            Write-Host " ADAPTER MANG HIEN TAI:" -ForegroundColor White
            Write-Host "   Ten: $($dnsInfo.AdapterName)" -ForegroundColor Gray
            Write-Host "   Mo ta: $($dnsInfo.AdapterDescription)" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host " DNS HIEN TAI:" -ForegroundColor White
            if ($dnsInfo.IPv4.Count -gt 0) {
                Write-Host "   IPv4: $($dnsInfo.IPv4 -join ', ')" -ForegroundColor Gray
            } else {
                Write-Host "   IPv4: DHCP (Tu dong)" -ForegroundColor Gray
            }
            
            if ($dnsInfo.IPv6.Count -gt 0) {
                Write-Host "   IPv6: $($dnsInfo.IPv6 -join ', ')" -ForegroundColor Gray
            } else {
                Write-Host "   IPv6: DHCP (Tu dong)" -ForegroundColor Gray
            }
        } else {
            Write-Host " KHONG TIM THAY ADAPTER MANG!" -ForegroundColor Red
            Write-Host "   Vui long kiem tra ket noi mang." -ForegroundColor Yellow
            Write-Host ""
        }
        
        Write-Host ""
        Write-Host ("-" * $global:UI_Width) -ForegroundColor DarkGray
        Write-Host ""
        
        Write-Host " CHON DNS SERVER:" -ForegroundColor White
        Write-Host ""
        
        $dnsNames = $Config.PSObject.Properties.Name
        $index = 1
        
        foreach ($dnsName in $dnsNames) {
            $dnsConfig = $Config.$dnsName
            $primary = if ($dnsConfig.Primary) { $dnsConfig.Primary } else { "DHCP" }
            
            if ($dnsName -eq "Default DHCP") {
                Write-Host "  [0] $dnsName - Reset ve DHCP" -ForegroundColor Gray
            } else {
                Write-Host "  [$index] $dnsName - $primary" -ForegroundColor Gray
                $index++
            }
        }
        
        Write-Host ""
        Write-Host "  [9] Quay lai Menu Chinh" -ForegroundColor Gray
        Write-Host ""
        
        $choice = Read-Host " Lua chon DNS (0-9): "
        
        if ($choice -eq "9") {
            return
        }
        
        if ($choice -eq "0") {
            $selectedDns = "Default DHCP"
            $dnsConfig = $Config.$selectedDns
        } else {
            $dnsIndex = [int]$choice
            if ($dnsIndex -ge 1 -and $dnsIndex -le ($dnsNames.Count - 1)) {
                $selectedDns = $dnsNames[$dnsIndex]
                $dnsConfig = $Config.$selectedDns
            } else {
                Write-Status "Lua chon khong hop le!" -Type 'WARNING'
                Pause
                continue
            }
        }
        
        Show-Header -Title "AP DUNG DNS"
        Write-Status "Dang ap dung DNS: $selectedDns" -Type 'INFO'
        
        if ($dnsConfig.Description) {
            Write-Host "   Mo ta: $($dnsConfig.Description)" -ForegroundColor Gray
        }
        Write-Host ""
        
        $adapter = Get-ActiveNetworkAdapter
        if (-not $adapter) {
            Write-Status "Khong tim thay adapter mang!" -Type 'ERROR'
            Pause
            continue
        }
        
        try {
            if ($selectedDns -eq "Default DHCP") {
                Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ResetServerAddresses
                Write-Host "   Da reset DNS ve DHCP" -ForegroundColor Green
            } else {
                $servers = @()
                if ($dnsConfig.Primary)   { $servers += $dnsConfig.Primary }
                if ($dnsConfig.Secondary) { $servers += $dnsConfig.Secondary }
                
                Write-Host "   DNS servers se duoc ap dung:" -ForegroundColor Gray
                foreach ($server in $servers) {
                    Write-Host "     - $server" -ForegroundColor Gray
                }
                
                Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ServerAddresses $servers
                Write-Host "   Da ap dung DNS thanh cong!" -ForegroundColor Green
            }
            
            ipconfig /flushdns 2>&1 | Out-Null
            Write-Host "   Da xoa DNS cache" -ForegroundColor Green
            
        } catch {
            Write-Status "Loi khi ap dung DNS!" -Type 'ERROR'
            Write-Host "   Vui long kiem tra quyen Administrator" -ForegroundColor Red
        }
        
        Write-Host ""
        Pause
    }
}
