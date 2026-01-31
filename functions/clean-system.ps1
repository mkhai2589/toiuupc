# ============================================================
# clean-system.ps1 - CLEAN SYSTEM
# ============================================================

function Invoke-TempClean {
    Write-Status "Dang don dep file tam thoi..." -Type 'INFO'
    
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
                    Write-Host "   Da xoa: $(Split-Path $path -Leaf)" -ForegroundColor Green
                }
            }
        } catch { }
    }

    if ($totalFreed -gt 0) {
        $freedMB = [math]::Round($totalFreed / 1MB, 2)
        Write-Status "Da giai phong: $freedMB MB tu $deletedCount files" -Type 'SUCCESS'
    } else {
        Write-Status "Khong tim thay file tam de xoa" -Type 'INFO'
    }
}

function Invoke-UpdateCacheClean {
    Write-Status "Dang xoa Windows Update cache..." -Type 'INFO'
    
    try {
        Stop-Service wuauserv, bits, cryptsvc -Force -ErrorAction SilentlyContinue
        Write-Host "   Da dung Windows Update services" -ForegroundColor Green
        
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
                    Write-Host "   Da xoa: $(Split-Path $path)" -ForegroundColor Green
                }
            }
        }
        
        Start-Service bits, wuauserv, cryptsvc -ErrorAction SilentlyContinue
        Write-Host "   Da khoi dong lai Windows Update services" -ForegroundColor Green
        
        if ($freed -gt 0) {
            $freedMB = [math]::Round($freed / 1MB, 2)
            Write-Status "Da giai phong: $freedMB MB" -Type 'SUCCESS'
        } else {
            Write-Status "Khong co cache de xoa" -Type 'INFO'
        }
    } catch {
        Write-Status "Co loi xay ra" -Type 'WARNING'
    }
}

function Invoke-PrefetchClean {
    Write-Status "Dang xoa Prefetch data..." -Type 'INFO'
    
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
                
                Write-Host "   Da xoa Prefetch data" -ForegroundColor Green
                Write-Status "Da giai phong: $([math]::Round($size/1MB,2)) MB" -Type 'SUCCESS'
            } else {
                Write-Status "Khong co Prefetch data de xoa" -Type 'INFO'
            }
        }
    } catch {
        Write-Status "Co loi xay ra" -Type 'WARNING'
    }
}

function Invoke-RecycleBinClean {
    Write-Status "Dang xoa thung rac..." -Type 'INFO'
    
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Host "   Da xoa toan bo thung rac" -ForegroundColor Green
        Write-Status "Da lam sach thung rac!" -Type 'SUCCESS'
    } catch {
        Write-Status "Co loi xay ra khi xoa thung rac" -Type 'WARNING'
    }
}

function Invoke-DnsCacheClean {
    Write-Status "Dang xoa DNS cache..." -Type 'INFO'
    
    try {
        ipconfig /flushdns 2>&1 | Out-Null
        Write-Host "   Da xoa DNS cache" -ForegroundColor Green
        Write-Status "Da xoa DNS cache thanh cong!" -Type 'SUCCESS'
    } catch {
        Write-Status "Co loi xay ra khi xoa DNS cache" -Type 'WARNING'
    }
}

function Show-DiskUsageReport {
    Write-Status "BAO CAO DUNG LUONG O C:" -Type 'INFO'
    
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
            }
        }
    } catch {
        Write-Status "Khong the lay thong tin dung luong" -Type 'WARNING'
    }
}

function Show-CleanSystem {
    while ($true) {
        Show-Header -Title "DON DEP HE THONG"
        
        Write-Host " CAC CHUC NANG DON DEP:" -ForegroundColor White
        Write-Host ""
        Write-Host "  [1] File tam thoi (Temp)" -ForegroundColor Gray
        Write-Host "  [2] Windows Update cache" -ForegroundColor Gray
        Write-Host "  [3] Prefetch data" -ForegroundColor Gray
        Write-Host "  [4] Thung rac (Recycle Bin)" -ForegroundColor Gray
        Write-Host "  [5] DNS cache" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [6] Don dep TOAN BO (tat ca tren)" -ForegroundColor Magenta
        Write-Host "  [7] Kiem tra dung luong o dia" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [0] Quay lai Menu Chinh" -ForegroundColor Gray
        Write-Host ""
        
        $choice = Read-Host " Lua chon (0-7): "
        
        switch ($choice) {
            '1' { 
                Show-Header -Title "DON DEP FILE TAM THOI"
                Invoke-TempClean 
                Pause
            }
            '2' { 
                Show-Header -Title "DON DEP UPDATE CACHE"
                Invoke-UpdateCacheClean 
                Pause
            }
            '3' { 
                Show-Header -Title "DON DEP PREFETCH"
                Invoke-PrefetchClean 
                Pause
            }
            '4' { 
                Show-Header -Title "DON DEP THUNG RAC"
                Invoke-RecycleBinClean 
                Pause
            }
            '5' { 
                Show-Header -Title "XOA DNS CACHE"
                Invoke-DnsCacheClean 
                Pause
            }
            '6' {
                Show-Header -Title "DON DEP TOAN BO HE THONG"
                Write-Status "Bat dau don dep toan bo..." -Type 'INFO'
                Write-Host " CANH BAO: Qua trinh nay co the mat nhieu thoi gian!" -ForegroundColor Red
                Write-Host ""
                
                $confirm = Read-Host " Nhap 'YES' de tiep tuc: "
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
                
                Write-Status "DA DON DEP TOAN BO HE THONG!" -Type 'SUCCESS'
                Pause
            }
            '7' {
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
