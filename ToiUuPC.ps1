# ToiUuPC.ps1 - PMK Toolbox v3.0 (Modular & Remote Compatible)

Clear-Host

# Kiểm tra & relaunch admin (giữ nguyên)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# Logo hardcode fallback cho remote mode
function Show-PMKLogo {
    $logo = @"
╔══════════════════════════════════════════════════════════════════════════╗
║   ██████╗ ███╗   ███╗██╗  ██╗      ████████╗ ██████╗  ██████╗ ██╗       ║
║   ██╔══██╗████╗ ████║██║ ██╔╝      ╚══██╔══╝██╔═══██╗██╔═══██╗██║       ║
║   ██████╔╝██╔████╔██║█████╔╝          ██║   ██║   ██║██║   ██║██║       ║
║   ██╔═══╝ ██║╚██╔╝██║██╔═██╗          ██║   ██║   ██║██║   ██║██║       ║
║   ██║     ██║ ╚═╝ ██║██║  ██╗         ██║   ╚██████╔╝╚██████╔╝███████╗  ║
║   ╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝         ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝  ║
║                        PMK Toolbox - Tối ưu Windows                      ║
║                    Phiên bản: 3.0 | Windows 10/11                        ║
╚══════════════════════════════════════════════════════════════════════════╝
"@
    Write-Host $logo -ForegroundColor Cyan
}

# Kiểm tra mode: Local (có $PSScriptRoot) hay Remote (irm | iex)
if ($PSScriptRoot) {
    # Local mode: dot-source functions
    . "$PSScriptRoot\functions\Show-PMKLogo.ps1"  # Nếu bạn đã tách logo riêng
    . "$PSScriptRoot\functions\utils.ps1"
    . "$PSScriptRoot\functions\install-apps.ps1"
    . "$PSScriptRoot\functions\dns-management.ps1"
    . "$PSScriptRoot\functions\tweaks.ps1"
    # Gọi function từ file nếu có
    Show-PMKLogo  # Hoặc dùng fallback nếu file không tồn tại
} else {
    # Remote mode: dùng fallback logo + thông báo
    Show-PMKLogo
    Write-Host "`nChế độ Remote (one-liner): Chức năng modular chưa load đầy đủ." -ForegroundColor Yellow
    Write-Host "Để dùng đầy đủ, tải repo về máy và chạy local." -ForegroundColor Yellow
}

Write-Host "`nPMK Toolbox v3.0 - Modular Edition" -ForegroundColor Cyan
Write-Host "Đang tải cấu hình..." -ForegroundColor Yellow

# Thêm menu console đơn giản hoặc gọi hàm test
Write-Host "1. Chạy tweaks hiệu suất"
Write-Host "2. Cài apps"
Write-Host "Q. Thoát"
$choice = Read-Host "Chọn"

# ... logic menu sau

Write-Host "`nHoàn tất khởi tạo." -ForegroundColor Green
Pause
