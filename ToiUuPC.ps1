# ToiUuPC.ps1 - PMK Toolbox v3.0
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Minh Khải (PMK) - https://www.facebook.com/khaiitcntt
# Version: 3.0

Clear-Host

# Kiểm tra & relaunch admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

function Reset-ConsoleColor {
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = "White"
    Clear-Host
}

# Hàm hiển thị header thông tin hệ thống
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

    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ USER: $username   |   COMPUTER NAME: $computername   |   TPM: $tpmStatus" -ForegroundColor Cyan
    Write-Host "║ CURRENT OS: $osFull" -ForegroundColor Cyan
    Write-Host "║ CPU: $cpuInfo   |   GPU: $gpuInfo   |   RAM: $ram GB" -ForegroundColor Cyan
    Write-Host "║ THỜI GIAN: $time   |   MÚI GIỜ: $timezone" -ForegroundColor Cyan
    Write-Host "║ AUTHOR: Minh Khải (PMK)   |   FB: https://www.facebook.com/khaiitcntt" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

$logo = @"
   ██████╗ ███╗   ███╗██╗  ██╗      ████████╗ ██████╗  ██████╗ ██╗
   ██╔══██╗████╗ ████║██║ ██╔╝      ╚══██╔══╝██╔═══██╗██╔═══██╗██║
   ██████╔╝██╔████╔██║█████╔╝          ██║   ██║   ██║██║   ██║██║
   ██╔═══╝ ██║╚██╔╝██║██╔═██╗          ██║   ██║   ██║██║   ██║██║
   ██║     ██║ ╚═╝ ██║██║  ██╗         ██║   ╚██████╔╝╚██████╔╝███████╗
   ╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝         ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
               PMK TOOLBOX - Tối ưu Windows | v3.0 | Cyberpunk Neon
"@

function Test-Winget {
    try { winget --version | Out-Null; $true } catch { $false }
}

# Danh sách app 
$AppList = @(
    @{STT=1;  Name="Brave";           ID="Brave.Brave"},
    @{STT=2;  Name="Google Chrome";    ID="Google.Chrome"},
    @{STT=3;  Name="Firefox";          ID="Mozilla.Firefox"},
    @{STT=4;  Name="Discord";          ID="Discord.Discord"},
    @{STT=5;  Name="Telegram";         ID="Telegram.TelegramDesktop"},
    @{STT=6;  Name="Visual Studio Code"; ID="Microsoft.VisualStudioCode"},
    @{STT=7;  Name="Git";              ID="Git.Git"},
    @{STT=8;  Name="Python 3";         ID="Python.Python.3.12"},
    @{STT=9;  Name="7-Zip";            ID="7zip.7zip"},
    @{STT=10; Name="PowerToys";        ID="Microsoft.PowerToys"},
    @{STT=11; Name="Windows Terminal"; ID="Microsoft.WindowsTerminal"},
    @{STT=12; Name="LibreOffice";      ID="TheDocumentFoundation.LibreOffice"}
)

function Install-AppQuick {
    Reset-ConsoleColor
    Show-SystemHeader
    Write-Host $logo -ForegroundColor Cyan
    Write-Host "`nDANH SÁCH ỨNG DỤNG CÓ THỂ CÀI NHANH" -ForegroundColor Cyan
    Write-Host "-------------------------------" -ForegroundColor DarkCyan
    foreach ($app in $AppList) {
        Write-Host " [$($app.STT)] $($app.Name) ($($app.ID))" -ForegroundColor White
    }
    Write-Host "-------------------------------" -ForegroundColor DarkCyan
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
                } else {
                    Write-Host "STT $item không tồn tại" -ForegroundColor Red
                }
            } else {
                Write-Host "Đang cài $item..." -ForegroundColor Yellow
                try {
                    winget install --id $item --silent --accept-package-agreements --accept-source-agreements
                    Write-Host "✅ Cài xong: $item" -ForegroundColor Green
                } catch {
                    Write-Host "❌ Lỗi cài ${item}: $_" -ForegroundColor Red
                }
            }
        }
    }
}


function Disable-TelemetryQuick {
    Reset-ConsoleColor
    Show-SystemHeader
    Write-Host $logo -ForegroundColor Cyan
    Write-Host "Tắt Telemetry nhanh..." -ForegroundColor Yellow
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
    Reset-ConsoleColor
    Show-SystemHeader
    Write-Host $logo -ForegroundColor Cyan
    Write-Host "Xóa file tạm..." -ForegroundColor Yellow
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
    Reset-ConsoleColor
    Show-SystemHeader
    Write-Host $logo -ForegroundColor Cyan
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
    Pause
}

function Create-RestorePoint {
    Reset-ConsoleColor
    Show-SystemHeader
    Write-Host $logo -ForegroundColor Cyan
    Write-Host "Tạo điểm khôi phục hệ thống..." -ForegroundColor Yellow
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "PMK Toolbox - $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host "✅ Đã tạo điểm khôi phục" -ForegroundColor Green
    } catch {
        Write-Host "❌ Lỗi tạo điểm khôi phục: $_" -ForegroundColor Red
    }
    Pause
}

# Menu chính 
do {
    Reset-ConsoleColor
    Show-SystemHeader
    Write-Host $logo -ForegroundColor Cyan

    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║               MENU PMK TOOLBOX - CYBERPUNK NEON              ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

    Write-Host "--------------- CÁC CHỨC NĂNG ---------------" -ForegroundColor DarkCyan
    Write-Host " [1] Kiểm tra Winget" -ForegroundColor White
    Write-Host " [2] Cài app nhanh (danh sách STT + nhập IDs)" -ForegroundColor White
    Write-Host " [3] Tắt Telemetry nhanh" -ForegroundColor White
    Write-Host " [4] Xóa file tạm" -ForegroundColor White
    Write-Host " [5] Tắt dịch vụ không cần thiết" -ForegroundColor White
    Write-Host " [6] Tạo điểm khôi phục hệ thống" -ForegroundColor White
    Write-Host " [7] Thoát (hoặc nhấn ESC bất kỳ lúc nào)" -ForegroundColor White

    Write-Host "`nNhập số (1-7): " -ForegroundColor Green -NoNewline

    # Bắt phím ESC thoát ngay
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
