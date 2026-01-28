# ToiUuPC.ps1 - PMK Toolbox v3.0 (Modular)
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex

Clear-Host

# Kiểm tra & relaunch admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# Nạp functions (sửa path: loại bỏ dấu \ thừa ở đầu)
$scriptRoot = $PSScriptRoot
. "$scriptRoot\functions\Show-PMKLogo.ps1"
. "$scriptRoot\functions\utils.ps1"
. "$scriptRoot\functions\install-apps.ps1"
. "$scriptRoot\functions\dns-management.ps1"
. "$scriptRoot\functions\tweaks.ps1"

Show-PMKLogo

Write-Host "`nPMK Toolbox v3.0 - Modular Edition" -ForegroundColor Cyan
Write-Host "Đang tải cấu hình..." -ForegroundColor Yellow

# Test gọi hàm (sẽ mở rộng thành menu sau)
# Invoke-TweaksPerformance

Write-Host "`nHoàn tất khởi tạo. Chọn chức năng qua menu (sắp tới) hoặc chạy trực tiếp hàm." -ForegroundColor Green
Pause
