# ToiUuPC.ps1 - PMK Toolbox v3.3.2-final (Fixed remote load 2026)
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex

[CmdletBinding()]
param([switch]$Silent)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Admin check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# Colors (hardcode trước để tránh null)
$global:TEXT_COLOR     = "White"
$global:HEADER_COLOR   = "Cyan"
$global:SUCCESS_COLOR  = "Green"
$global:ERROR_COLOR    = "Red"
$global:BORDER_COLOR   = "DarkGray"
$global:WARNING_COLOR  = "Yellow"

# Load functions - Local or Remote safe
$scriptDir = $PSScriptRoot

if ($scriptDir -and (Test-Path "$scriptDir\functions")) {
    # Local mode
    . "$scriptDir\functions\Show-PMKLogo.ps1" -ErrorAction SilentlyContinue
    . "$scriptDir\functions\utils.ps1" -ErrorAction SilentlyContinue
    . "$scriptDir\functions\install-apps.ps1" -ErrorAction SilentlyContinue
    . "$scriptDir\functions\tweaks.ps1" -ErrorAction SilentlyContinue
    . "$scriptDir\functions\dns-management.ps1" -ErrorAction SilentlyContinue
    . "$scriptDir\functions\clean-system.ps1" -ErrorAction SilentlyContinue
} else {
    # Remote mode - load with better error handling
    $base = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main/functions"
    $files = @(
        "Show-PMKLogo.ps1",
        "utils.ps1",
        "install-apps.ps1",
        "tweaks.ps1",
        "dns-management.ps1",
        "clean-system.ps1"
    )

    foreach ($file in $files) {
        try {
            $url = "$base/$file"
            $content = (Invoke-RestMethod -Uri $url -UseBasicParsing)
            Invoke-Expression $content
        } catch {
            Write-Host "Không tải được $file: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# Fallback functions nếu load thất bại
if (-not (Get-Command Reset-ConsoleStyle -ErrorAction SilentlyContinue)) {
    function Reset-ConsoleStyle { Clear-Host }
}

# Menu chính
do {
    Reset-ConsoleStyle
    if (Get-Command Show-PMKLogo -ErrorAction SilentlyContinue) { Show-PMKLogo }
    if (Get-Command Show-SystemHeader -ErrorAction SilentlyContinue) { Show-SystemHeader }

    Write-Host "MENU CHÍNH - PMK TOOLBOX" -ForegroundColor $HEADER_COLOR
    Write-Host "=========================" -ForegroundColor $BORDER_COLOR
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
        if ($key.Key -eq [ConsoleKey]::Escape) {
            Write-Host "`nThoát chương trình..." -ForegroundColor $BORDER_COLOR
            exit
        }
    }

    switch ($input.Trim()) {
        "1" { if (Get-Command Install-AppsQuick -ErrorAction SilentlyContinue) { Install-AppsQuick } else { Write-Host "Chức năng chưa sẵn sàng" -ForegroundColor Yellow } }
        "2" { if (Get-Command Invoke-TweaksMenu -ErrorAction SilentlyContinue) { Invoke-TweaksMenu } else { Write-Host "Chức năng chưa sẵn sàng" -ForegroundColor Yellow } }
        "3" { if (Get-Command Invoke-CleanSystem -ErrorAction SilentlyContinue) { Invoke-CleanSystem } else { Write-Host "Chức năng chưa sẵn sàng" -ForegroundColor Yellow } }
        "4" { if (Get-Command Set-DNSServerMenu -ErrorAction SilentlyContinue) { Set-DNSServerMenu } else { Write-Host "Chức năng chưa sẵn sàng" -ForegroundColor Yellow } }
        "5" { Write-Host "Tạm biệt! Cảm ơn đã sử dụng PMK Toolbox!" -ForegroundColor $HEADER_COLOR; exit }
        default { Write-Host "Lựa chọn không hợp lệ!" -ForegroundColor $ERROR_COLOR; Start-Sleep 1 }
    }
} while ($true)