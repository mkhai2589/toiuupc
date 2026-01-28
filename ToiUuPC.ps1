# ToiUuPC.ps1 - PMK Toolbox v3.0 (Modular & Remote Compatible)
# Run: irm bit.ly/pmktool | iex

Clear-Host

# Kiểm tra & relaunch admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# Kiểm tra mode: Local hay Remote
if ($PSScriptRoot) {
    # Local: dot-source functions
    . "$PSScriptRoot\functions\show-pmklogo.ps1"
    . "$PSScriptRoot\functions\utils.ps1"
    . "$PSScriptRoot\functions\install-apps.ps1"
    . "$PSScriptRoot\functions\dns-management.ps1"
    . "$PSScriptRoot\functions\tweaks.ps1"
} else {
    # Remote fallback: Hardcode logo, thông báo limit
    function Show-PMKLogo {
        $logo = @"
╔══════════════════════════════════════════════════════════════════════════╗
║ ██████╗ ███╗ ███╗██╗ ██╗ ████████╗ ██████╗ ██████╗ ██╗ ║
║ ██╔══██╗████╗ ████║██║ ██╔╝ ╚══██╔══╝██╔═══██╗██╔═══██╗██║ ║
║ ██████╔╝██╔████╔██║█████╔╝ ██║ ██║ ██║██║ ██║██║ ║
║ ██╔═══╝ ██║╚██╔╝██║██╔═██╗ ██║ ██║ ██║██║ ██║██║ ║
║ ██║ ██║ ╚═╝ ██║██║ ██╗ ██║ ╚██████╔╝╚██████╔╝███████╗ ║
║ ╚═╝ ╚═╝ ╚═╝╚═╝ ╚═╝ ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝ ║
║ PMK Toolbox - Tối ưu Windows ║
║ Phiên bản: 3.0 | Windows 10/11 ║
╚══════════════════════════════════════════════════════════════════════════╝
"@
        Write-Host $logo -ForegroundColor Cyan
    }
    Write-Host "`nChế độ Remote: Chức năng giới hạn. Tải repo để dùng đầy đủ." -ForegroundColor Yellow
}

Show-PMKLogo

Write-Host "`nPMK Toolbox v3.0 - Modular Edition" -ForegroundColor Cyan
Write-Host "Đang tải cấu hình..." -ForegroundColor Yellow

# Load WPF nếu có (fallback console nếu fail)
try {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    $mainWindow = Create-MainWindow
    $mainWindow.ShowDialog() | Out-Null
} catch {
    Write-Host "❌ Lỗi GUI: $($_.Exception.Message). Chuyển console." -ForegroundColor Red
    Show-ConsoleMenu
}

# Console fallback (từ code cũ, tối ưu)
function Show-ConsoleMenu {
    do {
        Clear-Host
        Show-PMKLogo
        Write-Host "`n=== MENU DÒNG LỆNH ===" -ForegroundColor Green
        Write-Host "1. Hiển thị thông tin hệ thống"
        Write-Host "2. Cài đặt ứng dụng (cần winget)"
        Write-Host "3. Áp dụng tweaks"
        Write-Host "4. Quản lý DNS"
        Write-Host "5. Thoát"
        $choice = Read-Host "Chọn (1-5)"

        switch ($choice) {
            "1" { Get-SystemInfoText | Write-Host -ForegroundColor Cyan; Pause }
            "2" { Install-SelectedApps; Pause }
            "3" { Invoke-TweaksMenu; Pause }
            "4" { Set-DNSServerMenu; Pause }
            "5" { exit }
            default { Write-Host "Lựa chọn sai!" -ForegroundColor Red; Start-Sleep 1 }
        }
    } while ($choice -ne "5")
}
