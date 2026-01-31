# ============================================================
# clean-system.ps1 - CLEAN SYSTEM (FINAL VERSION)
# ============================================================
# Author: Minh Khai
# Version: 2.0.0
# Description: System cleaning module
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

function Invoke-TempClean {
    Write-Status "Dang don dep file tam thoi..." -Type 'INFO'
    Write-Host ""
    
    $paths = @(
        "$env:TEMP\*",
        "$env:LOCALAPPDATA\Temp\*", 
        "$env:WINDIR\Temp\*"
    )

    $totalFreed = 0
    $deletedCount = 0

    foreach ($path in $paths) {
        try {
            if (Test-Path $path) {
                $items = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Where-Object {
                    $_.Name -notlike "*.dll" -and
                    $_.Name -notlike "*.sys" -and
                    $_.Name -notlike "*.exe"
                }
                
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
        Stop-Service wuauserv, bits, cryptsvc -Force -ErrorAction SilentlyContinue 2>&1 | Out-Null
        Write-Host "   ✓ Da dung Windows Update services" -ForegroundColor Green
        
        $updatePaths = @(
            "$env:WINDIR\SoftwareDistribution\Download\*",
            "$env:WINDIR\SoftwareDistribution\DataStore\*"
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
        
        Start-Service bits, wuauserv, cryptsvc -ErrorAction SilentlyContinue 2>&1 | Out-Null
        Write-Host "   ✓ Da khoi dong lai Windows Update services" -ForegroundColor Green
        
        if ($freed -gt 0) {
            $freedMB = [math]::Round($freed / 1MB, 2)
            Write-Host ""
            Write-Status "Da giai phong: $freedMB MB" -Type 'SUCCESS'
        } else {
            Write-Status "Khong co cache de xoa" -Type 'INFO'
        }
    } catch {
        Write-Status "Co loi xay ra" -Type 'WARNING'
    }
    Write-Host ""
}

function Invoke-PrefetchClean {
    Write-Status "Dang xoa Prefetch data..." -Type 'INFO'
    Write-Host ""
    try {
        $prefetchPath = "$env:WINDIR\Prefetch"
        if (Test-Path $prefetchPath) {
            $items = Get-ChildItem "$prefetchPath\*" -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -ne "layout.ini"
            }
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
        $recycleBin.Items() | ForEach-Object { 
            try {
                $recycleBin.RemoveItem($_)
            } catch {}
        }
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
        ipconfig /flushdns 2>&1 | Out-Null
        Write-Host "   ✓ Da xoa DNS cache" -ForegroundColor Green
        Write-Host ""
        Write-Status "Da xoa DNS cache thanh cong!" -Type 'SUCCESS'
    } catch {
        Write-Status "Co loi xay ra khi xoa DNS cache" -Type 'WARNING'
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
            $usedPercent = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 2) } else { 0 }
            
            Write-Host "   Tong dung luong: $totalGB GB" -ForegroundColor White
            Write-Host "   Da su dung: $usedGB GB ($usedPercent%)" -ForegroundColor Yellow
            Write-Host "   Con trong: $freeGB GB" -ForegroundColor $(if ($freeGB -lt 10) { "Red" } else { "Green" })
            
            Write-Host "   [" -NoNewline -ForegroundColor Gray
            $filled = if ($usedPercent -gt 0) { [math]::Round($usedPercent / 5) } else { 0 }
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
        
        Write-Host ""
        Write-Host "  [TIEN ICH]" -ForegroundColor Cyan
        Write-Host "    11. Don dep TOAN BO (tat ca tren)" -ForegroundColor $global:UI_Colors.Highlight
        Write-Host "    12. Kiem tra dung luong o dia" -ForegroundColor $global:UI_Colors.Menu
        Write-Host ""
        Write-Host "    0. Quay lai Menu Chinh" -ForegroundColor $global:UI_Colors.Menu
        Write-Host ""
        Write-Host "-" * 55 -ForegroundColor $global:UI_Colors.Border
        Write-Host ""
        
        $choice = Read-Host "Lua chon (0-12): "
        
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
                Write-Status "Chuc nang dang phat trien..." -Type 'INFO'
                Pause
            }
            '7' { 
                Write-Status "Chuc nang dang phat trien..." -Type 'INFO'
                Pause
            }
            '8' { 
                Write-Status "Chuc nang dang phat trien..." -Type 'INFO'
                Pause
            }
            '9' { 
                Write-Status "Chuc nang dang phat trien..." -Type 'INFO'
                Pause
            }
            '10' { 
                Write-Status "Chuc nang dang phat trien..." -Type 'INFO'
                Pause
            }
            '11' {
                Show-Header -Title "DON DEP TOAN BO HE THONG"
                Write-Status "Bat dau don dep toan bo..." -Type 'INFO'
                Write-Host ""
                Write-Host " CANH BAO: Qua trinh nay co the mat nhieu thoi gian!" -ForegroundColor Red
                Write-Host ""
                
                $confirm = Read-Host "Nhap 'YES' de tiep tuc: "
                if ($confirm -ne "YES") {
                    Write-Status "Da huy!" -Type 'INFO'
                    Pause
                    continue
                }
                
                Invoke-TempClean
                Invoke-UpdateCacheClean
                Invoke-PrefetchClean
                Invoke-RecycleBinClean
                Invoke-DnsCacheClean
                
                Write-Host ""
                Write-Status "DA DON DEP TOAN BO HE THONG!" -Type 'SUCCESS'
                Write-Host ""
                
                Show-DiskUsageReport
                Pause
            }
            '12' {
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
