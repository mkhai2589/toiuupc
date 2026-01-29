# ToiUuPC.ps1 - PMK Toolbox v3.3.2-final
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Minh Khải (PMK) - https://www.facebook.com/khaiitcntt
# Version: 3.3.2-final - Modular, fixed logo, input + ESC

[CmdletBinding()]
param([switch]$Silent)  # Thêm param cho silent mode

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Optional console size (không force nếu error)
try {
    $Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size(100, 50)
    $Host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(100, 50)
} catch { Write-Verbose "Console size not set: $_" }

# Admin check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# Load functions
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }  # fallback remote

. "$scriptDir\functions\Show-PMKLogo.ps1"
. "$scriptDir\functions\utils.ps1"
. "$scriptDir\functions\install-apps.ps1"
. "$scriptDir\functions\tweaks.ps1"
. "$scriptDir\functions\dns-management.ps1"
. "$scriptDir\functions\clean-system.ps1"  # Thêm

# Menu chính (sửa calls: Invoke-TweaksMenu, Invoke-CleanSystem, Set-DNSServerMenu)
do {
    Reset-ConsoleStyle
    Show-PMKLogo
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

    # ESC check
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Escape) {
            Write-Host "`nThoát chương trình..." -ForegroundColor $BORDER_COLOR
            exit
        }
    }

    switch ($input) {
        "1" { Install-AppsQuick }
        "2" { Invoke-TweaksMenu }
        "3" { Invoke-CleanSystem }
        "4" { Set-DNSServerMenu }
        "5" { Write-Host "Tạm biệt! Cảm ơn đã sử dụng PMK Toolbox!" -ForegroundColor $HEADER_COLOR; exit }
        default { Write-Host "Lựa chọn không hợp lệ! Vui lòng chọn 1-5" -ForegroundColor $ERROR_COLOR; Start-Sleep 1 }
    }
} while ($true)