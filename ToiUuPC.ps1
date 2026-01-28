# ToiUuPC.ps1 - PMK Toolbox v3.0 (Online/Remote Optimized Only)
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Thuthuatwiki (PMK) - Enhanced for online use
# Version: 3.0 - Modern console UI, app list with STT, no local dependency

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

# Logo hiện đại
$logo = @"
╔══════════════════════════════════════════════════════════════════════════╗
║ ██████╗ ███╗   ███╗██╗  ██╗      ████████╗ ██████╗  ██████╗ ██╗       ║
║ ██╔══██╗████╗ ████║██║ ██╔╝      ╚══██╔══╝██╔═══██╗██╔═══██╗██║       ║
║ ██████╔╝██╔████╔██║█████╔╝          ██║   ██║   ██║██║   ██║██║       ║
║ ██╔═══╝ ██║╚██╔╝██║██╔═██╗          ██║   ██║   ██║██║   ██║██║       ║
║ ██║     ██║ ╚═╝ ██║██║  ██╗         ██║   ╚██████╔╝╚██████╔╝███████╗  ║
║ ╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝         ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝  ║
║                        PMK TOOLBOX - Tối ưu Windows                      ║
║                    Phiên bản: 3.0 | Windows 10/11                        ║
╚══════════════════════════════════════════════════════════════════════════╝
"@
Write-Host $logo -ForegroundColor Cyan

Write-Host "`nPMK Toolbox v3.0 - Online Mode" -ForegroundColor Cyan
Write-Host "Menu console hiện đại - Chọn số để thực hiện" -ForegroundColor Green

# Hàm cơ bản hardcode
function Test-Winget {
    try { winget --version | Out-Null; return $true } catch { return $false }
}

# Danh sách app hardcode (từ config/applications.json cũ) để hiển thị STT
$AppList = @(
    @{STT=1; Name="Brave"; ID="Brave.Brave"; Icon="🚀"},
    @{STT=2; Name="Google Chrome"; ID="Google.Chrome"; Icon="🔍"},
    @{STT=3; Name="Firefox"; ID="Mozilla.Firefox"; Icon="🦊"},
    @{STT=4; Name="Discord"; ID="Discord.Discord"; Icon="🎮"},
    @{STT=5; Name="Telegram"; ID="Telegram.TelegramDesktop"; Icon="✈️"},
    @{STT=6; Name="Visual Studio Code"; ID="Microsoft.VisualStudioCode"; Icon="📝"},
    @{STT=7; Name="Git"; ID="Git.Git"; Icon="🌿"},
    @{STT=8; Name="Python 3"; ID="Python.Python.3.12"; Icon="🐍"},
    @{STT=9; Name="7-Zip"; ID="7zip.7zip"; Icon="🗜️"},
    @{STT=10; Name="PowerToys"; ID="Microsoft.PowerToys"; Icon="🛠️"}
)

function Install-AppQuick {
    Write-Host "`nDanh sách app phổ biến (chọn bằng STT, ví dụ: 1,4,7):" -ForegroundColor Cyan
    foreach ($app in $AppList) {
        Write-Host "$($app.STT). $($app.Icon) $($app.Name) ($($app.ID))" -ForegroundColor White
    }
    Write-Host "`nNhập STT (dùng dấu phẩy nếu nhiều):" -ForegroundColor Yellow
    $sttInput = Read-Host
    if ($sttInput) {
        foreach ($stt in $sttInput.Split(',')) {
            $stt = $stt.Trim()
            if ($stt -match '^\d+$') {
                $app = $AppList | Where-Object { $_.STT -eq [int]$stt }
                if ($app) {
                    Write-Host "Đang cài $($app.Name) ($($app.ID))..." -ForegroundColor Yellow
                    try {
                        winget install --id $app.ID --silent --accept-package-agreements --accept-source-agreements
                        Write-Host "✅ Cài xong: $($app.Name)" -ForegroundColor Green
                    } catch {
                        Write-Host "❌ Lỗi cài $($app.Name): $_" -ForegroundColor Red
                    }
                } else {
                    Write-Host "STT $stt không tồn tại" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "Không có STT nào được nhập." -ForegroundColor Yellow
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

# Menu console đầy đủ, UX/UI hiện đại hơn
do {
    Clear-Host
    Write-Host $logo -ForegroundColor Cyan
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "║               MENU PMK TOOLBOX (Online Mode)                 ║" -ForegroundColor DarkCyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host "1. Kiểm tra Winget" -ForegroundColor Cyan
    Write-Host "2. Cài app nhanh (danh sách STT + nhập IDs)" -ForegroundColor Cyan
    Write-Host "3. Tắt Telemetry nhanh" -ForegroundColor Cyan
    Write-Host "4. Xóa file tạm" -ForegroundColor Cyan
    Write-Host "5. Tắt dịch vụ không cần thiết" -ForegroundColor Cyan
    Write-Host "6. Tạo điểm khôi phục" -ForegroundColor Cyan
    Write-Host "7. Thoát" -ForegroundColor Cyan
    Write-Host "Nhập số (1-7): " -ForegroundColor Green -NoNewline
    $choice = Read-Host

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
        default { Write-Host "Lựa chọn sai! Nhập lại (1-7)" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice -ne "7")
