# ============================================================
# install-apps.ps1 - INSTALL APPLICATIONS (FINAL VERSION)
# ============================================================
# Author: Minh Khai
# Version: 2.0.0
# Description: Application installation module
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# CORE FUNCTIONS
# ============================================================

function Is-AppInstalled {
    param([string]$PackageId)
    
    try {
        # Check via winget
        $result = winget list --id $PackageId --accept-source-agreements 2>&1
        if ($result -like "*$PackageId*") {
            return $true
        }
    } catch {
        # Check via registry
        $uninstallKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        
        foreach ($key in $uninstallKeys) {
            $apps = Get-ItemProperty $key -ErrorAction SilentlyContinue
            foreach ($app in $apps) {
                if ($app.PSChildName -like "*$PackageId*") {
                    return $true
                }
            }
        }
    }
    
    return $false
}

function Test-WingetAvailable {
    try {
        $wingetVersion = winget --version 2>&1
        if ($wingetVersion -like "*version*" -or $wingetVersion -match '\d+\.\d+\.\d+') {
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

function Install-WingetIfMissing {
    if (Test-WingetAvailable) {
        return $true
    }
    
    Write-Status "Winget chua duoc cai dat. Dang cai dat winget..." -Type 'INFO'
    
    try {
        $wingetUrl = "https://aka.ms/getwinget"
        $wingetPath = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        
        Write-Host "   Dang tai winget tu Microsoft..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath -UseBasicParsing -ErrorAction Stop
        
        Write-Host "   Dang cai dat winget..." -ForegroundColor Gray
        Add-AppxPackage -Path $wingetPath -ErrorAction Stop | Out-Null
        
        if (Test-WingetAvailable) {
            Write-Status "Winget da duoc cai dat thanh cong!" -Type 'SUCCESS'
            Remove-Item $wingetPath -Force -ErrorAction SilentlyContinue
            return $true
        }
        
    } catch {
        Write-Status "Loi cai dat winget: $_" -Type 'ERROR'
        return $false
    }
    
    return $false
}

function Install-Application {
    param([object]$App)
    
    if (-not $App.packageId) {
        Write-Status "Cau hinh ung dung khong hop le!" -Type 'ERROR'
        return $false
    }
    
    Write-Host ""
    Write-Host " THONG TIN UNG DUNG:" -ForegroundColor $global:UI_Colors.Title
    Write-Host "   Ten: $($App.name)" -ForegroundColor $global:UI_Colors.Value
    Write-Host "   ID: $($App.packageId)" -ForegroundColor $global:UI_Colors.Label
    Write-Host "   Loai: $($App.category)" -ForegroundColor $global:UI_Colors.Label
    Write-Host ""
    
    # Kiem tra neu da cai dat
    Write-Status "Kiem tra trang thai cai dat..." -Type 'INFO'
    if (Is-AppInstalled $App.packageId) {
        Write-Status "Ung dung da duoc cai dat (bo qua)" -Type 'WARNING'
        Write-Host ""
        return $true
    }
    
    # Kiem tra winget
    if (-not (Test-WingetAvailable)) {
        if (-not (Install-WingetIfMissing)) {
            Write-Status "Khong the cai dat ung dung vi winget khong co san" -Type 'ERROR'
            return $false
        }
    }
    
    Write-Status "Bat dau cai dat..." -Type 'INFO'
    Write-Host ""
    
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
        Write-Host "   Dang cai dat (co the mat vai phut)..." -ForegroundColor $global:UI_Colors.Label
        
        $process = Start-Process -FilePath "winget" `
            -ArgumentList $arguments `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardOutput "$env:TEMP\winget_install.log" `
            -RedirectStandardError "$env:TEMP\winget_install_error.log"
        
        if ($process.ExitCode -eq 0) {
            Write-Status "Cai dat thanh cong!" -Type 'SUCCESS'
            
            if (Is-AppInstalled $App.packageId) {
                return $true
            } else {
                Write-Status "Da cai nhung khong tim thay trong danh sach!" -Type 'WARNING'
                return $true
            }
        } else {
            Write-Status "That bai (Ma loi: $($process.ExitCode))" -Type 'ERROR'
            return $false
        }
        
    } catch {
        Write-Status "Loi trong qua trinh cai dat: $_" -Type 'ERROR'
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
    
    # Kiem tra winget
    if (-not (Test-WingetAvailable)) {
        Write-Status "Winget chua duoc cai dat!" -Type 'WARNING'
        Write-Host "   Ban co muon cai dat winget ngay bay gio?" -ForegroundColor $global:UI_Colors.Label
        Write-Host ""
        $choice = Read-Host "Nhap 'YES' de cai dat winget, hoac bat ky de bo qua: "
        if ($choice -eq "YES") {
            if (-not (Install-WingetIfMissing)) {
                Write-Status "Khong the cai dat winget. Mot so chuc nang co the khong hoat dong." -Type 'ERROR'
                Pause
            }
        }
    }
    
    while ($true) {
        # Group by category
        $categories = @{}
        foreach ($app in $Config.applications) {
            $category = $app.category
            if (-not $categories.ContainsKey($category)) {
                $categories[$category] = New-Object System.Collections.ArrayList
            }
            $null = $categories[$category].Add($app)
        }
        
        Show-Header -Title "CAI DAT UNG DUNG"
        
        Write-Host " DANH MUC UNG DUNG:" -ForegroundColor $global:UI_Colors.Title
        Write-Host ""
        
        # Hien thi danh muc
        $catKeys = @()
        $index = 1
        foreach ($cat in $categories.Keys | Sort-Object) {
            $count = $categories[$cat].Count
            Write-Host "  [$index] $cat ($count ung dung)" -ForegroundColor $global:UI_Colors.Menu
            $catKeys += $cat
            $index++
        }
        
        Write-Host ""
        Write-Host "  [A] Cai dat TOAN BO ung dung" -ForegroundColor $global:UI_Colors.Highlight
        Write-Host "  [B] Cai dat tung ung dung" -ForegroundColor $global:UI_Colors.Menu
        Write-Host "  [C] Kiem tra ung dung da cai" -ForegroundColor $global:UI_Colors.Menu
        Write-Host "  [D] Cai dat Winget (neu thieu)" -ForegroundColor $global:UI_Colors.Menu
        Write-Host ""
        Write-Host "  [0] Quay lai Menu Chinh" -ForegroundColor $global:UI_Colors.Menu
        Write-Host ""
        Write-Host "-" * 55 -ForegroundColor $global:UI_Colors.Border
        Write-Host ""
        
        $choice = Read-Host "Lua chon (0-$($catKeys.Count), A, B, C, D): "
        
        switch ($choice.ToUpper()) {
            '0' { return }
            'A' {
                Show-Header -Title "CAI DAT TOAN BO UNG DUNG"
                Write-Status "Ban co chac muon cai dat TOAN BO ung dung?" -Type 'WARNING'
                Write-Host "   So luong: $($Config.applications.Count) ung dung" -ForegroundColor $global:UI_Colors.Value
                Write-Host "   Qua trinh co the mat nhieu thoi gian!" -ForegroundColor $global:UI_Colors.Warning
                Write-Host ""
                $confirm = Read-Host "Nhap 'YES' de xac nhan: "
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
                    Write-Host " TONG KET CAI DAT:" -ForegroundColor $global:UI_Colors.Title
                    Write-Host "   Thanh cong: $success" -ForegroundColor Green
                    Write-Host "   That bai: $failed" -ForegroundColor Red
                    Write-Host "   Da bo qua: $skipped" -ForegroundColor Yellow
                    Write-Host ""
                } else {
                    Write-Status "Da huy!" -Type 'INFO'
                }
                Pause
            }
            'B' {
                Show-Header -Title "CAI DAT TUNG UNG DUNG"
                
                # Liet ke tat ca ung dung
                $allApps = $Config.applications
                $appMenuItems = @()
                for ($i = 0; $i -lt $allApps.Count; $i++) {
                    $app = $allApps[$i]
                    $status = if (Is-AppInstalled $app.packageId) { "[Da cai]" } else { "[Chua cai]" }
                    $displayText = "$($app.name) $status"
                    if ($displayText.Length -gt 40) {
                        $displayText = $displayText.Substring(0, 37) + "..."
                    }
                    $appMenuItems += @{ 
                        Key = "$($i+1)"; 
                        Text = $displayText
                    }
                }
                
                $appMenuItems += @{ Key = "0"; Text = "Quay lai" }
                
                Show-Menu -MenuItems $appMenuItems -Title "CHON UNG DUNG" -TwoColumn -Prompt "Chon ung dung (0 de quay lai): "
                
                $appChoice = Read-Host
                if ($appChoice -eq "0") { continue }
                
                $appIndex = [int]$appChoice - 1
                if ($appIndex -ge 0 -and $appIndex -lt $allApps.Count) {
                    $selectedApp = $allApps[$appIndex]
                    Install-Application -App $selectedApp
                    Pause
                } else {
                    Write-Status "Lua chon khong hop le!" -Type 'WARNING'
                    Pause
                }
            }
            'C' {
                Show-Header -Title "KIEM TRA UNG DUNG DA CAI DAT"
                
                $installedCount = 0
                Write-Host " DANH SACH UNG DUNG:" -ForegroundColor $global:UI_Colors.Title
                Write-Host ""
                
                foreach ($app in $Config.applications) {
                    $installed = Is-AppInstalled $app.packageId
                    $status = if ($installed) { 
                        $installedCount++
                        "[Da cai]" 
                    } else { 
                        "[Chua cai]" 
                    }
                    Write-Host "   $($app.name) $status" -ForegroundColor $(if ($installed) { "Green" } else { "Gray" })
                }
                
                Write-Host ""
                Write-Status "Da cai dat: $installedCount/$($Config.applications.Count) ung dung" -Type 'INFO'
                Pause
            }
            'D' {
                Show-Header -Title "CAI DAT WINGET"
                if (Install-WingetIfMissing) {
                    Write-Status "Winget da san sang su dung!" -Type 'SUCCESS'
                } else {
                    Write-Status "Khong the cai dat winget!" -Type 'ERROR'
                }
                Pause
            }
            default {
                # Xu ly chon danh muc
                if ($choice -match '^\d+$') {
                    $catIndex = [int]$choice - 1
                    if ($catIndex -ge 0 -and $catIndex -lt $catKeys.Count) {
                        $selectedCat = $catKeys[$catIndex]
                        $catApps = $categories[$selectedCat]
                        
                        Show-Header -Title "CAI DAT UNG DUNG: $selectedCat"
                        
                        # Hien thi ung dung trong danh muc
                        $catMenuItems = @()
                        for ($i = 0; $i -lt $catApps.Count; $i++) {
                            $app = $catApps[$i]
                            $status = if (Is-AppInstalled $app.packageId) { "[Da cai]" } else { "[Chua cai]" }
                            $displayText = "$($app.name) $status"
                            if ($displayText.Length -gt 40) {
                                $displayText = $displayText.Substring(0, 37) + "..."
                            }
                            $catMenuItems += @{ 
                                Key = "$($i+1)"; 
                                Text = $displayText
                            }
                        }
                        
                        $catMenuItems += @{ Key = "A"; Text = "Cai dat TOAN BO danh muc nay" }
                        $catMenuItems += @{ Key = "0"; Text = "Quay lai" }
                        
                        Show-Menu -MenuItems $catMenuItems -Title "CHON UNG DUNG TRONG $selectedCat" -TwoColumn -Prompt "Lua chon (0, A, hoac so): "
                        
                        $catChoice = Read-Host
                        
                        switch ($catChoice.ToUpper()) {
                            '0' { continue }
                            'A' {
                                $success = 0
                                $failed = 0
                                $skipped = 0
                                
                                foreach ($app in $catApps) {
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
                                Write-Status "Da cai dat $success/$($catApps.Count) ung dung trong danh muc!" -Type 'INFO'
                                Pause
                            }
                            default {
                                if ($catChoice -match '^\d+$') {
                                    $appIndex = [int]$catChoice - 1
                                    if ($appIndex -ge 0 -and $appIndex -lt $catApps.Count) {
                                        $selectedApp = $catApps[$appIndex]
                                        Install-Application -App $selectedApp
                                        Pause
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
