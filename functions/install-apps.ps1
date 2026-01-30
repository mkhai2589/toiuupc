# ============================================================
# install-apps.ps1 - INSTALL APPLICATIONS (COMPLETE VERSION)
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

function Install-Application {
    param([object]$App)
    
    if (-not $App.packageId) {
        Write-Status "Cấu hình ứng dụng không hợp lệ!" -Type 'ERROR'
        return
    }
    
    Write-Host ""
    Write-Host " THÔNG TIN ỨNG DỤNG:" -ForegroundColor $global:UI_Colors.Title
    Write-Host "   Tên: $($App.name)" -ForegroundColor $global:UI_Colors.Value
    Write-Host "   ID: $($App.packageId)" -ForegroundColor $global:UI_Colors.Label
    Write-Host "   Nguồn: $($App.source)" -ForegroundColor $global:UI_Colors.Label
    Write-Host "   Loại: $($App.category)" -ForegroundColor $global:UI_Colors.Label
    Write-Host ""
    
    # Kiểm tra đã cài đặt chưa
    Write-Status "Kiểm tra trạng thái cài đặt..." -Type 'INFO'
    if (Is-AppInstalled $App.packageId) {
        Write-Status "Ứng dụng đã được cài đặt (bỏ qua)" -Type 'WARNING'
        Write-Host ""
        return
    }
    
    Write-Status "Bắt đầu cài đặt..." -Type 'INFO'
    Write-Host ""
    
    $arguments = @(
        "install",
        "--id", $App.packageId,
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--disable-interactivity",
        "--silent"
    )
    
    if ($App.source) {
        $arguments += "--source", $App.source
    }
    
    # Log file
    $logFile = Join-Path $env:TEMP "winget_install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    try {
        Write-Host "   Đang cài đặt (có thể mất vài phút)..." -ForegroundColor $global:UI_Colors.Label
        
        # Run winget
        $process = Start-Process -FilePath "winget" `
            -ArgumentList $arguments `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardOutput $logFile `
            -RedirectStandardError "$logFile.error"
        
        # Check result
        if ($process.ExitCode -eq 0) {
            Write-Status "Cài đặt thành công!" -Type 'SUCCESS'
        } else {
            Write-Status "Thất bại (Mã lỗi: $($process.ExitCode))" -Type 'ERROR'
            
            # Show error log
            if (Test-Path "$logFile.error") {
                $errorLog = Get-Content "$logFile.error" -Tail 5
                Write-Host "   Chi tiết lỗi:" -ForegroundColor $global:UI_Colors.Error
                foreach ($line in $errorLog) {
                    Write-Host "     $line" -ForegroundColor $global:UI_Colors.Warning
                }
            }
        }
        
        # Cleanup
        Remove-Item $logFile, "$logFile.error" -ErrorAction SilentlyContinue
        
    } catch {
        Write-Status "Lỗi trong quá trình cài đặt: $_" -Type 'ERROR'
    }
    
    Write-Host ""
}

function Install-ApplicationsBulk {
    param([array]$Apps)
    
    $total = $Apps.Count
    $success = 0
    $failed = 0
    $skipped = 0
    
    Write-Status "Bắt đầu cài đặt loạt $total ứng dụng..." -Type 'INFO'
    Write-Host ""
    
    foreach ($app in $Apps) {
        Write-Host " [$($success+$failed+$skipped+1)/$total] $($app.name)" -ForegroundColor $global:UI_Colors.Menu
        
        if (Is-AppInstalled $app.packageId) {
            Write-Status "Đã cài đặt, bỏ qua" -Type 'WARNING'
            $skipped++
        } else {
            Install-Application -App $app
            if (Is-AppInstalled $app.packageId) {
                $success++
            } else {
                $failed++
            }
        }
        
        Write-Host ""
    }
    
    Write-Host ""
    Write-Host " TỔNG KẾT CÀI ĐẶT:" -ForegroundColor $global:UI_Colors.Title
    Write-Host "   Thành công: $success" -ForegroundColor $global:UI_Colors.Success
    Write-Host "   Thất bại: $failed" -ForegroundColor $global:UI_Colors.Error
    Write-Host "   Đã bỏ qua: $skipped" -ForegroundColor $global:UI_Colors.Warning
    Write-Host ""
}

function Show-AppsMenu {
    param($Config)
    
    if (-not $Config -or -not $Config.applications) {
        Write-Status "Cấu hình ứng dụng không hợp lệ!" -Type 'ERROR'
        Pause
        return
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
        
        Show-Header -Title "CÀI ĐẶT ỨNG DỤNG"
        
        Write-Host " DANH MỤC ỨNG DỤNG:" -ForegroundColor $global:UI_Colors.Title
        Write-Host ""
        
        # Display categories
        $catKeys = @()
        $index = 1
        foreach ($cat in $categories.Keys | Sort-Object) {
            $count = $categories[$cat].Count
            Write-Host "  [$index] $cat ($count ứng dụng)" -ForegroundColor $global:UI_Colors.Menu
            $catKeys += $cat
            $index++
        }
        
        Write-Host ""
        Write-Host "  [A] Cài đặt TOÀN BỘ ứng dụng" -ForegroundColor $global:UI_Colors.Highlight
        Write-Host "  [B] Cài đặt từng ứng dụng" -ForegroundColor $global:UI_Colors.Menu
        Write-Host "  [C] Kiểm tra ứng dụng đã cài" -ForegroundColor $global:UI_Colors.Menu
        Write-Host ""
        Write-Host "  [0] Quay lại Menu Chính" -ForegroundColor $global:UI_Colors.Menu
        Write-Host ""
        Write-Host "─" * 55 -ForegroundColor $global:UI_Colors.Border
        Write-Host ""
        
        $choice = Read-Host "Lựa chọn (0-$($catKeys.Count), A, B, C): "
        
        switch ($choice) {
            '0' { return }
            'A' {
                Show-Header -Title "CÀI ĐẶT TOÀN BỘ ỨNG DỤNG"
                Write-Status "Bạn có chắc muốn cài đặt TOÀN BỘ ứng dụng?" -Type 'WARNING'
                Write-Host "   Số lượng: $($Config.applications.Count) ứng dụng" -ForegroundColor $global:UI_Colors.Value
                Write-Host ""
                $confirm = Read-Host "Nhập 'YES' để xác nhận: "
                if ($confirm -eq "YES") {
                    Install-ApplicationsBulk -Apps $Config.applications
                } else {
                    Write-Status "Đã hủy!" -Type 'INFO'
                }
                Pause
            }
            'B' {
                Show-Header -Title "CÀI ĐẶT TỪNG ỨNG DỤNG"
                
                # List all apps
                $allApps = $Config.applications
                $appMenuItems = @()
                for ($i = 0; $i -lt $allApps.Count; $i++) {
                    $app = $allApps[$i]
                    $status = if (Is-AppInstalled $app.packageId) { "[Đã cài]" } else { "[Chưa cài]" }
                    $appMenuItems += @{ 
                        Key = "$($i+1)"; 
                        Text = "$($app.name.PadRight(30)) $status"
                    }
                }
                
                $appMenuItems += @{ Key = "0"; Text = "Quay lại" }
                
                Show-Menu -MenuItems $appMenuItems -Title "CHỌN ỨNG DỤNG" -TwoColumn -Prompt "Chọn ứng dụng (0 để quay lại): "
                
                $appChoice = Read-Host
                if ($appChoice -eq "0") { continue }
                
                $appIndex = [int]$appChoice - 1
                if ($appIndex -ge 0 -and $appIndex -lt $allApps.Count) {
                    $selectedApp = $allApps[$appIndex]
                    Install-Application -App $selectedApp
                    Pause
                } else {
                    Write-Status "Lựa chọn không hợp lệ!" -Type 'WARNING'
                    Pause
                }
            }
            'C' {
                Show-Header -Title "KIỂM TRA ỨNG DỤNG ĐÃ CÀI ĐẶT"
                
                $installedCount = 0
                Write-Host " DANH SÁCH ỨNG DỤNG:" -ForegroundColor $global:UI_Colors.Title
                Write-Host ""
                
                foreach ($app in $Config.applications) {
                    $installed = Is-AppInstalled $app.packageId
                    $status = if ($installed) { 
                        $installedCount++
                        "[Đã cài]" 
                    } else { 
                        "[Chưa cài]" 
                    }
                    Write-Host "   $($app.name.PadRight(35)) $status" -ForegroundColor $(if ($installed) { "Green" } else { "Gray" })
                }
                
                Write-Host ""
                Write-Status "Đã cài đặt: $installedCount/$($Config.applications.Count) ứng dụng" -Type 'INFO'
                Pause
            }
            default {
                # Handle category selection
                if ($choice -match '^\d+$') {
                    $catIndex = [int]$choice - 1
                    if ($catIndex -ge 0 -and $catIndex -lt $catKeys.Count) {
                        $selectedCat = $catKeys[$catIndex]
                        $catApps = $categories[$selectedCat]
                        
                        Show-Header -Title "CÀI ĐẶT ỨNG DỤNG: $selectedCat"
                        
                        # Show apps in category
                        $catMenuItems = @()
                        for ($i = 0; $i -lt $catApps.Count; $i++) {
                            $app = $catApps[$i]
                            $status = if (Is-AppInstalled $app.packageId) { "[Đã cài]" } else { "[Chưa cài]" }
                            $catMenuItems += @{ 
                                Key = "$($i+1)"; 
                                Text = "$($app.name.PadRight(30)) $status"
                            }
                        }
                        
                        $catMenuItems += @{ Key = "A"; Text = "Cài đặt TOÀN BỘ category này" }
                        $catMenuItems += @{ Key = "0"; Text = "Quay lại" }
                        
                        Show-Menu -MenuItems $catMenuItems -Title "CHỌN ỨNG DỤNG TRONG $selectedCat" -Prompt "Lựa chọn (0, A, hoặc số): "
                        
                        $catChoice = Read-Host
                        
                        switch ($catChoice) {
                            '0' { continue }
                            'A' {
                                Write-Status "Cài đặt toàn bộ category: $selectedCat" -Type 'INFO'
                                Install-ApplicationsBulk -Apps $catApps
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
                                        Write-Status "Lựa chọn không hợp lệ!" -Type 'WARNING'
                                        Pause
                                    }
                                } else {
                                    Write-Status "Lựa chọn không hợp lệ!" -Type 'WARNING'
                                    Pause
                                }
                            }
                        }
                    } else {
                        Write-Status "Lựa chọn không hợp lệ!" -Type 'WARNING'
                        Pause
                    }
                } else {
                    Write-Status "Lựa chọn không hợp lệ!" -Type 'WARNING'
                    Pause
                }
            }
        }
    }
}

# ============================================================
# EXPORT FUNCTIONS
# ============================================================
Export-ModuleMember -Function @(
    'Is-AppInstalled',
    'Install-Application',
    'Install-ApplicationsBulk',
    'Show-AppsMenu'
)
