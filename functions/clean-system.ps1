# ============================================================
# clean-system.ps1 - CLEAN SYSTEM (FIXED DISPLAY)
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

function Invoke-TempClean {
    Write-Status "Dang don dep file tam thoi..." -Type 'INFO'
    Write-Host ""
    
    $paths = @(
        "$env:TEMP\*",
        "$env:LOCALAPPDATA\Temp\*", 
        "$env:WINDIR\Temp\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCookies\*",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
        "$env:APPDATA\Mozilla\Firefox\Profiles\*.default-release\cache2\entries\*"
    )

    $totalFreed = 0
    $deletedCount = 0

    foreach ($path in $paths) {
        try {
            if (Test-Path $path) {
                $items = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue
                if ($items) {
                    $size = ($items | Measure-Object Length -Sum).Sum
                    $count = $items.Count
                    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                    $totalFreed += $size
                    $deletedCount += $count
                    Write-Host "   ✓ Da xoa: $(Split-Path $path -Leaf)" -ForegroundColor Green
                    Write-Host "      $count files ($([math]::Round($size/1MB,2)) MB)" -ForegroundColor Gray
                }
            }
        } catch { }
    }

    if ($totalFreed -gt 0) {
        $freedMB = [math]::Round($totalFreed / 1MB, 2)
        Write-Host ""
        Write-Status "Da giai phong: $freedMB MB tu $deletedCount files" -Type 'SUCCESS'
    } else {
        Write-Status "Khong tim thay file tam de xoa" -Type 'INFO'
    }
    Write-Host ""
}

function Invoke-UpdateCacheClean {
    Write-Status "Dang xoa Windows Update cache..." -Type 'INFO'
    Write-Host ""
    try {
        # Dung cac service lien quan
        Stop-Service wuauserv, bits, cryptsvc -Force -ErrorAction SilentlyContinue
        Write-Host "   ✓ Da dung Windows Update services" -ForegroundColor Green
        
        # Xoa cache
        $updatePaths = @(
            "$env:WINDIR\SoftwareDistribution\Download\*",
            "$env:WINDIR\SoftwareDistribution\DataStore\*",
            "$env:WINDIR\SoftwareDistribution\SLS\*"
        )
        
        $freed = 0
        foreach ($path in $updatePaths) {
            if (Test-Path $path) {
                $items = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue
                if ($items) {
                    $size = ($items | Measure-Object Length -Sum).Sum
                    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                    $freed += $size
                    Write-Host "   ✓ Da xoa: $(Split-Path $path)" -ForegroundColor Green
                }
            }
        }
        
        # Khoi dong lai services
        Start-Service bits, wuauserv, cryptsvc -ErrorAction SilentlyContinue
        Write-Host "   ✓ Da khoi dong lai Windows Update services" -ForegroundColor Green
        
        if ($freed -gt 0) {
            $freedMB = [math]::Round($freed / 1MB, 2)
            Write-Host ""
            Write-Status "Da giai phong: $freedMB MB" -Type 'SUCCESS'
        } else {
            Write-Status "Khong co cache de xoa" -Type 'INFO'
        }
    } catch {
        Write-Status "Co loi xay ra: $_" -Type 'WARNING'
    }
    Write-Host ""
}

function Invoke-PrefetchClean {
    Write-Status "Dang xoa Prefetch data..." -Type 'INFO'
    Write-Host ""
    try {
        $prefetchPath = "$env:WINDIR\Prefetch"
        if (Test-Path $prefetchPath) {
            $items = Get-ChildItem "$prefetchPath\*" -ErrorAction SilentlyContinue
            if ($items) {
                $size = ($items | Measure-Object Length -Sum).Sum
                $count = $items.Count
                Remove-Item "$prefetchPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                
                Write-Host "   ✓ Da xoa Prefetch data" -ForegroundColor Green
                Write-Host "      $count files ($([math]::Round($size/1MB,2)) MB)" -ForegroundColor Gray
                Write-Host ""
                Write-Status "Da giai phong: $([math]::Round($size/1MB,2)) MB" -Type 'SUCCESS'
            } else {
                Write-Status "Khong co Prefetch data de xoa" -Type 'INFO'
            }
        }
    } catch {
        Write-Status "Co loi xay ra" -Type 'WARNING'
    }
    Write-Host ""
}

function Invoke-RecycleBinClean {
    Write-Status "Dang xoa thung rac..." -Type 'INFO'
    Write-Host ""
    try {
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.Namespace(0xA)
        $recycleBin.Items() | ForEach-Object { $recycleBin.RemoveItem($_) }
        Write-Host "   ✓ Da xoa toan bo thung rac" -ForegroundColor Green
        Write-Host ""
        Write-Status "Da lam sach thung rac!" -Type 'SUCCESS'
    } catch {
        Write-Status "Co loi xay ra khi xoa thung rac" -Type 'WARNING'
    }
    Write-Host ""
}

function Invoke-DnsCacheClean {
    Write-Status "Dang xoa DNS cache..." -Type 'INFO'
    Write-Host ""
    try {
        ipconfig /flushdns | Out-Null
        Write-Host "   ✓ Da xoa DNS cache" -ForegroundColor Green
        Write-Host ""
        Write-Status "Da xoa DNS cache thanh cong!" -Type 'SUCCESS'
    } catch {
        Write-Status "Co loi xay ra khi xoa DNS cache" -Type 'WARNING'
    }
    Write-Host ""
}

# ============================================================
# ADVANCED DEEP CLEAN FUNCTIONS
# ============================================================
function Invoke-WindowsOldClean {
    Write-Status "Dang don dep Windows.old..." -Type 'INFO'
    Write-Host ""
    try {
        $windowsOldPath = "C:\Windows.old"
        if (Test-Path $windowsOldPath) {
            $items = Get-ChildItem $windowsOldPath -Recurse -ErrorAction SilentlyContinue
            if ($items) {
                $size = ($items | Measure-Object Length -Sum).Sum
                $sizeGB = [math]::Round($size / 1GB, 2)
                
                Write-Host "   Tim thay Windows.old folder" -ForegroundColor Yellow
                Write-Host "   Dung luong: $sizeGB GB" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "   Ban co chac muon xoa Windows.old?" -ForegroundColor Red
                Write-Host "   (Chi xoa neu ban khong can rollback Windows)" -ForegroundColor Red
                Write-Host ""
                
                $confirm = Read-Host "   Nhap 'YES' de xoa: "
                if ($confirm -eq "YES") {
                    Remove-Item $windowsOldPath -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "   ✓ Da xoa Windows.old" -ForegroundColor Green
                    Write-Host ""
                    Write-Status "Da giai phong: $sizeGB GB" -Type 'SUCCESS'
                } else {
                    Write-Status "Da bo qua Windows.old" -Type 'INFO'
                }
            } else {
                Write-Status "Khong tim thay Windows.old" -Type 'INFO'
            }
        } else {
            Write-Status "Khong tim thay Windows.old" -Type 'INFO'
        }
    } catch {
        Write-Status "Can quyen Administrator de xoa Windows.old" -Type 'WARNING'
    }
    Write-Host ""
}

function Invoke-SystemLogsClean {
    Write-Status "Dang don dep System Logs..." -Type 'INFO'
    Write-Host ""
    $logPaths = @(
        "$env:WINDIR\Logs\*",
        "$env:WINDIR\System32\LogFiles\*",
        "$env:WINDIR\debug\*",
        "$env:WINDIR\Minidump\*"
    )

    $totalFreed = 0
    $deletedCount = 0

    foreach ($path in $logPaths) {
        try {
            if (Test-Path $path) {
                $items = Get-ChildItem $path -ErrorAction SilentlyContinue | Where-Object {
                    $_.LastWriteTime -lt (Get-Date).AddDays(-30) -and $_.Name -notlike "*.exe"
                }
                
                if ($items) {
                    $size = ($items | Measure-Object Length -Sum).Sum
                    $count = $items.Count
                    Remove-Item $items.FullName -Force -ErrorAction SilentlyContinue
                    $totalFreed += $size
                    $deletedCount += $count
                    Write-Host "   ✓ Da xoa log files: $(Split-Path $path)" -ForegroundColor Green
                    Write-Host "      $count files cu (>30 ngay)" -ForegroundColor Gray
                }
            }
        } catch { }
    }

    if ($totalFreed -gt 0) {
        $freedMB = [math]::Round($totalFreed / 1MB, 2)
        Write-Host ""
        Write-Status "Da giai phong: $freedMB MB tu $deletedCount log files" -Type 'SUCCESS'
    } else {
        Write-Status "Khong tim thay log files cu de xoa" -Type 'INFO'
    }
    Write-Host ""
}

function Invoke-DeliveryOptimizationClean {
    Write-Status "Dang xoa Delivery Optimization cache..." -Type 'INFO'
    Write-Host ""
    try {
        Stop-Service DoSvc -Force -ErrorAction SilentlyContinue
        
        $doPaths = @(
            "$env:WINDIR\ServiceProfiles\LocalService\AppData\Local\Microsoft\Delivery Optimization\Logs\*",
            "$env:WINDIR\ServiceProfiles\LocalService\AppData\Local\Microsoft\Delivery Optimization\Cache\*",
            "$env:LOCALAPPDATA\Microsoft\Windows\Delivery Optimization\Cache\*"
        )
        
        $freed = 0
        foreach ($path in $doPaths) {
            if (Test-Path $path) {
                $items = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue
                if ($items) {
                    $size = ($items | Measure-Object Length -Sum).Sum
                    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                    $freed += $size
                    Write-Host "   ✓ Da xoa Delivery Optimization cache" -ForegroundColor Green
                }
            }
        }
        
        Start-Service DoSvc -ErrorAction SilentlyContinue
        
        if ($freed -gt 0) {
            $freedMB = [math]::Round($freed / 1MB, 2)
            Write-Host ""
            Write-Status "Da giai phong: $freedMB MB" -Type 'SUCCESS'
        } else {
            Write-Status "Khong co cache de xoa" -Type 'INFO'
        }
    } catch {
        Write-Status "Can quyen Administrator" -Type 'WARNING'
    }
    Write-Host ""
}

function Invoke-StoreCacheClean {
    Write-Status "Dang xoa Microsoft Store cache..." -Type 'INFO'
    Write-Host ""
    try {
        # Dung Store services
        Get-Service *wsosvc*, *WSService* | Stop-Service -Force -ErrorAction SilentlyContinue
        
        # Xoa Store cache
        $storePaths = @(
            "$env:LOCALAPPDATA\Packages\Microsoft.WindowsStore_*\LocalCache\*",
            "$env:LOCALAPPDATA\Packages\Microsoft.WindowsStore_*\LocalState\Cache\*",
            "$env:LOCALAPPDATA\Packages\Microsoft.WindowsStore_*\AC\INetCache\*",
            "$env:LOCALAPPDATA\Packages\Microsoft.WindowsStore_*\AC\INetCookies\*"
        )
        
        $freed = 0
        foreach ($path in $storePaths) {
            $matchedPaths = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
            foreach ($matched in $matchedPaths) {
                if (Test-Path $matched) {
                    $items = Get-ChildItem $matched -Recurse -ErrorAction SilentlyContinue
                    if ($items) {
                        $size = ($items | Measure-Object Length -Sum).Sum
                        Remove-Item $matched -Recurse -Force -ErrorAction SilentlyContinue
                        $freed += $size
                    }
                }
            }
        }
        
        # Khoi dong lai Store
        Get-Service *wsosvc*, *WSService* | Start-Service -ErrorAction SilentlyContinue
        
        if ($freed -gt 0) {
            $freedMB = [math]::Round($freed / 1MB, 2)
            Write-Host "   ✓ Da xoa Microsoft Store cache" -ForegroundColor Green
            Write-Host ""
            Write-Status "Da giai phong: $freedMB MB" -Type 'SUCCESS'
        } else {
            Write-Status "Khong co Store cache de xoa" -Type 'INFO'
        }
    } catch {
        Write-Status "Co loi khi xoa Store cache" -Type 'WARNING'
    }
    Write-Host ""
}

function Invoke-ChromeEdgeCacheClean {
    Write-Status "Dang xoa Browser Cache (Chrome/Edge)..." -Type 'INFO'
    Write-Host ""
    $browserPaths = @()

    # Chrome paths
    $chromePaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache2\entries\*",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache\*",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Service Worker\CacheStorage\*",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Session Storage\*"
    )

    # Edge paths
    $edgePaths = @(
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache2\entries\*",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache\*",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Service Worker\CacheStorage\*"
    )

    $browserPaths = $chromePaths + $edgePaths
    $totalFreed = 0

    foreach ($path in $browserPaths) {
        try {
            if (Test-Path $path) {
                $items = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue
                if ($items) {
                    $size = ($items | Measure-Object Length -Sum).Sum
                    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                    $totalFreed += $size
                    
                    $browser = if ($path -like "*Chrome*") { "Chrome" } else { "Edge" }
                    Write-Host "   ✓ Da xoa $browser cache" -ForegroundColor Green
                }
            }
        } catch { }
    }

    if ($totalFreed -gt 0) {
        $freedMB = [math]::Round($totalFreed / 1MB, 2)
        Write-Host ""
        Write-Status "Da giai phong: $freedMB MB tu browser cache" -Type 'SUCCESS'
    } else {
        Write-Status "Khong tim thay browser cache de xoa" -Type 'INFO'
    }
    Write-Host ""
}

function Invoke-UserTempClean {
    Write-Status "Dang don dep User Temp files..." -Type 'INFO'
    Write-Host ""
    $userTempPaths = @()

    # Lay tat ca user profiles
    $users = Get-ChildItem "C:\Users" -Directory | Where-Object { $_.Name -notlike "*Public*" -and $_.Name -notlike "*Default*" }

    foreach ($user in $users) {
        $userTempPaths += @(
            "C:\Users\$($user.Name)\AppData\Local\Temp\*",
            "C:\Users\$($user.Name)\AppData\Local\Microsoft\Windows\INetCache\*",
            "C:\Users\$($user.Name)\AppData\Local\Microsoft\Windows\INetCookies\*"
        )
    }

    $totalFreed = 0
    $userCount = 0

    foreach ($path in $userTempPaths) {
        try {
            if (Test-Path $path) {
                $items = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue
                if ($items) {
                    $size = ($items | Measure-Object Length -Sum).Sum
                    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                    $totalFreed += $size
                    $userCount++
                }
            }
        } catch { }
    }

    if ($totalFreed -gt 0) {
        $freedMB = [math]::Round($totalFreed / 1MB, 2)
        Write-Host "   ✓ Da don dep temp files cho $userCount users" -ForegroundColor Green
        Write-Host ""
        Write-Status "Da giai phong: $freedMB MB" -Type 'SUCCESS'
    } else {
        Write-Status "Khong tim thay user temp files de xoa" -Type 'INFO'
    }
    Write-Host ""
}

function Show-DiskUsageReport {
    Write-Status "BAO CAO DUNG LUONG O C:" -Type 'INFO'
    Write-Host ""
    try {
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
        if ($disk) {
            $totalGB = [math]::Round($disk.Size / 1GB, 2)
            $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            $usedGB = $totalGB - $freeGB
            $usedPercent = [math]::Round(($usedGB / $totalGB) * 100, 2)
            
            Write-Host "   Tong dung luong: $totalGB GB" -ForegroundColor White
            Write-Host "   Da su dung: $usedGB GB ($usedPercent%)" -ForegroundColor Yellow
            Write-Host "   Con trong: $freeGB GB" -ForegroundColor $(if ($freeGB -lt 10) { "Red" } else { "Green" })
            
            # Hien thi thanh progress
            Write-Host "   [" -NoNewline -ForegroundColor Gray
            $filled = [math]::Round($usedPercent / 5)
            for ($i = 1; $i -le 20; $i++) {
                if ($i -le $filled) {
                    Write-Host "█" -NoNewline -ForegroundColor $(if ($usedPercent -gt 90) { "Red" } elseif ($usedPercent -gt 70) { "Yellow" } else { "Green" })
                } else {
                    Write-Host "░" -NoNewline -ForegroundColor Gray
                }
            }
            Write-Host "]" -ForegroundColor Gray
            
            if ($freeGB -lt 5) {
                Write-Host ""
                Write-Status "CANH BAO: O C sap day!" -Type 'WARNING'
                Write-Host "   Hay su dung chuc nang Don dep Toan bo" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Status "Khong the lay thong tin dung luong" -Type 'WARNING'
    }
    Write-Host ""
}

# ============================================================
# MAIN CLEAN SYSTEM MENU
# ============================================================
function Show-CleanSystem {
    while ($true) {
        Show-Header -Title "DON DEP HE THONG CHUYEN SAU"
        
        # Hien thi bao cao dung luong
        Show-DiskUsageReport
        
        Write-Host " CAC CHUC NANG DON DEP:" -ForegroundColor $global:UI_Colors.Title
        Write-Host ""
        Write-Host "  [CO BAN]" -ForegroundColor Cyan
        Write-Host "    1. File tam thoi (Temp)" -ForegroundColor $global:UI_Colors.Menu
        Write-Host "    2. Windows Update cache" -ForegroundColor $global:UI_Colors.Menu  
        Write-Host "    3. Prefetch data" -ForegroundColor $global:UI_Colors.Menu
        Write-Host "    4. Thung rac (Recycle Bin)" -ForegroundColor $global:UI_Colors.Menu
        Write-Host "    5. DNS cache" -ForegroundColor $global:UI_Colors.Menu
        
        Write-Host ""
        Write-Host "  [NANG CAO]" -ForegroundColor Cyan
        Write-Host "    6. Windows.old (Lon nhat)" -ForegroundColor $global:UI_Colors.Menu
        Write-Host "    7. System Logs (Log files)" -ForegroundColor $global:UI_Colors.Menu
        Write-Host "    8. Delivery Optimization cache" -ForegroundColor $global:UI_Colors.Menu
        Write-Host "    9. Microsoft Store cache" -ForegroundColor $global:UI_Colors.Menu
        Write-Host "    10. Browser Cache (Chrome/Edge)" -ForegroundColor $global:UI_Colors.Menu
        Write-Host "    11. User Temp files (tat ca users)" -ForegroundColor $global:UI_Colors.Menu
        
        Write-Host ""
        Write-Host "  [TIEN ICH]" -ForegroundColor Cyan
        Write-Host "    12. Don dep TOAN BO (tat ca tren)" -ForegroundColor $global:UI_Colors.Highlight
        Write-Host "    13. Kiem tra dung luong o dia" -ForegroundColor $global:UI_Colors.Menu
        Write-Host ""
        Write-Host "    0. Quay lai Menu Chinh" -ForegroundColor $global:UI_Colors.Menu
        Write-Host ""
        Write-Host "─" * 55 -ForegroundColor $global:UI_Colors.Border
        Write-Host ""
        
        $choice = Read-Host "Lua chon (0-13): "
        
        switch ($choice) {
            '1' { 
                Show-Header -Title "DON DEP FILE TAM THOI"
                Invoke-TempClean 
                Write-Status "Don dep hoan tat!" -Type 'SUCCESS'
                Pause
            }
            '2' { 
                Show-Header -Title "DON DEP UPDATE CACHE"
                Invoke-UpdateCacheClean 
                Write-Status "Don dep hoan tat!" -Type 'SUCCESS'
                Pause
            }
            '3' { 
                Show-Header -Title "DON DEP PREFETCH"
                Invoke-PrefetchClean 
                Write-Status "Don dep hoan tat!" -Type 'SUCCESS'
                Pause
            }
            '4' { 
                Show-Header -Title "DON DEP THUNG RAC"
                Invoke-RecycleBinClean 
                Write-Status "Don dep hoan tat!" -Type 'SUCCESS'
                Pause
            }
            '5' { 
                Show-Header -Title "XOA DNS CACHE"
                Invoke-DnsCacheClean 
                Write-Status "Don dep hoan tat!" -Type 'SUCCESS'
                Pause
            }
            '6' { 
                Show-Header -Title "DON DEP WINDOWS.OLD"
                Invoke-WindowsOldClean 
                Pause
            }
            '7' { 
                Show-Header -Title "DON DEP SYSTEM LOGS"
                Invoke-SystemLogsClean 
                Write-Status "Don dep hoan tat!" -Type 'SUCCESS'
                Pause
            }
            '8' { 
                Show-Header -Title "DON DEP DELIVERY OPTIMIZATION"
                Invoke-DeliveryOptimizationClean 
                Write-Status "Don dep hoan tat!" -Type 'SUCCESS'
                Pause
            }
            '9' { 
                Show-Header -Title "DON DEP MICROSOFT STORE CACHE"
                Invoke-StoreCacheClean 
                Write-Status "Don dep hoan tat!" -Type 'SUCCESS'
                Pause
            }
            '10' { 
                Show-Header -Title "DON DEP BROWSER CACHE"
                Invoke-ChromeEdgeCacheClean 
                Write-Status "Don dep hoan tat!" -Type 'SUCCESS'
                Pause
            }
            '11' { 
                Show-Header -Title "DON DEP USER TEMP FILES"
                Invoke-UserTempClean 
                Write-Status "Don dep hoan tat!" -Type 'SUCCESS'
                Pause
            }
            '12' {
                Show-Header -Title "DON DEP TOAN BO HE THONG"
                Write-Status "Bat dau don dep toan bo..." -Type 'INFO'
                Write-Host ""
                
                Invoke-TempClean
                Invoke-UpdateCacheClean
                Invoke-PrefetchClean
                Invoke-RecycleBinClean
                Invoke-DnsCacheClean
                Invoke-SystemLogsClean
                Invoke-DeliveryOptimizationClean
                Invoke-StoreCacheClean
                Invoke-ChromeEdgeCacheClean
                Invoke-UserTempClean
                
                Write-Host ""
                Write-Status "DA DON DEP TOAN BO HE THONG!" -Type 'SUCCESS'
                Write-Host ""
                
                # Hien thi bao cao cuoi cung
                Show-DiskUsageReport
                Pause
            }
            '13' {
                Show-Header -Title "KIEM TRA DUNG LUONG O DIA"
                Show-DiskUsageReport
                Pause
            }
            '0' { return }
            default {
                Write-Status "Lua chon khong hop le!" -Type 'WARNING'
                Pause
            }
        }
    }
}

# ============================================================
# EXPORT FUNCTIONS
# ============================================================
Export-ModuleMember -Function @(
    'Show-CleanSystem',
    'Invoke-TempClean',
    'Invoke-UpdateCacheClean',
    'Invoke-PrefetchClean',
    'Invoke-RecycleBinClean',
    'Invoke-DnsCacheClean',
    'Invoke-WindowsOldClean',
    'Invoke-SystemLogsClean',
    'Invoke-DeliveryOptimizationClean',
    'Invoke-StoreCacheClean',
    'Invoke-ChromeEdgeCacheClean',
    'Invoke-UserTempClean',
    'Show-DiskUsageReport'
)
