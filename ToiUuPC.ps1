# ToiUuPC.ps1 - PMK Toolbox v3.3.2-final (Remote-safe version)
# Author: Minh Khải (PMK) - https://www.facebook.com/khaiitcntt
# Run remote: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex

[CmdletBinding()]
param([switch]$Silent)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Optional console size
try {
    $Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size(100, 50)
    $Host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(100, 50)
} catch {}

# Admin check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# COLOR PALETTE
$global:TEXT_COLOR     = "White"
$global:HEADER_COLOR   = "Cyan"
$global:SUCCESS_COLOR  = "Green"
$global:ERROR_COLOR    = "Red"
$global:BORDER_COLOR   = "DarkGray"
$global:WARNING_COLOR  = "Yellow"

# Load functions - Local or Remote
$scriptDir = $PSScriptRoot

if ($scriptDir) {
    # Local
    . "$scriptDir\functions\Show-PMKLogo.ps1" -ErrorAction SilentlyContinue
    . "$scriptDir\functions\utils.ps1" -ErrorAction SilentlyContinue
    . "$scriptDir\functions\install-apps.ps1" -ErrorAction SilentlyContinue
    . "$scriptDir\functions\tweaks.ps1" -ErrorAction SilentlyContinue
    . "$scriptDir\functions\dns-management.ps1" -ErrorAction SilentlyContinue
    . "$scriptDir\functions\clean-system.ps1" -ErrorAction SilentlyContinue
} else {
    # Remote: Download from raw
    $base = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main/functions"
    $files = @("Show-PMKLogo.ps1", "utils.ps1", "install-apps.ps1", "tweaks.ps1", "dns-management.ps1", "clean-system.ps1")

    foreach ($f in $files) {
        try {
            Invoke-Expression (Invoke-RestMethod "$base/$f")
        } catch {
            Write-Host "Failed to load $f from remote: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Menu
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
    Write-Host "Nhập số lựa chọn (1-5) hoặc ESC thoát: " -NoNewline -ForegroundColor $HEADER_COLOR

    $input = Read-Host

    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq "Escape") { Write-Host "`nThoát..." -ForegroundColor $BORDER_COLOR; exit }
    }

    switch ($input) {
        "1" { if (Get-Command Install-AppsQuick -ErrorAction SilentlyContinue) { Install-AppsQuick } else { Write-Host "Chức năng chưa load" -ForegroundColor Yellow } }
        "2" { if (Get-Command Invoke-TweaksMenu -ErrorAction SilentlyContinue) { Invoke-TweaksMenu } else { Write-Host "Chức năng chưa load" -ForegroundColor Yellow } }
        "3" { if (Get-Command Invoke-CleanSystem -ErrorAction SilentlyContinue) { Invoke-CleanSystem } else { Write-Host "Chức năng chưa load" -ForegroundColor Yellow } }
        "4" { if (Get-Command Set-DNSServerMenu -ErrorAction SilentlyContinue) { Set-DNSServerMenu } else { Write-Host "Chức năng chưa load" -ForegroundColor Yellow } }
        "5" { Write-Host "Tạm biệt!" -ForegroundColor $HEADER_COLOR; exit }
        default { Write-Host "Lựa chọn sai!" -ForegroundColor $ERROR_COLOR; Start-Sleep 1 }
    }
} while ($true)