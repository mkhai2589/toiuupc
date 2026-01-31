# ============================================================
# install-apps.ps1 - INSTALL APPLICATIONS
# ============================================================

function Test-WingetAvailable {
    try {
        $null = winget --version 2>$null
        return $true
    } catch {
        return $false
    }
}

function Install-WingetIfMissing {
    if (Test-WingetAvailable) {
        return $true
    }
    
    Write-Status "Winget chua duoc cai dat..." -Type 'INFO'
    
    try {
        Write-Host "   Dang tai winget..." -ForegroundColor Gray
        $wingetUrl = "https://aka.ms/getwinget"
        $wingetPath = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        
        Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath -UseBasicParsing
        
        Write-Host "   Dang cai dat winget..." -ForegroundColor Gray
        Add-AppxPackage -Path $wingetPath -ErrorAction Stop
        
        Remove-Item $wingetPath -Force
        
        if (Test-WingetAvailable) {
            Write-Status "Winget da duoc cai dat!" -Type 'SUCCESS'
            return $true
        }
    } catch {
        Write-Status "Loi cai dat winget!" -Type 'ERROR'
        return $false
    }
}

function Is-AppInstalled {
    param([string]$PackageId)
    
    try {
        $result = winget list --id $PackageId --accept-source-agreements 2>$null
        return $result -like "*$PackageId*"
    } catch {
        return $false
    }
}

function Install-Application {
    param([object]$App)
    
    Write-Host ""
    Write-Host " THONG TIN UNG DUNG:" -ForegroundColor White
    Write-Host "   Ten: $($App.name)" -ForegroundColor Gray
    Write-Host "   ID: $($App.packageId)" -ForegroundColor Gray
    Write-Host ""
    
    if (Is-AppInstalled $App.packageId) {
        Write-Status "Ung dung da duoc cai dat!" -Type 'WARNING'
        return $true
    }
    
    if (-not (Test-WingetAvailable)) {
        if (-not (Install-WingetIfMissing)) {
            Write-Status "Khong the cai dat winget!" -Type 'ERROR'
            return $false
        }
    }
    
    Write-Status "Bat dau cai dat..." -Type 'INFO'
    
    $arguments = @(
        "install",
        "--id", $App.packageId,
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--silent"
    )
    
    if ($App.source) {
        $arguments += "--source", $App.source
    }
    
    try {
        Write-Host "   Dang cai dat..." -ForegroundColor Gray
        
        $process = Start-Process -FilePath "winget" `
            -ArgumentList $arguments `
            -NoNewWindow `
            -Wait `
            -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Status "Cai dat thanh cong!" -Type 'SUCCESS'
            return $true
        } else {
            Write-Status "That bai (Ma loi: $($process.ExitCode))" -Type 'ERROR'
            return $false
        }
    } catch {
        Write-Status "Loi trong qua trinh cai dat!" -Type 'ERROR'
        return $false
    }
}

function Show-AppsMenu {
    param($Config)
    
    if (-not $Config -or -not $Config.applications) {
        Write-Status "Cau hinh ung dung khong hop le!" -Type 'ERROR'
        Pause
        return
    }
    
    # Check winget
    if (-not (Test-WingetAvailable)) {
        Write-Status "Winget chua duoc cai dat!" -Type 'WARNING'
        Write-Host "   Ban co muon cai dat winget?" -ForegroundColor Gray
        Write-Host ""
        $choice = Read-Host " Nhap 'YES' de cai dat: "
        if ($choice -eq "YES") {
            if (-not (Install-WingetIfMissing)) {
                Write-Status "Khong the cai dat winget!" -Type 'ERROR'
                Pause
            }
        }
    }
    
    while ($true) {
        Show-Header -Title "CAI DAT UNG DUNG"
        
        # Group by category
        $categories = @{}
        foreach ($app in $Config.applications) {
            $category = $app.category
            if (-not $categories.ContainsKey($category)) {
                $categories[$category] = New-Object System.Collections.ArrayList
            }
            $null = $categories[$category].Add($app)
        }
        
        Write-Host " DANH SACH UNG DUNG:" -ForegroundColor White
        Write-Host ""
        
        $appIndex = 1
        $appMap = @{}
        
        foreach ($cat in ($categories.Keys | Sort-Object)) {
            Write-Host " [$cat]" -ForegroundColor Cyan
            Write-Host ""
            
            $appsInCategory = $categories[$cat]
            $mid = [math]::Ceiling($appsInCategory.Count / 2)
            
            for ($i = 0; $i -lt $mid; $i++) {
                $leftApp = $appsInCategory[$i]
                $rightIndex = $i + $mid
                
                # Left column (limit to 40 chars)
                $leftStatus = if (Is-AppInstalled $leftApp.packageId) { "[Da cai]" } else { "[Chua]" }
                $leftText = "$appIndex. $($leftApp.name.PadRight(30)) $leftStatus"
                $appMap[$appIndex] = $leftApp
                $appIndex++
                
                # Right column (if exists)
                if ($rightIndex -lt $appsInCategory.Count) {
                    $rightApp = $appsInCategory[$rightIndex]
                    $rightStatus = if (Is-AppInstalled $rightApp.packageId) { "[Da cai]" } else { "[Chua]" }
                    $rightText = "$appIndex. $($rightApp.name.PadRight(30)) $rightStatus"
                    
                    Write-Host "   $leftText   $rightText" -ForegroundColor Gray
                    $appMap[$appIndex] = $rightApp
                    $appIndex++
                } else {
                    Write-Host "   $leftText" -ForegroundColor Gray
                }
            }
            Write-Host ""
        }
        
        Write-Host ("-" * $global:UI_Width) -ForegroundColor DarkGray
        Write-Host ""
        
        Write-Host " TINH NANG:" -ForegroundColor White
        Write-Host ""
        Write-Host "  [A] Cai dat TOAN BO ung dung chua co" -ForegroundColor Magenta
        Write-Host "  [B] Kiem tra ung dung da cai" -ForegroundColor Gray
        Write-Host "  [C] Cap nhat winget" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [0] Quay lai Menu Chinh" -ForegroundColor Gray
        Write-Host ""
        
        $choice = Read-Host " Lua chon (so, A, B, C, hoac 0): "
        
        switch ($choice.ToUpper()) {
            '0' { return }
            'A' {
                Show-Header -Title "CAI DAT TOAN BO UNG DUNG"
                Write-Status "Cai dat TOAN BO ung dung chua co?" -Type 'WARNING'
                Write-Host "   So luong: $($Config.applications.Count) ung dung" -ForegroundColor Gray
                Write-Host ""
                $confirm = Read-Host " Nhap 'YES' de xac nhan: "
                if ($confirm -eq "YES") {
                    $success = 0
                    $failed = 0
                    $skipped = 0
                    
                    foreach ($app in $Config.applications) {
                        if (Is-AppInstalled $app.packageId) {
                            $skipped++
                        } else {
                            if (Install-Application -App $app) {
                                $success++
                            } else {
                                $failed++
                            }
                        }
                    }
                    
                    Write-Host ""
                    Write-Host " TONG KET CAI DAT:" -ForegroundColor White
                    Write-Host "   Thanh cong: $success" -ForegroundColor Green
                    Write-Host "   That bai: $failed" -ForegroundColor Red
                    Write-Host "   Da bo qua: $skipped" -ForegroundColor Yellow
                } else {
                    Write-Status "Da huy!" -Type 'INFO'
                }
                Pause
            }
            'B' {
                Show-Header -Title "KIEM TRA UNG DUNG DA CAI"
                
                $installedCount = 0
                Write-Host " DANH SACH UNG DUNG:" -ForegroundColor White
                Write-Host ""
                
                foreach ($app in $Config.applications) {
                    $installed = Is-AppInstalled $app.packageId
                    if ($installed) {
                        Write-Host "   ✓ $($app.name)" -ForegroundColor Green
                        $installedCount++
                    }
                }
                
                Write-Host ""
                Write-Status "Da cai dat: $installedCount/$($Config.applications.Count) ung dung" -Type 'INFO'
                Pause
            }
            'C' {
                Show-Header -Title "CAP NHAT WINGET"
                if (Install-WingetIfMissing) {
                    Write-Status "Winget da san sang!" -Type 'SUCCESS'
                }
                Pause
            }
            default {
                if ($choice -match '^\d+$') {
                    $selectedIndex = [int]$choice
                    if ($selectedIndex -ge 1 -and $selectedIndex -lt $appIndex) {
                        $selectedApp = $appMap[$selectedIndex]
                        if ($selectedApp) {
                            Show-Header -Title "CAI DAT UNG DUNG"
                            Install-Application -App $selectedApp
                            Pause
                        }
                    } else {
                        Write-Status "Lua chon khong hop le!" -Type 'WARNING'
                        Pause
                    }
                } else {
                    Write-Status "Lua chon khong hop le!" -Type 'WARNING'
                    Pause
                }
            }
        }
    }
}
