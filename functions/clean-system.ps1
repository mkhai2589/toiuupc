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
                Write-Host "   ✓ Đã xóa: $(Split-Path $path -Leaf)" -ForegroundColor Green
                Write-Host "      $count files ($([math]::Round($size/1MB,2)) MB)" -ForegroundColor Gray
            }
        }
    } catch { }
}

if ($totalFreed -gt 0) {
    $freedMB = [math]::Round($totalFreed / 1MB, 2)
    Write-Host ""
    Write-Status "Đã giải phóng: $freedMB MB từ $deletedCount files" -Type 'SUCCESS'
} else {
    Write-Status "Không tìm thấy file tạm để xóa" -Type 'INFO'
}
Write-Host ""
}

function Invoke-UpdateCacheClean {
Write-Status "Đang xóa Windows Update cache..." -Type 'INFO'
Write-Host ""
try {
    # Dừng các service liên quan
    Stop-Service wuauserv, bits, cryptsvc -Force -ErrorAction SilentlyContinue
    Write-Host "   ✓ Đã dừng Windows Update services" -ForegroundColor Green
    
    # Xóa cache
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
                Write-Host "   ✓ Đã xóa: $(Split-Path $path)" -ForegroundColor Green
            }
        }
    }
    
    # Khởi động lại services
    Start-Service bits, wuauserv, cryptsvc -ErrorAction SilentlyContinue
    Write-Host "   ✓ Đã khởi động lại Windows Update services" -ForegroundColor Green
    
    if ($freed -gt 0) {
        $freedMB = [math]::Round($freed / 1MB, 2)
        Write-Host ""
        Write-Status "Đã giải phóng: $freedMB MB" -Type 'SUCCESS'
    } else {
        Write-Status "Không có cache để xóa" -Type 'INFO'
    }
} catch {
    Write-Status "Có lỗi xảy ra: $_" -Type 'WARNING'
}
Write-Host ""
}

function Invoke-PrefetchClean {
Write-Status "Đang xóa Prefetch data..." -Type 'INFO'
Write-Host ""
try {
    $prefetchPath = "$env:WINDIR\Prefetch"
    if (Test-Path $prefetchPath) {
        $items = Get-ChildItem "$prefetchPath\*" -ErrorAction SilentlyContinue
        if ($items) {
            $size = ($items | Measure-Object Length -Sum).Sum
            $count = $items.Count
            Remove-Item "$prefetchPath\*" -Recurse -Force -ErrorAction SilentlyContinue
            
            Write-Host "   ✓ Đã xóa Prefetch data" -ForegroundColor Green
            Write-Host "      $count files ($([math]::Round($size/1MB,2)) MB)" -ForegroundColor Gray
            Write-Host ""
            Write-Status "Đã giải phóng: $([math]::Round($size/1MB,2)) MB" -Type 'SUCCESS'
        } else {
            Write-Status "Không có Prefetch data để xóa" -Type 'INFO'
        }
    }
} catch {
    Write-Status "Có lỗi xảy ra" -Type 'WARNING'
}
Write-Host ""
}

function Invoke-RecycleBinClean {
Write-Status "Đang xóa thùng rác..." -Type 'INFO'
Write-Host ""
try {
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.Namespace(0xA)
    $recycleBin.Items() | ForEach-Object { $recycleBin.RemoveItem($_) }
    Write-Host "   ✓ Đã xóa toàn bộ thùng rác" -ForegroundColor Green
    Write-Host ""
    Write-Status "Đã làm sạch thùng rác!" -Type 'SUCCESS'
} catch {
    Write-Status "Có lỗi xảy ra khi xóa thùng rác" -Type 'WARNING'
}
Write-Host ""
}

function Invoke-DnsCacheClean {
Write-Status "Đang xóa DNS cache..." -Type 'INFO'
Write-Host ""
try {
    ipconfig /flushdns | Out-Null
    Write-Host "   ✓ Đã xóa DNS cache" -ForegroundColor Green
    Write-Host ""
    Write-Status "Đã xóa DNS cache thành công!" -Type 'SUCCESS'
} catch {
    Write-Status "Có lỗi xảy ra khi xóa DNS cache" -Type 'WARNING'
}
Write-Host ""
}

============================================================
ADVANCED DEEP CLEAN FUNCTIONS
============================================================
function Invoke-WindowsOldClean {
Write-Status "Đang dọn dẹp Windows.old..." -Type 'INFO'
Write-Host ""
try {
    $windowsOldPath = "C:\Windows.old"
    if (Test-Path $windowsOldPath) {
        $items = Get-ChildItem $windowsOldPath -Recurse -ErrorAction SilentlyContinue
        if ($items) {
            $size = ($items | Measure-Object Length -Sum).Sum
            $sizeGB = [math]::Round($size / 1GB, 2)
            
            Write-Host "   Tìm thấy Windows.old folder" -ForegroundColor Yellow
            Write-Host "   Dung lượng: $sizeGB GB" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "   Bạn có chắc muốn xóa Windows.old?" -ForegroundColor Red
            Write-Host "   (Chỉ xóa nếu bạn không cần rollback Windows)" -ForegroundColor Red
            Write-Host ""
            
            $confirm = Read-Host "   Nhập 'YES' để xóa: "
            if ($confirm -eq "YES") {
                Remove-Item $windowsOldPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "   ✓ Đã xóa Windows.old" -ForegroundColor Green
                Write-Host ""
                Write-Status "Đã giải phóng: $sizeGB GB" -Type 'SUCCESS'
            } else {
                Write-Status "Đã bỏ qua Windows.old" -Type 'INFO'
            }
        } else {
            Write-Status "Không tìm thấy Windows.old" -Type 'INFO'
        }
    } else {
        Write-Status "Không tìm thấy Windows.old" -Type 'INFO'
    }
} catch {
    Write-Status "Cần quyền Administrator để xóa Windows.old" -Type 'WARNING'
}
Write-Host ""
}

function Invoke-SystemLogsClean {
Write-Status "Đang dọn dẹp System Logs..." -Type 'INFO'
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
                Write-Host "   ✓ Đã xóa log files: $(Split-Path $path)" -ForegroundColor Green
                Write-Host "      $count files cũ (>30 ngày)" -ForegroundColor Gray
            }
        }
    } catch { }
}

if ($totalFreed -gt 0) {
    $freedMB = [math]::Round($totalFreed / 1MB, 2)
    Write-Host ""
    Write-Status "Đã giải phóng: $freedMB MB từ $deletedCount log files" -Type 'SUCCESS'
} else {
    Write-Status "Không tìm thấy log files cũ để xóa" -Type 'INFO'
}
Write-Host ""
}

function Invoke-DeliveryOptimizationClean {
Write-Status "Đang xóa Delivery Optimization cache..." -Type 'INFO'
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
                Write-Host "   ✓ Đã xóa Delivery Optimization cache" -ForegroundColor Green
            }
        }
    }
    
    Start-Service DoSvc -ErrorAction SilentlyContinue
    
    if ($freed -gt 0) {
        $freedMB = [math]::Round($freed / 1MB, 2)
        Write-Host ""
        Write-Status "Đã giải phóng: $freedMB MB" -Type 'SUCCESS'
    } else {
        Write-Status "Không có cache để xóa" -Type 'INFO'
    }
} catch {
    Write-Status "Cần quyền Administrator" -Type 'WARNING'
}
Write-Host ""
}

function Invoke-StoreCacheClean {
Write-Status "Đang xóa Microsoft Store cache..." -Type 'INFO'
Write-Host ""
try {
    # Dừng Store services
    Get-Service *wsosvc*, *WSService* | Stop-Service -Force -ErrorAction SilentlyContinue
    
    # Xóa Store cache
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
    
    # Khởi động lại Store
    Get-Service *wsosvc*, *WSService* | Start-Service -ErrorAction SilentlyContinue
    
    if ($freed -gt 0) {
        $freedMB = [math]::Round($freed / 1MB, 2)
        Write-Host "   ✓ Đã xóa Microsoft Store cache" -ForegroundColor Green
        Write-Host ""
        Write-Status "Đã giải phóng: $freedMB MB" -Type 'SUCCESS'
    } else {
        Write-Status "Không có Store cache để xóa" -Type 'INFO'
    }
} catch {
    Write-Status "Có lỗi khi xóa Store cache" -Type 'WARNING'
}
Write-Host ""
}

function Invoke-ChromeEdgeCacheClean {
Write-Status "Đang xóa Browser Cache (Chrome/Edge)..." -Type 'INFO'
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
                Write-Host "   ✓ Đã xóa $browser cache" -ForegroundColor Green
            }
        }
    } catch { }
}

if ($totalFreed -gt 0) {
    $freedMB = [math]::Round($totalFreed / 1MB, 2)
    Write-Host ""
    Write-Status "Đã giải phóng: $freedMB MB từ browser cache" -Type 'SUCCESS'
} else {
    Write-Status "Không tìm thấy browser cache để xóa" -Type 'INFO'
}
Write-Host ""
}

function Invoke-UserTempClean {
Write-Status "Đang dọn dẹp User Temp files..." -Type 'INFO'
Write-Host ""
$userTempPaths = @()

# Lấy tất cả user profiles
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
    Write-Host "   ✓ Đã dọn dẹp temp files cho $userCount users" -ForegroundColor Green
    Write-Host ""
    Write-Status "Đã giải phóng: $freedMB MB" -Type 'SUCCESS'
} else {
    Write-Status "Không tìm thấy user temp files để xóa" -Type 'INFO'
}
Write-Host ""
}

function Show-DiskUsageReport {
Write-Status "BÁO CÁO DUNG LƯỢNG Ổ C:" -Type 'INFO'
Write-Host ""
try {
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    if ($disk) {
        $totalGB = [math]::Round($disk.Size / 1GB, 2)
        $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $usedGB = $totalGB - $freeGB
        $usedPercent = [math]::Round(($usedGB / $totalGB) * 100, 2)
        
        Write-Host "   Tổng dung lượng: $totalGB GB" -ForegroundColor White
        Write-Host "   Đã sử dụng: $usedGB GB ($usedPercent%)" -ForegroundColor Yellow
        Write-Host "   Còn trống: $freeGB GB" -ForegroundColor $(if ($freeGB -lt 10) { "Red" } else { "Green" })
        
        # Hiển thị thanh progress
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
            Write-Status "CẢNH BÁO: Ổ C sắp đầy!" -Type 'WARNING'
            Write-Host "   Hãy sử dụng chức năng Dọn dẹp Toàn bộ" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Status "Không thể lấy thông tin dung lượng" -Type 'WARNING'
}
Write-Host ""
}

============================================================
MAIN CLEAN SYSTEM MENU
============================================================
function Show-CleanSystem {
while ($true) {
Show-Header -Title "DỌN DẸP HỆ THỐNG CHUYÊN SÂU"
    # Hiển thị báo cáo dung lượng
    Show-DiskUsageReport
    
    Write-Host " CÁC CHỨC NĂNG DỌN DẸP:" -ForegroundColor $global:UI_Colors.Title
    Write-Host ""
    Write-Host "  [CƠ BẢN]" -ForegroundColor Cyan
    Write-Host "    1. File tạm thời (Temp)" -ForegroundColor $global:UI_Colors.Menu
    Write-Host "    2. Windows Update cache" -ForegroundColor $global:UI_Colors.Menu  
    Write-Host "    3. Prefetch data" -ForegroundColor $global:UI_Colors.Menu
    Write-Host "    4. Thùng rác (Recycle Bin)" -ForegroundColor $global:UI_Colors.Menu
    Write-Host "    5. DNS cache" -ForegroundColor $global:UI_Colors.Menu
    
    Write-Host ""
    Write-Host "  [NÂNG CAO]" -ForegroundColor Cyan
    Write-Host "    6. Windows.old (Lớn nhất)" -ForegroundColor $global:UI_Colors.Menu
    Write-Host "    7. System Logs (Log files)" -ForegroundColor $global:UI_Colors.Menu
    Write-Host "    8. Delivery Optimization cache" -ForegroundColor $global:UI_Colors.Menu
    Write-Host "    9. Microsoft Store cache" -ForegroundColor $global:UI_Colors.Menu
    Write-Host "    10. Browser Cache (Chrome/Edge)" -ForegroundColor $global:UI_Colors.Menu
    Write-Host "    11. User Temp files (tất cả users)" -ForegroundColor $global:UI_Colors.Menu
    
    Write-Host ""
    Write-Host "  [TIỆN ÍCH]" -ForegroundColor Cyan
    Write-Host "    12. Dọn dẹp TOÀN BỘ (tất cả trên)" -ForegroundColor $global:UI_Colors.Highlight
    Write-Host "    13. Kiểm tra dung lượng ổ đĩa" -ForegroundColor $global:UI_Colors.Menu
    Write-Host ""
    Write-Host "    0. Quay lại Menu Chính" -ForegroundColor $global:UI_Colors.Menu
    Write-Host ""
    Write-Host "─" * 55 -ForegroundColor $global:UI_Colors.Border
    Write-Host ""
    
    $choice = Read-Host "Lựa chọn (0-13): "
    
    switch ($choice) {
        '1' { 
            Show-Header -Title "DỌN DẸP FILE TẠM THỜI"
            Invoke-TempClean 
            Write-Status "Dọn dẹp hoàn tất!" -Type 'SUCCESS'
            Pause
        }
        '2' { 
            Show-Header -Title "DỌN DẸP UPDATE CACHE"
            Invoke-UpdateCacheClean 
            Write-Status "Dọn dẹp hoàn tất!" -Type 'SUCCESS'
            Pause
        }
        '3' { 
            Show-Header -Title "DỌN DẸP PREFETCH"
            Invoke-PrefetchClean 
            Write-Status "Dọn dẹp hoàn tất!" -Type 'SUCCESS'
            Pause
        }
        '4' { 
            Show-Header -Title "DỌN DẸP THÙNG RÁC"
            Invoke-RecycleBinClean 
            Write-Status "Dọn dẹp hoàn tất!" -Type 'SUCCESS'
            Pause
        }
        '5' { 
            Show-Header -Title "XÓA DNS CACHE"
            Invoke-DnsCacheClean 
            Write-Status "Dọn dẹp hoàn tất!" -Type 'SUCCESS'
            Pause
        }
        '6' { 
            Show-Header -Title "DỌN DẸP WINDOWS.OLD"
            Invoke-WindowsOldClean 
            Pause
        }
        '7' { 
            Show-Header -Title "DỌN DẸP SYSTEM LOGS"
            Invoke-SystemLogsClean 
            Write-Status "Dọn dẹp hoàn tất!" -Type 'SUCCESS'
            Pause
        }
        '8' { 
            Show-Header -Title "DỌN DẸP DELIVERY OPTIMIZATION"
            Invoke-DeliveryOptimizationClean 
            Write-Status "Dọn dẹp hoàn tất!" -Type 'SUCCESS'
            Pause
        }
        '9' { 
            Show-Header -Title "DỌN DẸP MICROSOFT STORE CACHE"
            Invoke-StoreCacheClean 
            Write-Status "Dọn dẹp hoàn tất!" -Type 'SUCCESS'
            Pause
        }
        '10' { 
            Show-Header -Title "DỌN DẸP BROWSER CACHE"
            Invoke-ChromeEdgeCacheClean 
            Write-Status "Dọn dẹp hoàn tất!" -Type 'SUCCESS'
            Pause
        }
        '11' { 
            Show-Header -Title "DỌN DẸP USER TEMP FILES"
            Invoke-UserTempClean 
            Write-Status "Dọn dẹp hoàn tất!" -Type 'SUCCESS'
            Pause
        }
        '12' {
            Show-Header -Title "DỌN DẸP TOÀN BỘ HỆ THỐNG"
            Write-Status "Bắt đầu dọn dẹp toàn bộ..." -Type 'INFO'
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
            Write-Status "ĐÃ DỌN DẸP TOÀN BỘ HỆ THỐNG!" -Type 'SUCCESS'
            Write-Host ""
            
            # Hiển thị báo cáo cuối cùng
            Show-DiskUsageReport
            Pause
        }
        '13' {
            Show-Header -Title "KIỂM TRA DUNG LƯỢNG Ổ ĐĨA"
            Show-DiskUsageReport
            Pause
        }
        '0' { return }
        default {
            Write-Status "Lựa chọn không hợp lệ!" -Type 'WARNING'
            Pause
        }
    }
}
}

============================================================
EXPORT FUNCTIONS
============================================================
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
