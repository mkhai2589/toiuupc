# ToiUuPC-Bundled.ps1 - PMK Toolbox v3.0 (One-File for one-liner/remote)
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC-Bundled.ps1 | iex

Clear-Host

# Admin check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Admin!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# Logo hardcode (dùng cho remote)
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

Show-PMKLogo

Write-Host "`nPMK Toolbox v3.0 - Remote Bundled Mode" -ForegroundColor Cyan
Write-Host "Chế độ Remote: Hỗ trợ console cơ bản (GUI đầy đủ chỉ khi chạy local)" -ForegroundColor Yellow

# Hardcode basic functions (từ utils.ps1)
function Test-Winget {
    try { winget --version | Out-Null; return $true } catch { return $false }
}

function Get-SystemInfoText {
    "Remote mode: Không lấy info đầy đủ. Tải repo về để dùng." 
}

# Console menu đơn giản cho remote
do {
    Clear-Host
    Show-PMKLogo
    Write-Host "`n=== MENU REMOTE CƠ BẢN ===" -ForegroundColor Green
    Write-Host "1. Kiểm tra Winget"
    Write-Host "2. Thông tin hệ thống (cơ bản)"
    Write-Host "3. Thoát"
    $choice = Read-Host "Chọn (1-3)"

    switch ($choice) {
        "1" { if (Test-Winget) { Write-Host "Winget OK" -ForegroundColor Green } else { Write-Host "Winget chưa cài" -ForegroundColor Red }; Pause }
        "2" { Write-Host (Get-SystemInfoText) -ForegroundColor Cyan; Pause }
        "3" { exit }
        default { Write-Host "Lựa chọn sai!" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice -ne "3")
