# ==========================================================
# ToiUuPC.ps1 - MAIN MENU (REWRITTEN - SIMPLE FLOW)
# ==========================================================
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

# ==========================================================
# ROOT & LOAD CORE
# ==========================================================
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load utils và kiểm tra Admin
. (Join-Path $ScriptRoot "functions\utils.ps1")
Ensure-Admin

# Load tất cả modules hàm (ĐẢM BẢO TÊN CHUẨN)
$FunctionFiles = @(
    "Show-PMKLogo.ps1",
    "tweaks.ps1",
    "install-apps.ps1",
    "dns-management.ps1",
    "clean-system.ps1"
)
foreach ($file in $FunctionFiles) {
    $path = Join-Path $ScriptRoot "functions\$file"
    if (Test-Path $path) {
        . $path
    } else {
        Write-Host "[WARN] Khong tim thay file: $file" -ForegroundColor Yellow
    }
}

# Load JSON Config (dùng hàm từ utils.ps1)
$ConfigDir = Join-Path $ScriptRoot "config"
$TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
$AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
$DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")

if (-not $TweaksConfig -or -not $AppsConfig -or -not $DnsConfig) {
    Write-Host "LOI: Tai cau hinh JSON that bai!" -ForegroundColor Red
    Pause
    exit 1
}

# ==========================================================
# HÀM HIỂN THỊ MENU CHÍNH (KHÔNG CỘT ACTION)
# ==========================================================
function Show-MainMenu {
    Clear-Host
    Show-PMKLogo
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         TOI UU PC - MENU CHINH         " -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Tinh Chinh Windows (Tweaks)"
    Write-Host "  2. Quan Ly DNS"
    Write-Host "  3. Don Dep He Thong"
    Write-Host "  4. Cai Dat Ung Dung"
    Write-Host "  5. Tai Lai Cau Hinh (Reload Config)"
    Write-Host ""
    Write-Host "  0. Thoat Chuong Trinh"
    Write-Host ""
}

# ==========================================================
# VÒNG LẶP CHÍNH - LUỒNG ĐIỀU KHIỂN ĐƠN GIẢN
# ==========================================================
while ($true) {
    Show-MainMenu
    $choice = Read-Host "Nhap lua chon (0-5)"

    switch ($choice) {
        '1' { # Windows Tweaks
            # KIỂM TRA HÀM TỒN TẠI TRƯỚC KHI GỌI
            if (Get-Command Invoke-TweaksMenu -ErrorAction SilentlyContinue) {
                Invoke-TweaksMenu -Config $TweaksConfig
            } else {
                Write-Host "LOI: Khong tim thay ham 'Invoke-TweaksMenu'!" -ForegroundColor Red
                Write-Host "Kiem tra file tweaks.ps1 trong thu muc functions." -ForegroundColor Yellow
                Pause
            }
        }
        '2' { # DNS Management
            Invoke-DnsMenu
        }
        '3' { # Clean System
            Invoke-CleanSystem
        }
        '4' { # Install Applications
            Invoke-AppMenu -Config $AppsConfig
        }
        '5' { # Reload Config
            Clear-Host
            Write-Host "Dang tai lai cau hinh tu JSON..." -ForegroundColor Cyan
            $TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
            $AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
            $DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")
            Write-Host "Tai lai cau hinh thanh cong!" -ForegroundColor Green
            Pause
        }
        '0' { # Exit
            Clear-Host
            Write-Host "Cam on ban da su dung ToiUuPC!" -ForegroundColor Green
            Write-Host "Chuong trinh se dong trong 3 giay..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
            exit 0 # Thoát sạch sẽ
        }
        default {
            Write-Host "Lua chon khong hop le. Vui long nhap so tu 0 den 5." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}
