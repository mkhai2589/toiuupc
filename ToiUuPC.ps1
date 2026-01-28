# ToiUuPC.ps1 - PMK Toolbox v3.0 (Online/Remote Optimized Only)
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Thuthuatwiki (PMK) - Enhanced for online use
# Version: 3.0 - Full console menu, dark theme, no local/folder dependency

Clear-Host

# Kiểm tra & relaunch admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# Dark theme console đẹp
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# Logo
$logo = @"
╔══════════════════════════════════════════════════════════════════════════╗
║ ██████╗ ███╗ ███╗██╗ ██╗ ████████╗ ██████╗ ██████╗ ██╗ ║
║ ██╔══██╗████╗ ████║██║ ██╔╝ ╚══██╔══╝██╔═══██╗██╔═══██╗██║ ║
║ ██████╔╝██╔████╔██║█████╔╝ ██║ ██║ ██║██║ ██║██║ ║
║ ██╔═══╝ ██║╚██╔╝██║██╔═██╗ ██║ ██║ ██║██║ ██║██║ ║
║ ██║ ██║ ╚═╝ ██║██║ ██╗ ██║ ╚██████╔╝╚██████╔╝███████╗ ║
║ ╚═╝ ╚═╝ ╚═╝╚═╝ ╚═╝ ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝ ║
║ PMK TOOLBOX - Tối ưu Windows ║
║ Phiên bản: 3.0 | Windows 10/11 ║
╚══════════════════════════════════════════════════════════════════════════╝
"@
Write-Host $logo -ForegroundColor Cyan

Write-Host "`nPMK Toolbox v3.0 - Online/Remote Mode" -ForegroundColor Cyan
Write-Host "Chạy online: Console menu đầy đủ" -ForegroundColor Yellow

# Hàm cơ bản hardcode
function Test-Winget {
    try {
        winget --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Install-AppQuick {
    Write-Host "Nhập Winget IDs (dùng dấu phẩy, ví dụ: Brave.Brave,Discord.Discord):" -ForegroundColor Yellow
    $ids = Read-Host
    if ($ids) {
        foreach ($id in $ids.Split(',')) {
            $id = $id.Trim()
            if ($id) {
                Write-Host "Đang cài $id..." -ForegroundColor Yellow
                try {
                    winget install --id $id --silent --accept-package-agreements --accept-source-agreements
                    Write-Host "✅ Cài xong: $id" -ForegroundColor Green
                } catch {
                    Write-Host "❌ Lỗi cài ${id}: $_" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "Không có ID nào được nhập." -ForegroundColor Yellow
    }
}

function Disable-TelemetryQuick {
    Write-Host "Tắt Telemetry nhanh..." -ForegroundColor Yellow
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Force -ErrorAction Stop
        Write-Host "✅ Telemetry đã tắt (cần reboot để apply đầy đủ)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Lỗi: $_" -ForegroundColor Red
    }
}

function Clean-TempFiles {
    Write-Host "Xóa file tạm..." -ForegroundColor Yellow
    try {
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Đã xóa file tạm" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Lỗi khi xóa file tạm: $_" -ForegroundColor Red
    }
}

function Disable-UnneededServices {
    Write-Host "Tắt dịch vụ không cần thiết..." -ForegroundColor Yellow
    $services = @("DiagTrack", "dmwappushservice", "WMPNetworkSvc", "RemoteRegistry", "XblAuthManager", "XblGameSave", "XboxNetApiSvc")
    foreach ($service in $services) {
        try {
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Write-Host "✅ Đã tắt $service" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Không tắt được $service" -ForegroundColor Yellow
        }
    }
}

function Create-RestorePoint {
    Write-Host "Tạo điểm khôi phục hệ thống..." -ForegroundColor Yellow
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "PMK Toolbox - $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host "✅ Đã tạo điểm khôi phục" -ForegroundColor Green
    } catch {
        Write-Host "❌ Lỗi tạo điểm khôi phục: $_" -ForegroundColor Red
    }
}

# Menu console đầy đủ
do {
    Clear-Host
    Write-Host $logo -ForegroundColor Cyan
    Write-Host "`n=== MENU PMK TOOLBOX (Online Mode) ===" -ForegroundColor Green
    Write-Host "1. Kiểm tra Winget" -ForegroundColor White
    Write-Host "2. Cài app nhanh (nhập Winget IDs)" -ForegroundColor White
    Write-Host "3. Tắt Telemetry nhanh" -ForegroundColor White
    Write-Host "4. Xóa file tạm" -ForegroundColor White
    Write-Host "5. Tắt dịch vụ không cần thiết" -ForegroundColor White
    Write-Host "6. Tạo điểm khôi phục" -ForegroundColor White
    Write-Host "7. Thoát" -ForegroundColor White
    $choice = Read-Host "`nChọn (1-7)"

    switch ($choice) {
        "1" {
            if (Test-Winget) { Write-Host "✅ Winget đã sẵn sàng!" -ForegroundColor Green }
            else { Write-Host "❌ Winget chưa cài. Cài từ Microsoft Store hoặc chạy 'winget install --id Microsoft.Winget.CLI'" -ForegroundColor Red }
            Pause
        }
        "2" { Install-AppQuick; Pause }
        "3" { Disable-TelemetryQuick; Pause }
        "4" { Clean-TempFiles; Pause }
        "5" { Disable-UnneededServices; Pause }
        "6" { Create-RestorePoint; Pause }
        "7" { Write-Host "Thoát..." -ForegroundColor Cyan; exit }
        default { Write-Host "Lựa chọn sai!" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice -ne "7")
