# ToiUuPC.ps1 - PMK Toolbox v3.3.2-final
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Minh Khải (PMK) - https://www.facebook.com/khaiitcntt
# Version: 3.3.2-final - Modular structure, functions separated, fixed input + ESC, exact logo

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Cố định kích thước console (padding & không cho kéo thay đổi)
try {
    $Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size(100, 50)
    $Host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(100, 50)
} catch {}

# Kiểm tra quyền Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# ===== COLOR PALETTE =====
$TEXT_COLOR     = "White"
$HEADER_COLOR   = "Cyan"        # Tiêu đề, STT, dòng nhập, progress
$SUCCESS_COLOR  = "Green"
$ERROR_COLOR    = "Red"
$BORDER_COLOR   = "DarkGray"
$WARNING_COLOR  = "Yellow"

# Reset console
function Reset-ConsoleStyle {
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = $TEXT_COLOR
    Clear-Host
}

# Logo
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


# Load các file chức năng (dot-source)
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }  # fallback khi chạy từ URL

. "$scriptDir\functions\Show-PMKLogo.ps1"
. "$scriptDir\functions\utils.ps1"
. "$scriptDir\functions\install-apps.ps1"
. "$scriptDir\functions\tweaks.ps1"
. "$scriptDir\functions\dns-management.ps1"

# Menu chính
do {
    Reset-ConsoleStyle
    Show-PMKLogo  # gọi logo từ file riêng
    Show-SystemHeader

    Write-Host "MENU CHÍNH - PMK TOOLBOX" -ForegroundColor $HEADER_COLOR
    Write-Host "=========================" -ForegroundColor $BORDER_COLOR
    Write-Host ""

    Write-Host " [1] Cài đặt ứng dụng nhanh" -ForegroundColor $HEADER_COLOR
    Write-Host " [2] Vô hiệu hóa Telemetry & Tweaks" -ForegroundColor $HEADER_COLOR
    Write-Host " [3] Dọn dẹp file tạm & hệ thống" -ForegroundColor $HEADER_COLOR
    Write-Host " [4] Quản lý DNS & mạng" -ForegroundColor $HEADER_COLOR
    Write-Host " [5] Thoát" -ForegroundColor $HEADER_COLOR

    Write-Host ""
    Write-Host "Nhập số lựa chọn (1-5) rồi nhấn Enter (hoặc ESC để thoát): " -NoNewline -ForegroundColor $HEADER_COLOR

    $input = Read-Host

    # Kiểm tra ESC sau khi nhập
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq "Escape") {
            Write-Host "`nThoát chương trình..." -ForegroundColor $BORDER_COLOR
            exit
        }
    }

    switch ($input) {
        "1" { Install-AppsQuick }
        "2" { Apply-Tweaks }
        "3" { Clean-System }
        "4" { Manage-DNS }
        "5" { Write-Host "Tạm biệt! Cảm ơn đã sử dụng PMK Toolbox!" -ForegroundColor $HEADER_COLOR; exit }
        default { Write-Host "Lựa chọn không hợp lệ! Vui lòng chọn 1-5" -ForegroundColor $ERROR_COLOR; Start-Sleep 1 }
    }
} while ($true)
