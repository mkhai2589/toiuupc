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
        "$env:WINDIR\Temp\*"
    )
    
    $totalFreed = 0
    foreach ($path in $paths) {
        try {
            $items = Get-ChildItem $path -ErrorAction SilentlyContinue
            $size = ($items | Measure-Object Length -Sum).Sum
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            $totalFreed += $size
            Write-Host "   Da xoa: $path" -ForegroundColor $global:UI_Colors.Label
        } catch { }
    }
    
    if ($totalFreed -gt 0) {
        $freedMB = [math]::Round($totalFreed / 1MB, 2)
        Write-Host ""
        Write-Status "Giai phong: $freedMB MB" -Type 'SUCCESS'
    }
    Write-Host ""
}

# ... (các hàm khác tương tự)

function Show-CleanSystem {
    Show-Header -Title "DON DEP HE THONG"
    
    Write-Host " CAC CHUC NANG DON DEP:" -ForegroundColor $global:UI_Colors.Title
    Write-Host ""
    Write-Host "  1. File tam thoi (Temp)" -ForegroundColor $global:UI_Colors.Menu
    Write-Host "  2. Windows Update cache" -ForegroundColor $global:UI_Colors.Menu  
    Write-Host "  3. Prefetch data" -ForegroundColor $global:UI_Colors.Menu
    Write-Host "  4. Thung rac (Recycle Bin)" -ForegroundColor $global:UI_Colors.Menu
    Write-Host "  5. DNS cache" -ForegroundColor $global:UI_Colors.Menu
    Write-Host "  6. Don dep TOAN BO (tat ca tren)" -ForegroundColor $global:UI_Colors.Highlight
    Write-Host ""
    Write-Host "  0. Quay lai Menu Chinh" -ForegroundColor $global:UI_Colors.Menu
    Write-Host ""
    Write-Host "─" * 40 -ForegroundColor $global:UI_Colors.Border
    Write-Host ""
    
    $choice = Read-Host "Lua chon (0-6): "
    
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
            Show-Header -Title "DON DEP TOAN BO"
            Write-Status "Bat dau don dep toan bo..." -Type 'INFO'
            Write-Host ""
            
            Invoke-TempClean
            Invoke-UpdateCacheClean
            Invoke-PrefetchClean
            Invoke-RecycleBinClean
            Invoke-DnsCacheClean
            
            Write-Host ""
            Write-Status "DA DON DEP TOAN BO HE THONG!" -Type 'SUCCESS'
            Write-Host ""
            Pause
        }
        '0' { return }
        default {
            Write-Status "Lua chon khong hop le!" -Type 'WARNING'
            Pause
            return
        }
    }
}
