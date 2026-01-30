# ============================================================
# install-apps.ps1 - INSTALL APPLICATIONS (IMPROVED)
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# VALIDATE APPLICATION CONFIG
# ============================================================
function Validate-AppConfig {
    param([object]$App)
    
    $errors = @()
    
    if (-not $App.id) {
        $errors += "Thieu 'id'"
    }
    
    if (-not $App.name) {
        $errors += "Thieu 'name'"
    }
    
    if (-not $App.packageId) {
        $errors += "Thieu 'packageId'"
    } else {
        # Kiểm tra định dạng packageId (thường là Vendor.App)
        if ($App.packageId -notmatch '^[a-zA-Z0-9]+\.[a-zA-Z0-9]+') {
            $errors += "packageId khong dung dinh dang (Vendor.App)"
        }
    }
    
    if (-not $App.source) {
        $errors += "Thieu 'source'"
    } elseif ($App.source -notin @('winget', 'msstore')) {
        $errors += "source phai la 'winget' hoac 'msstore'"
    }
    
    if ($errors.Count -gt 0) {
        Write-Host " [VALIDATION ERROR] $($App.name):" -ForegroundColor $global:UI_Colors.Error
        foreach ($err in $errors) {
            Write-Host "   - $err" -ForegroundColor $global:UI_Colors.Warning
        }
        return $false
    }
    
    return $true
}

function Load-ApplicationConfig {
    $path = Join-Path $PSScriptRoot "..\config\applications.json"
    $config = Load-JsonFile -Path $path
    
    if ($config -and $config.applications) {
        Write-Status "Kiem tra cau hinh ung dung..." -Type 'INFO'
        $validCount = 0
        $invalidCount = 0
        
        foreach ($app in $config.applications) {
            if (Validate-AppConfig -App $app) {
                $validCount++
            } else {
                $invalidCount++
            }
        }
        
        Write-Host ""
        Write-Status "Kiem tra hoan tat: $validCount ung dung hop le, $invalidCount ung dung loi" -Type 'INFO'
        
        if ($invalidCount -gt 0) {
            Write-Host "   Moi cap nhat file applications.json de sua loi" -ForegroundColor $global:UI_Colors.Warning
            Write-Host ""
            Pause
        }
    }
    
    return $config
}

function Install-Application {
    param([object]$App)
    
    if (-not $App.packageId) {
        Write-Status "Cau hinh ung dung khong hop le!" -Type 'ERROR'
        return
    }
    
    Write-Host ""
    Write-Host " THONG TIN UNG DUNG:" -ForegroundColor $global:UI_Colors.Title
    Write-Host "   Ten: $($App.name)" -ForegroundColor $global:UI_Colors.Value
    Write-Host "   ID: $($App.packageId)" -ForegroundColor $global:UI_Colors.Label
    Write-Host "   Nguon: $($App.source)" -ForegroundColor $global:UI_Colors.Label
    Write-Host "   Loai: $($App.category)" -ForegroundColor $global:UI_Colors.Label
    Write-Host ""
    
    # Kiểm tra nếu đã cài đặt
    Write-Status "Kiem tra trang thai cai dat..." -Type 'INFO'
    if (Is-AppInstalled $App.packageId) {
        Write-Status "Ung dung da duoc cai dat (bo qua)" -Type 'WARNING'
        Write-Host ""
        return
    }
    
    Write-Status "Bat dau cai dat..." -Type 'INFO'
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
    
    # Thêm logging chi tiết
    $logFile = Join-Path $env:TEMP "winget_install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    try {
        Write-Host "   Dang cai dat (co the mat vai phut)..." -ForegroundColor $global:UI_Colors.Label
        
        # Chạy winget với timeout
        $process = Start-Process -FilePath "winget" `
            -ArgumentList $arguments `
            -NoNewWindow `
            -Wait `
            -PassThrupip install `
            -RedirectStandardOutput $logFile `
            -RedirectStandardError "$logFile.error"
        
        # Kiểm tra kết quả
        if ($process.ExitCode -eq 0) {
            Write-Status "Cai dat thanh cong!" -Type 'SUCCESS'
        } else {
            Write-Status "That bai (Ma loi: $($process.ExitCode))" -Type 'ERROR'
            
            # Hiển thị log lỗi nếu có
            if (Test-Path "$logFile.error") {
                $errorLog = Get-Content "$logFile.error" -Tail 5
                Write-Host "   Chi tiet loi:" -ForegroundColor $global:UI_Colors.Error
                foreach ($line in $errorLog) {
                    Write-Host "     $line" -ForegroundColor $global:UI_Colors.Warning
                }
            }
        }
        
        # Dọn dẹp log file
        Remove-Item $logFile, "$logFile.error" -ErrorAction SilentlyContinue
        
    } catch {
        Write-Status "Loi trong qua trinh cai dat: $_" -Type 'ERROR'
    }
    
    Write-Host ""
}
