# ToiUuPC.ps1 - PMK Toolbox v3.3.2-final (Remote-safe version)
# Run local: .\ToiUuPC.ps1
# Run remote: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Minh Khải (PMK) - https://www.facebook.com/khaiitcntt

[CmdletBinding()]
param([switch]$Silent)  # Hỗ trợ chạy silent nếu cần sau này

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Optional console size (không force nếu error)
try {
    $Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size(100, 50)
    $Host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(100, 50)
} catch { Write-Verbose "Console size not set: $_" }

# Kiểm tra quyền Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# ────────────────────────────────────────────────────────────────
# Load functions - Hỗ trợ cả LOCAL và REMOTE
# ────────────────────────────────────────────────────────────────
$scriptDir = $PSScriptRoot

if ($scriptDir) {
    # Local mode: dot-source từ folder functions
    Write-Verbose "Local mode detected - loading from disk"
    . "$scriptDir\functions\Show-PMKLogo.ps1"
    . "$scriptDir\functions\utils.ps1"
    . "$scriptDir\functions\install-apps.ps1"
    . "$scriptDir\functions\tweaks.ps1"
    . "$scriptDir\functions\dns-management.ps1"
    . "$scriptDir\functions\clean-system.ps1"
}
else {
    # Remote mode: tải functions trực tiếp từ GitHub raw
    Write-Verbose "Remote mode detected - loading from GitHub raw"
    $baseUrl = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main/functions"
    $functionFiles = @(
        "Show-PMKLogo.ps1",
        "utils.ps1",
        "install-apps.ps1",
        "tweaks.ps1",
        "dns-management.ps1",
        "clean-system.ps1"
    )

    foreach ($file in $functionFiles) {
        try {
            $url = "$baseUrl/$file"
            $content = Invoke-RestMethod -Uri $url -UseBasicParsing -ErrorAction Stop
            . ([ScriptBlock]::Create($content))
            Write-Verbose "Loaded remote function: $file"
        }
        catch {
            Write-Host "LỖI: Không thể tải function $file từ $url" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor DarkRed
            exit 1
        }
    }
}

# ────────────────────────────────────────────────────────────────
# Menu chính
# ────────────────────────────────────────────────────────────────
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

    # ESC check (robust hơn)
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