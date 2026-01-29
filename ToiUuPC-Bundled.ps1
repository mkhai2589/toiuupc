# ToiUuPC-Bundled.ps1 - PMK Toolbox v3.3.2-final (Bundled, Remote-ready)
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC-Bundled.ps1 | iex
# Author: Minh Khải (PMK)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Admin check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Admin!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# Colors
$TEXT_COLOR     = "White"
$HEADER_COLOR   = "Cyan"
$SUCCESS_COLOR  = "Green"
$ERROR_COLOR    = "Red"
$BORDER_COLOR   = "DarkGray"
$WARNING_COLOR  = "Yellow"

# Logo
function Show-PMKLogo {
    $logo = @"
╔══════════════════════════════════════════════════════════════════════════╗
║ ██████╗ ███╗   ███╗██╗  ██╗      ████████╗ ██████╗  ██████╗ ██╗          ║
║ ██╔══██╗████╗ ████║██║ ██╔╝      ╚══██╔══╝██╔═══██╗██╔═══██╗██║          ║
║ ██████╔╝██╔████╔██║█████╔╝          ██║   ██║   ██║██║   ██║██║          ║
║ ██╔═══╝ ██║╚██╔╝██║██╔═██╗          ██║   ██║   ██║██║   ██║██║          ║
║ ██║     ██║ ╚═╝ ██║██║  ██╗         ██║   ╚██████╔╝╚██████╔╝███████╗     ║
║ ╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝         ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝     ║
║                 PMK Toolbox - Tối ưu Windows                             ║
╚══════════════════════════════════════════════════════════════════════════╝
"@
    Write-Host $logo -ForegroundColor $HEADER_COLOR
}

# Basic utils
function Reset-ConsoleStyle {
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = $TEXT_COLOR
    Clear-Host
}

# Sample menu functions (thay bằng full khi compile)
function Install-AppsQuick { Write-Host "Cài app (sample)" -ForegroundColor $SUCCESS_COLOR; Start-Sleep 1 }
function Invoke-TweaksMenu { Write-Host "Tweaks (sample)" -ForegroundColor $SUCCESS_COLOR; Start-Sleep 1 }
function Invoke-CleanSystem { Write-Host "Dọn dẹp (sample)" -ForegroundColor $SUCCESS_COLOR; Start-Sleep 1 }
function Set-DNSServerMenu { Write-Host "DNS (sample)" -ForegroundColor $SUCCESS_COLOR; Start-Sleep 1 }

# Main loop
do {
    Reset-ConsoleStyle
    Show-PMKLogo

    Write-Host "`nPMK Toolbox v3.3.2 - Bundled Mode" -ForegroundColor $HEADER_COLOR
    Write-Host "====================================" -ForegroundColor $BORDER_COLOR
    Write-Host ""
    Write-Host " [1] Cài đặt ứng dụng nhanh" -ForegroundColor $HEADER_COLOR
    Write-Host " [2] Vô hiệu hóa Telemetry & Tweaks" -ForegroundColor $HEADER_COLOR
    Write-Host " [3] Dọn dẹp file tạm & hệ thống" -ForegroundColor $HEADER_COLOR
    Write-Host " [4] Quản lý DNS & mạng" -ForegroundColor $HEADER_COLOR
    Write-Host " [5] Thoát" -ForegroundColor $HEADER_COLOR
    Write-Host ""
    Write-Host "Nhập số (1-5) hoặc ESC thoát: " -NoNewline -ForegroundColor $HEADER_COLOR

    $input = Read-Host

    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq "Escape") {
            Write-Host "`nThoát..." -ForegroundColor $BORDER_COLOR
            exit
        }
    }

    switch ($input) {
        "1" { Install-AppsQuick }
        "2" { Invoke-TweaksMenu }
        "3" { Invoke-CleanSystem }
        "4" { Set-DNSServerMenu }
        "5" { Write-Host "Tạm biệt!" -ForegroundColor $HEADER_COLOR; exit }
        default { Write-Host "Lựa chọn sai!" -ForegroundColor $ERROR_COLOR; Start-Sleep 1 }
    }
} while ($true)