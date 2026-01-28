# ToiUuPC.ps1 - PMK Toolbox v3.1 (Cyberpunk Console Edition - Online/Remote)
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Minh Khải (Thuthuatwiki PMK) - FB: https://www.facebook.com/khaiitcntt
# Version: 3.1 - Cyberpunk style, fixed color, ESC escape, app list with STT

Clear-Host

# Kiểm tra & relaunch admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# Dark Cyberpunk theme (màu cố định, không đổi sau khi thoát menu con)
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
[console]::CursorVisible = $true
Clear-Host

# Logo Cyberpunk
$logo = @"
╔══════════════════════════════════════════════════════════════════════════╗
║ ██████╗ ███╗   ███╗██╗  ██╗      ████████╗ ██████╗  ██████╗ ██╗       ║
║ ██╔══██╗████╗ ████║██║ ██╔╝      ╚══██╔══╝██╔═══██╗██╔═══██╗██║       ║
║ ██████╔╝██╔████╔██║█████╔╝          ██║   ██║   ██║██║   ██║██║       ║
║ ██╔═══╝ ██║╚██╔╝██║██╔═██╗          ██║   ██║   ██║██║   ██║██║       ║
║ ██║     ██║ ╚═╝ ██║██║  ██╗         ██║   ╚██████╔╝╚██████╔╝███████╗  ║
║ ╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝         ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝  ║
║                     PMK TOOLBOX - Tối ưu Windows                     ║
║                  Phiên bản: 3.1 | Windows 10/11                      ║
╚══════════════════════════════════════════════════════════════════════════╝
"@

# Thông tin hệ thống trên cùng (Cyberpunk style)
function Show-SystemHeader {
    $user = $env:USERNAME
    $computer = $env:COMPUTERNAME
    $os = (Get-CimInstance Win32_OperatingSystem).Caption
    $build = (Get-CimInstance Win32_OperatingSystem).BuildNumber
    $time = Get-Date -Format "HH:mm:ss dd/MM/yyyy"
    $timezone = (Get-TimeZone).Id

    Write-Host "╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║ USER: $user   |   PC: $computer   |   OS: $os $build   |   TIME: $time $timezone ║" -ForegroundColor Cyan
    Write-Host "║ AUTHOR: Minh Khải (PMK)   |   FB: https://www.facebook.com/khaiitcntt ║" -ForegroundColor DarkCyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}

# Danh sách app hardcode (hiển thị STT + icon)
$AppList = @(
    @{STT=1;  Name="Brave Browser";          ID="Brave.Brave";           Icon="🌐"},
    @{STT=2;  Name="Google Chrome";          ID="Google.Chrome";         Icon="🔍"},
    @{STT=3;  Name="Mozilla Firefox";        ID="Mozilla.Firefox";       Icon="🦊"},
    @{STT=4;  Name="Discord";                ID="Discord.Discord";        Icon="🎮"},
    @{STT=5;  Name="Telegram Desktop";       ID="Telegram.TelegramDesktop"; Icon="✈️"},
    @{STT=6;  Name="Visual Studio Code";     ID="Microsoft.VisualStudioCode"; Icon="📝"},
    @{STT=7;  Name="Git";                    ID="Git.Git";               Icon="🌿"},
    @{STT=8;  Name="Python 3.12";            ID="Python.Python.3.12";    Icon="🐍"},
    @{STT=9;  Name="7-Zip";                  ID="7zip.7zip";             Icon="🗜️"},
    @{STT=10; Name="PowerToys";              ID="Microsoft.PowerToys";    Icon="🛠️"},
    @{STT=11; Name="Windows Terminal";       ID="Microsoft.WindowsTerminal"; Icon="⌨️"},
    @{STT=12; Name="LibreOffice";            ID="TheDocumentFoundation.LibreOffice"; Icon="📑"}
)

# Hàm cài app nhanh (hiển thị danh sách STT)
function Install-AppQuick {
    Clear-Host
    Show-SystemHeader
    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║       DANH SÁCH ỨNG DỤNG PHỔ BIẾN     ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""

    foreach ($app in $AppList) {
        Write-Host " [$($app.STT)] $($app.Icon) $($app.Name) ($($app.ID))" -ForegroundColor White
    }

    Write-Host "`nNhập STT (ví dụ: 1,3,5) hoặc ESC để thoát" -ForegroundColor Green -NoNewline
    Write-Host " > " -ForegroundColor Magenta -NoNewline

    # Bắt phím ESC thoát nhanh
    $key = [Console]::ReadKey($true)
    if ($key.Key -eq "Escape") {
        Write-Host "`nĐã thoát về menu chính..." -ForegroundColor Yellow
        return
    }

    $input = $key.KeyChar + [Console]::ReadLine()
    if ($input) {
        foreach ($stt in $input.Split(',')) {
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
    }
    Write-Host "`nNhấn phím bất kỳ để về menu..." -ForegroundColor DarkGray
    [Console]::ReadKey($true) | Out-Null
}

# Các hàm khác (giữ nguyên)
function Disable-TelemetryQuick {
    Clear-Host
    Show-SystemHeader
    Write-Host "Đang tắt Telemetry..." -ForegroundColor Yellow
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Force -ErrorAction Stop
        Write-Host "✅ Telemetry đã tắt (cần reboot để apply đầy đủ)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Lỗi: $_" -ForegroundColor Red
    }
    Pause
}

function Clean-TempFiles {
    Clear-Host
    Show-SystemHeader
    Write-Host "Đang xóa file tạm..." -ForegroundColor Yellow
    try {
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Đã xóa file tạm" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Lỗi khi xóa file tạm: $_" -ForegroundColor Red
    }
    Pause
}

function Disable-UnneededServices {
    Clear-Host
    Show-SystemHeader
    Write-Host "Đang tắt dịch vụ không cần thiết..." -ForegroundColor Yellow
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
    Pause
}

function Create-RestorePoint {
    Clear-Host
    Show-SystemHeader
    Write-Host "Đang tạo điểm khôi phục..." -ForegroundColor Yellow
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "PMK Toolbox - $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host "✅ Đã tạo điểm khôi phục" -ForegroundColor Green
    } catch {
        Write-Host "❌ Lỗi: $_" -ForegroundColor Red
    }
    Pause
}

# Menu chính (Cyberpunk style, 2 cột như ảnh Ghost Toolbox)
do {
    Clear-Host
    Show-SystemHeader
    Write-Host "╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                        PMK TOOLBOX - TỐI ƯU WINDOWS                     ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

    Write-Host "`n" -NoNewline
    Write-Host "  TWEAKS & CLEANER".PadRight(40) + "INSTALLER & TOOLS" -ForegroundColor DarkCyan

    Write-Host "  [1] Tắt Telemetry nhanh" -ForegroundColor Cyan
    Write-Host "  [2] Cài app nhanh (danh sách STT)" -ForegroundColor Cyan
    Write-Host "  [3] Xóa file tạm" -ForegroundColor Cyan
    Write-Host "  [4] Tắt dịch vụ không cần thiết" -ForegroundColor Cyan
    Write-Host "  [5] Tạo điểm khôi phục" -ForegroundColor Cyan
    Write-Host "  [6] Thoát" -ForegroundColor Cyan

    Write-Host "`nNhập số (1-6) hoặc ESC để thoát nhanh: " -ForegroundColor Green -NoNewline
    $key = [Console]::ReadKey($true)
    $choice = $key.KeyChar

    if ($key.Key -eq "Escape") {
        Write-Host "`nThoát nhanh..." -ForegroundColor Yellow
        exit
    }

    switch ($choice) {
        "1" { Disable-TelemetryQuick }
        "2" { Install-AppQuick }
        "3" { Clean-TempFiles }
        "4" { Disable-UnneededServices }
        "5" { Create-RestorePoint }
        "6" { Write-Host "Thoát..." -ForegroundColor Cyan; exit }
        default { Write-Host "Lựa chọn sai! Nhập 1-6" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice -ne "6")
