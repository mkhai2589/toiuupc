# ToiUuPC.ps1 - PMK Toolbox v3.0 (Cyberpunk Neon Online Mode)
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Minh Khải (PMK) - https://www.facebook.com/khaiitcntt
# Version: 3.0 - Neon UI, fixed color, ESC exit, full system info header

# Kiểm tra & relaunch admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# Hàm reset màu console về chuẩn Cyberpunk (gọi lại sau mỗi action)
function Reset-ConsoleColor {
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = "White"
    Clear-Host
}

# Hàm hiển thị header thông tin hệ thống (luôn ở trên cùng)
function Show-SystemHeader {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cs = Get-CimInstance Win32_ComputerSystem
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1

    $osName = $os.Caption
    $osBuild = $os.BuildNumber
    $username = $env:USERNAME
    $computername = $env:COMPUTERNAME
    $time = Get-Date -Format "HH:mm:ss dd/MM/yyyy"
    $timezone = (Get-TimeZone).Id

    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ USER: $username   |   COMPUTER: $computername" -ForegroundColor Cyan
    Write-Host "║ OS: $osName   |   Build: $osBuild   |   CPU: $($cpu.NumberOfCores) cores" -ForegroundColor Cyan
    Write-Host "║ GPU: $($gpu.Name)   |   TIME: $time   |   ZONE: $timezone" -ForegroundColor Cyan
    Write-Host "║ AUTHOR: Minh Khải (PMK)   |   FB: https://www.facebook.com/khaiitcntt" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Logo Cyberpunk Neon
$logo = @"
   ██████╗ ███╗   ███╗██╗  ██╗      ████████╗ ██████╗  ██████╗ ██╗
   ██╔══██╗████╗ ████║██║ ██╔╝      ╚══██╔══╝██╔═══██╗██╔═══██╗██║
   ██████╔╝██╔████╔██║█████╔╝          ██║   ██║   ██║██║   ██║██║
   ██╔═══╝ ██║╚██╔╝██║██╔═██╗          ██║   ██║   ██║██║   ██║██║
   ██║     ██║ ╚═╝ ██║██║  ██╗         ██║   ╚██████╔╝╚██████╔╝███████╗
   ╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝         ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
               PMK TOOLBOX - Tối ưu Windows | v3.0 | Cyberpunk Neon
"@

# Hàm cơ bản
function Test-Winget { try { winget --version | Out-Null; $true } catch { $false } }

# Danh sách app (hiển thị STT + icon + tên + ID)
$AppList = @(
    @{STT=1;  Icon="🚀"; Name="Brave";           ID="Brave.Brave"},
    @{STT=2;  Icon="🔍"; Name="Google Chrome";    ID="Google.Chrome"},
    @{STT=3;  Icon="🦊"; Name="Firefox";          ID="Mozilla.Firefox"},
    @{STT=4;  Icon="🎮"; Name="Discord";          ID="Discord.Discord"},
    @{STT=5;  Icon="✈️"; Name="Telegram";         ID="Telegram.TelegramDesktop"},
    @{STT=6;  Icon="📝"; Name="VS Code";          ID="Microsoft.VisualStudioCode"},
    @{STT=7;  Icon="🌿"; Name="Git";              ID="Git.Git"},
    @{STT=8;  Icon="🐍"; Name="Python 3";         ID="Python.Python.3.12"},
    @{STT=9;  Icon="🗜️"; Name="7-Zip";            ID="7zip.7zip"},
    @{STT=10; Icon="🛠️"; Name="PowerToys";        ID="Microsoft.PowerToys"},
    @{STT=11; Icon="⌨️"; Name="Windows Terminal"; ID="Microsoft.WindowsTerminal"},
    @{STT=12; Icon="📑"; Name="LibreOffice";      ID="TheDocumentFoundation.LibreOffice"}
)

function Install-AppQuick {
    Reset-ConsoleColor
    Show-SystemHeader
    Write-Host $logo -ForegroundColor Cyan
    Write-Host "`nDanh sách ứng dụng có thể cài nhanh:" -ForegroundColor Neon
    foreach ($app in $AppList) {
        Write-Host " [$($app.STT)]  $($app.Icon)  $($app.Name)  ($($app.ID))" -ForegroundColor White
    }
    Write-Host "`nNhập STT (ví dụ: 1,4,7) hoặc nhập Winget ID trực tiếp:" -ForegroundColor Cyan
    Write-Host "Nhấn ESC để thoát về menu chính" -ForegroundColor DarkGray

    $input = Read-Host
    if ($input) {
        foreach ($item in $input.Split(',')) {
            $item = $item.Trim()
            if ($item -match '^\d+$') {
                $app = $AppList | Where-Object { $_.STT -eq [int]$item }
                if ($app) {
                    Write-Host "Đang cài $($app.Name) ($($app.ID))..." -ForegroundColor Yellow
                    try {
                        winget install --id $app.ID --silent --accept-package-agreements --accept-source-agreements
                        Write-Host "✅ Cài xong: $($app.Name)" -ForegroundColor Green
                    } catch {
                        Write-Host "❌ Lỗi cài $($app.Name): $_" -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "Đang cài $item..." -ForegroundColor Yellow
                try {
                    winget install --id $item --silent --accept-package-agreements --accept-source-agreements
                    Write-Host "✅ Cài xong: $item" -ForegroundColor Green
                } catch {
                    Write-Host "❌ Lỗi cài $item: $_" -ForegroundColor Red
                }
            }
        }
    }
}

# Các hàm khác (giữ nguyên, thêm reset màu)
function Disable-TelemetryQuick {
    Reset-ConsoleColor
    Show-SystemHeader
    Write-Host $logo -ForegroundColor Cyan
    Disable-TelemetryQuick
    Pause
}

function Clean-TempFiles {
    Reset-ConsoleColor
    Show-SystemHeader
    Write-Host $logo -ForegroundColor Cyan
    Clean-TempFiles
    Pause
}

function Disable-UnneededServices {
    Reset-ConsoleColor
    Show-SystemHeader
    Write-Host $logo -ForegroundColor Cyan
    Disable-UnneededServices
    Pause
}

function Create-RestorePoint {
    Reset-ConsoleColor
    Show-SystemHeader
    Write-Host $logo -ForegroundColor Cyan
    Create-RestorePoint
    Pause
}

# Menu chính - phong cách Cyberpunk, viền neon
do {
    Reset-ConsoleColor
    Show-SystemHeader
    Write-Host $logo -ForegroundColor Cyan

    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                        MENU PMK TOOLBOX                      ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

    Write-Host " 1. Kiểm tra Winget" -ForegroundColor Neon
    Write-Host " 2. Cài app nhanh (danh sách STT + nhập IDs)" -ForegroundColor Neon
    Write-Host " 3. Tắt Telemetry nhanh" -ForegroundColor Neon
    Write-Host " 4. Xóa file tạm" -ForegroundColor Neon
    Write-Host " 5. Tắt dịch vụ không cần thiết" -ForegroundColor Neon
    Write-Host " 6. Tạo điểm khôi phục hệ thống" -ForegroundColor Neon
    Write-Host " 7. Thoát (hoặc nhấn ESC bất kỳ lúc nào)" -ForegroundColor Neon

    Write-Host "`nNhập số (1-7): " -ForegroundColor Green -NoNewline

    # Bắt phím ESC thoát ngay (dùng ReadKey)
    $key = [Console]::ReadKey($true)
    if ($key.Key -eq "Escape") { Write-Host "`nThoát bằng ESC..." -ForegroundColor DarkGray; exit }

    $choice = $key.KeyChar

    switch ($choice) {
        "1" { if (Test-Winget) { Write-Host "✅ Winget OK" -ForegroundColor Green } else { Write-Host "❌ Winget chưa cài" -ForegroundColor Red }; Pause }
        "2" { Install-AppQuick; Pause }
        "3" { Disable-TelemetryQuick; Pause }
        "4" { Clean-TempFiles; Pause }
        "5" { Disable-UnneededServices; Pause }
        "6" { Create-RestorePoint; Pause }
        "7" { Write-Host "Thoát..." -ForegroundColor Cyan; exit }
        default { Write-Host "Lựa chọn sai! Nhấn phím 1-7 hoặc ESC thoát" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($true)
