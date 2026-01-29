# =========================================================
# ToiUuPC – Main Controller
# Windows 10 / 11 Optimization Toolkit
# Author: PMK
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------
# ADMIN CHECK
# ---------------------------------------------------------
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "❌ Vui lòng chạy PowerShell với quyền Administrator" -ForegroundColor Red
    Pause
    exit 1
}

# ---------------------------------------------------------
# PATHS
# ---------------------------------------------------------
$Root      = Split-Path -Parent $MyInvocation.MyCommand.Path
$Assets    = Join-Path $Root "assets"
$Config    = Join-Path $Root "config"
$Functions = Join-Path $Root "functions"
$Logs      = Join-Path $Root "logs"
$Backup    = Join-Path $Root "backup"

# Ensure dirs
foreach ($dir in @($Logs, $Backup)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

# ---------------------------------------------------------
# LOAD ENGINES
# ---------------------------------------------------------
$FunctionFiles = @(
    "utils.ps1"
    "Show-PMKLogo.ps1"
    "tweaks.ps1"
    "install-apps.ps1"
    "dns-management.ps1"
    "clean-system.ps1"
)

foreach ($file in $FunctionFiles) {
    $path = Join-Path $Functions $file
    if (Test-Path $path) {
        . $path
    } else {
        Write-Host "❌ Thiếu file bắt buộc: $file" -ForegroundColor Red
        Pause
        exit 1
    }
}

# ---------------------------------------------------------
# MAIN MENU
# ---------------------------------------------------------
function Show-MainMenu {
    Clear-Host
    if (Get-Command Show-PMKLogo -ErrorAction SilentlyContinue) {
        Show-PMKLogo
    }

    Write-Host "=================================================" -ForegroundColor DarkGray
    Write-Host "  ToiUuPC – Tối ưu Windows 10 / 11" -ForegroundColor Cyan
    Write-Host "=================================================`n"

    Write-Host "1. ⚙️  Tối ưu hệ thống (Tweaks)"
    Write-Host "2. 📦 Cài đặt ứng dụng (Winget)"
    Write-Host "3. 🌐 Thiết lập DNS"
    Write-Host "4. 🧹 Dọn dẹp hệ thống"
    Write-Host "5. ⏪ Rollback tweaks gần nhất"
    Write-Host "0. ❌ Thoát`n"
}

# ---------------------------------------------------------
# TWEAK SUB MENU
# ---------------------------------------------------------
function Show-TweakMenu {
    Clear-Host
    Write-Host "▶ TỐI ƯU HỆ THỐNG (TWEAKS)" -ForegroundColor Cyan
    Write-Host "--------------------------------------"
    Write-Host "1. Áp dụng preset"
    Write-Host "2. Áp dụng theo category"
    Write-Host "3. Áp dụng theo ID tweak"
    Write-Host "0. Quay lại`n"
}

function Menu-TweakPreset {
    Write-Host "`nChọn preset:"
    Write-Host "1. Privacy  – Quyền riêng tư"
    Write-Host "2. Gaming   – Hiệu năng / FPS"
    Write-Host "3. Office   – Ổn định / bảo mật"

    $c = Read-Host "👉 Lựa chọn"

    switch ($c) {
        "1" { Invoke-TweaksEngine -Preset "Privacy" }
        "2" { Invoke-TweaksEngine -Preset "Gaming" }
        "3" { Invoke-TweaksEngine -Preset "Office" }
        default {
            Write-Host "❌ Lựa chọn không hợp lệ" -ForegroundColor Yellow
        }
    }
}

function Menu-TweakCategory {
    $file = Join-Path $Config "tweaks.json"
    if (-not (Test-Path $file)) {
        Write-Host "❌ Không tìm thấy tweaks.json" -ForegroundColor Red
        return
    }

    $json = Get-Content $file -Raw | ConvertFrom-Json
    $cats = $json.tweaks | Select-Object -ExpandProperty category -Unique | Sort-Object

    Write-Host ""
    for ($i = 0; $i -lt $cats.Count; $i++) {
        Write-Host "$($i + 1). $($cats[$i])"
    }

    $sel = Read-Host "👉 Chọn category"
    if ($sel -match '^\d+$') {
        $cat = $cats[[int]$sel - 1]
        if ($cat) {
            $ids = $json.tweaks |
                Where-Object { $_.category -eq $cat } |
                Select-Object -ExpandProperty id

            Invoke-TweaksEngine -Ids $ids
        }
    }
}

function Menu-TweakById {
    $ids = Read-Host "Nhập ID tweak (phân tách bằng dấu ,)"
    if ($ids) {
        $arr = $ids.Split(",") | ForEach-Object { $_.Trim() }
        Invoke-TweaksEngine -Ids $arr
    }
}

# ---------------------------------------------------------
# MAIN LOOP
# ---------------------------------------------------------
while ($true) {

    Show-MainMenu
    $choice = Read-Host "👉 Chọn chức năng"

    switch ($choice) {

        "1" {
            while ($true) {
                Show-TweakMenu
                $t = Read-Host "👉 Chọn"

                switch ($t) {
                    "1" { Menu-TweakPreset }
                    "2" { Menu-TweakCategory }
                    "3" { Menu-TweakById }
                    "0" { break }
                    default {
                        Write-Host "❌ Lựa chọn không hợp lệ" -ForegroundColor Yellow
                    }
                }
                Pause
            }
        }

        "2" {
            Clear-Host
            Write-Host "▶ CÀI ĐẶT ỨNG DỤNG" -ForegroundColor Cyan
            Invoke-InstallApps
            Pause
        }

        "3" {
            Clear-Host
            Write-Host "▶ THIẾT LẬP DNS" -ForegroundColor Cyan
            Invoke-DNSManager
            Pause
        }

        "4" {
            Clear-Host
            Write-Host "▶ DỌN DẸP HỆ THỐNG" -ForegroundColor Cyan
            Invoke-CleanSystem -All
            Pause
        }

        "5" {
            Clear-Host
            Write-Host "▶ ROLLBACK TWEAKS" -ForegroundColor Yellow
            Invoke-TweaksEngine -Rollback
            Pause
        }

        "0" {
            Write-Host "`n👋 Thoát ToiUuPC. Hẹn gặp lại!" -ForegroundColor Green
            break
        }

        default {
            Write-Host "❌ Lựa chọn không hợp lệ" -ForegroundColor Red
            Start-Sleep 1
        }
    }
}
