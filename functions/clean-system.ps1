# ============================================================
# clean-system.ps1 - CLEAN SYSTEM (FULL FEATURES)
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

function Invoke-TempClean {
    Write-Status "Dang don dep file tam thoi..." -Type 'INFO'
    
    $paths = @(
        "$env:TEMP\*",
        "$env:LOCALAPPDATA\Temp\*", 
        "$env:WINDIR\Temp\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCookies\*"
    )
    
    $totalFreed = 0
    foreach ($path in $paths) {
        try {
            $items = Get-ChildItem $path -ErrorAction SilentlyContinue
            $size = ($items | Measure-Object Length -Sum).Sum
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            $totalFreed += $size
            Write-Host "  Cleaned: $path" -ForegroundColor $global:UI_Colors.Label
        } catch { }
    }
    
    if ($totalFreed -gt 0) {
        $freedMB = [math]::Round($totalFreed / 1MB, 2)
        Write-Status "Giai phong: $freedMB MB" -Type 'SUCCESS'
    }
}

function Invoke-UpdateCacheClean {
    Write-Status "Dang xoa Windows Update cache..." -Type 'INFO'
    
    try {
        Stop-Service wuauserv, bits -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service bits, wuauserv -ErrorAction SilentlyContinue
        Write-Status "Hoan thanh!" -Type 'SUCCESS'
    } catch {
        Write-Status "Co loi xay ra" -Type 'WARNING'
    }
}

function Invoke-PrefetchClean {
    Write-Status "Dang xoa Prefetch data..." -Type 'INFO'
    
    try {
        Remove-Item "$env:WINDIR\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Status "Hoan thanh!" -Type 'SUCCESS'
    } catch {
        Write-Status "Co loi xay ra" -Type 'WARNING'
    }
}

function Invoke-RecycleBinClean {
    Write-Status "Dang xoa thung rac..." -Type 'INFO'
    
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Status "Hoan thanh!" -Type 'SUCCESS'
    } catch {
        Write-Status "Co loi xay ra" -Type 'WARNING'
    }
}

function Invoke-DnsCacheClean {
    Write-Status "Dang xoa DNS cache..." -Type 'INFO'
    
    try {
        ipconfig /flushdns | Out-Null
        Write-Status "Hoan thanh!" -Type 'SUCCESS'
    } catch {
        Write-Status "Co loi xay ra" -Type 'WARNING'
    }
}

function Show-CleanSystem {
    Show-Header -Title "DON DEP HE THONG"
    
    Write-Host " Cac chuc nang don dep:" -ForegroundColor $global:UI_Colors.Title
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
    
    $choice = Read-Host "Lua chon (0-6): "
    
    switch ($choice) {
        '1' { Invoke-TempClean }
        '2' { Invoke-UpdateCacheClean }
        '3' { Invoke-PrefetchClean }
        '4' { Invoke-RecycleBinClean }
        '5' { Invoke-DnsCacheClean }
        '6' {
            Invoke-TempClean
            Invoke-UpdateCacheClean
            Invoke-PrefetchClean
            Invoke-RecycleBinClean
            Invoke-DnsCacheClean
            Write-Status "DA DON DEP TOAN BO HE THONG!" -Type 'SUCCESS'
        }
        '0' { return }
        default {
            Write-Status "Lua chon khong hop le!" -Type 'WARNING'
            Pause
            return
        }
    }
    
    Write-Host ""
    Write-Status "Don dep hoan tat!" -Type 'SUCCESS'
    Pause
}
