# ToiUuPC.ps1 - PMK Toolbox v3.0 (Online/Remote Optimized Only)
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Minh Khải (PMK) - https://www.facebook.com/khaiitcntt
# Version: 3.0 - Custom colors/font/size, Vietnamese full, gray background, expanded app list

# Đặt encoding UTF8 để tiếng Việt hiển thị đúng
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Clear-Host

# Kiểm tra & relaunch admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# Cấu hình màu sắc & font (dễ tinh chỉnh)
$BG_COLOR = "DarkGray"          # Nền xám đậm nhẹ, dễ nhìn
$FG_COLOR = "White"             # Chữ chính trắng nhạt
$HEADER_COLOR = "Cyan"          # Header neon xanh
$OPTION_COLOR = "Cyan"          # Option menu xanh dương
$SUCCESS_COLOR = "Green"        # Success xanh lá
$ERROR_COLOR = "Red"            # Error đỏ
$BORDER_COLOR = "Gray"          # Viền/gạch ngang xám nhạt
$FONT_NAME = "Consolas"         # Font hỗ trợ tiếng Việt tốt
$FONT_SIZE_HEADER = 16          # Kích cỡ chữ header/logo
$FONT_SIZE_MENU = 14            # Kích cỡ chữ menu/option
$FONT_SIZE_TEXT = 12            # Kích cỡ chữ text nhỏ

# Áp dụng font & kích cỡ (nếu console hỗ trợ)
$Host.UI.RawUI.WindowTitle = "PMK TOOLBOX v3.0 - Minh Khải"

# Hàm reset màu & font về chuẩn
function Reset-ConsoleStyle {
    $Host.UI.RawUI.BackgroundColor = $BG_COLOR
    $Host.UI.RawUI.ForegroundColor = $FG_COLOR
    Clear-Host
}

# Hàm hiển thị header thông tin hệ thống (theo thứ tự bạn yêu cầu)
function Show-SystemHeader {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cs = Get-CimInstance Win32_ComputerSystem
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    $tpm = Get-CimInstance -Namespace "Root\CIMV2\Security\MicrosoftTpm" -ClassName Win32_Tpm -ErrorAction SilentlyContinue
    $tpmStatus = if ($tpm) { "ENABLE" } else { "NONE" }

    $username = $env:USERNAME
    $computername = $env:COMPUTERNAME
    $time = Get-Date -Format "HH:mm:ss dd/MM/yyyy"
    $timezone = (Get-TimeZone).DisplayName

    $osFull = "$($os.Caption) | Build $($os.BuildNumber) | $($os.OSArchitecture)"
    $cpuInfo = "$($cpu.Name) | Cores: $($cpu.NumberOfCores)"
    $gpuInfo = $gpu.Name
    $ram = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)

    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $HEADER_COLOR
    Write-Host "║ USER: $username   |   COMPUTER NAME: $computername   |   TPM: $tpmStatus" -ForegroundColor $HEADER_COLOR
    Write-Host "║ CURRENT OS: $osFull" -ForegroundColor $HEADER_COLOR
    Write-Host "║ CPU: $cpuInfo   |   GPU: $gpuInfo   |   RAM: $ram GB" -ForegroundColor $HEADER_COLOR
    Write-Host "║ THỜI GIAN: $time   |   MÚI GIỜ: $timezone" -ForegroundColor $HEADER_COLOR
    Write-Host "║ AUTHOR: Minh Khải (PMK)   |   FB: https://www.facebook.com/khaiitcntt" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $HEADER_COLOR
    Write-Host ""
}

# Logo Cyberpunk Neon (không icon)
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
function Test-Winget {
    try { winget --version | Out-Null; $true } catch { $false }
}

# Danh sách app mở rộng (30 app phổ biến, không icon, có STT)
$AppList = @(
    @{STT=1;  Name="Brave";           ID="Brave.Brave"},
    @{STT=2;  Name="Google Chrome";    ID="Google.Chrome"},
    @{STT=3;  Name="Firefox";          ID="Mozilla.Firefox"},
    @{STT=4;  Name="Opera";            ID="Opera.Opera"},
    @{STT=5;  Name="Vivaldi";          ID="VivaldiTechnologies.Vivaldi"},
    @{STT=6;  Name="Discord";          ID="Discord.Discord"},
    @{STT=7;  Name="Telegram";         ID="Telegram.TelegramDesktop"},
    @{STT=8;  Name="Zoom";             ID="Zoom.Zoom"},
    @{STT=9;  Name="Slack";            ID="SlackTechnologies.Slack"},
    @{STT=10; Name="Microsoft Teams";  ID="Microsoft.Teams"},
    @{STT=11; Name="Visual Studio Code"; ID="Microsoft.VisualStudioCode"},
    @{STT=12; Name="Git";              ID="Git.Git"},
    @{STT=13; Name="Python 3";         ID="Python.Python.3.12"},
    @{STT=14; Name="Node.js";          ID="OpenJS.NodeJS"},
    @{STT=15; Name="Notepad++";        ID="Notepad++.Notepad++"},
    @{STT=16; Name="7-Zip";            ID="7zip.7zip"},
    @{STT=17; Name="WinRAR";           ID="RARLab.WinRAR"},
    @{STT=18; Name="PowerToys";        ID="Microsoft.PowerToys"},
    @{STT=19; Name="Windows Terminal"; ID="Microsoft.WindowsTerminal"},
    @{STT=20; Name="Everything";       ID="voidtools.Everything"},
    @{STT=21; Name="LibreOffice";      ID="TheDocumentFoundation.LibreOffice"},
    @{STT=22; Name="SumatraPDF";       ID="SumatraPDF.SumatraPDF"},
    @{STT=23; Name="VLC Media Player"; ID="VideoLAN.VLC"},
    @{STT=24; Name="Spotify";          ID="Spotify.Spotify"},
    @{STT=25; Name="OBS Studio";       ID="OBSProject.OBSStudio"},
    @{STT=26; Name="CPU-Z";            ID="CPUID.CPU-Z"},
    @{STT=27; Name="CrystalDiskInfo";  ID="CrystalDewWorld.CrystalDiskInfo"},
    @{STT=28; Name="Rufus";            ID="Rufus.Rufus"},
    @{STT=29; Name="CCleaner";         ID="Piriform.CCleaner"},
    @{STT=30; Name="Adobe Acrobat Reader"; ID="Adobe.Acrobat.Reader.64-bit"}
)

function Install-AppQuick {
    Reset-ConsoleStyle
    Show-SystemHeader
    Write-Host $logo -ForegroundColor $HEADER_COLOR
    Write-Host "`nDANH SÁCH ỨNG DỤNG CÓ THỂ CÀI NHANH" -ForegroundColor $HEADER_COLOR
    Write-Host "-------------------------------" -ForegroundColor $BORDER_COLOR
    foreach ($app in $AppList) {
        Write-Host " [$($app.STT)] $($app.Name) ($($app.ID))" -ForegroundColor $FG_COLOR
    }
    Write-Host "-------------------------------" -ForegroundColor $BORDER_COLOR
    Write-Host "`nNhập STT (ví dụ: 1,4,7) hoặc nhập Winget ID trực tiếp:" -ForegroundColor $OPTION_COLOR
    Write-Host "Nhấn ESC để thoát về menu chính" -ForegroundColor $BORDER_COLOR

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
                        Write-Host "✅ Cài xong: $($app.Name)" -ForegroundColor $SUCCESS_COLOR
                    } catch {
                        Write-Host "❌ Lỗi cài $($app.Name): $_" -ForegroundColor $ERROR_COLOR
                    }
                } else {
                    Write-Host "STT $item không tồn tại" -ForegroundColor $ERROR_COLOR
                }
            } else {
                Write-Host "Đang cài $item..." -ForegroundColor Yellow
                try {
                    winget install --id $item --silent --accept-package-agreements --accept-source-agreements
                    Write-Host "✅ Cài xong: $item" -ForegroundColor $SUCCESS_COLOR
                } catch {
                    Write-Host "❌ Lỗi cài ${item}: $_" -ForegroundColor $ERROR_COLOR
                }
            }
        }
    }
}

# Các hàm khác (giữ nguyên, thêm reset màu)
function Disable-TelemetryQuick {
    Reset-ConsoleStyle
    Show-SystemHeader
    Write-Host $logo -ForegroundColor $HEADER_COLOR
    Write-Host "Tắt Telemetry nhanh..." -ForegroundColor $OPTION_COLOR
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Force -ErrorAction Stop
        Write-Host "✅ Telemetry đã tắt (cần reboot để apply đầy đủ)" -ForegroundColor $SUCCESS_COLOR
    } catch {
        Write-Host "❌ Lỗi: $_" -ForegroundColor $ERROR_COLOR
    }
    Pause
}

function Clean-TempFiles {
    Reset-ConsoleStyle
    Show-SystemHeader
    Write-Host $logo -ForegroundColor $HEADER_COLOR
    Write-Host "Xóa file tạm..." -ForegroundColor $OPTION_COLOR
    try {
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Đã xóa file tạm" -ForegroundColor $SUCCESS_COLOR
    } catch {
        Write-Host "⚠️ Lỗi khi xóa file tạm: $_" -ForegroundColor $ERROR_COLOR
    }
    Pause
}

function Disable-UnneededServices {
    Reset-ConsoleStyle
    Show-SystemHeader
    Write-Host $logo -ForegroundColor $HEADER_COLOR
    Write-Host "Tắt dịch vụ không cần thiết..." -ForegroundColor $OPTION_COLOR
    $services = @("DiagTrack", "dmwappushservice", "WMPNetworkSvc", "RemoteRegistry", "XblAuthManager", "XblGameSave", "XboxNetApiSvc")
    foreach ($service in $services) {
        try {
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Write-Host "✅ Đã tắt $service" -ForegroundColor $SUCCESS_COLOR
        } catch {
            Write-Host "⚠️ Không tắt được $service" -ForegroundColor $ERROR_COLOR
        }
    }
    Pause
}

function Create-RestorePoint {
    Reset-ConsoleStyle
    Show-SystemHeader
    Write-Host $logo -ForegroundColor $HEADER_COLOR
    Write-Host "Tạo điểm khôi phục hệ thống..." -ForegroundColor $OPTION_COLOR
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "PMK Toolbox - $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host "✅ Đã tạo điểm khôi phục" -ForegroundColor $SUCCESS_COLOR
    } catch {
        Write-Host "❌ Lỗi tạo điểm khôi phục: $_" -ForegroundColor $ERROR_COLOR
    }
    Pause
}

# Menu chính - phong cách Cyberpunk, viền neon, gạch ngang phân chia
do {
    Reset-ConsoleStyle
    Show-SystemHeader
    Write-Host $logo -ForegroundColor $HEADER_COLOR

    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║               MENU PMK TOOLBOX - CYBERPUNK NEON              ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

    Write-Host "--------------- CÁC CHỨC NĂNG ---------------" -ForegroundColor $BORDER_COLOR
    Write-Host " [1] Kiểm tra Winget" -ForegroundColor $OPTION_COLOR
    Write-Host " [2] Cài app nhanh (danh sách STT + nhập IDs)" -ForegroundColor $OPTION_COLOR
    Write-Host " [3] Tắt Telemetry nhanh" -ForegroundColor $OPTION_COLOR
    Write-Host " [4] Xóa file tạm" -ForegroundColor $OPTION_COLOR
    Write-Host " [5] Tắt dịch vụ không cần thiết" -ForegroundColor $OPTION_COLOR
    Write-Host " [6] Tạo điểm khôi phục hệ thống" -ForegroundColor $OPTION_COLOR
    Write-Host " [7] Thoát (hoặc nhấn ESC bất kỳ lúc nào)" -ForegroundColor $OPTION_COLOR

    Write-Host "`nNhập số (1-7): " -ForegroundColor Green -NoNewline

    # Bắt phím ESC thoát ngay (dùng ReadKey)
    $key = [Console]::ReadKey($true)
    if ($key.Key -eq "Escape") { Write-Host "`nThoát bằng ESC..." -ForegroundColor DarkGray; exit }

    $choice = $key.KeyChar

    switch ($choice) {
        "1" { if (Test-Winget) { Write-Host "✅ Winget OK" -ForegroundColor $SUCCESS_COLOR } else { Write-Host "❌ Winget chưa cài" -ForegroundColor $ERROR_COLOR }; Pause }
        "2" { Install-AppQuick; Pause }
        "3" { Disable-TelemetryQuick; Pause }
        "4" { Clean-TempFiles; Pause }
        "5" { Disable-UnneededServices; Pause }
        "6" { Create-RestorePoint; Pause }
        "7" { Write-Host "Thoát..." -ForegroundColor Cyan; exit }
        default { Write-Host "Lựa chọn sai! Nhấn phím 1-7 hoặc ESC thoát" -ForegroundColor $ERROR_COLOR; Start-Sleep 1 }
    }
} while ($true)
