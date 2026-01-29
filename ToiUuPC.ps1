# ToiUuPC.ps1 - PMK Toolbox v3.2
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Minh Khải (PMK) - https://www.facebook.com/khaiitcntt
# Version: 3.2 - Fixed STT input, added OS build + disk + RAM bus, fixed console size, progress bar

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Cố định kích thước console (padding & không cho kéo thay đổi)
mode con cols=100 lines=50

# Kiểm tra quyền Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# ===== COLOR PALETTE =====
$TEXT_COLOR    = "White"
$ACCENT_COLOR  = "White"
$SUCCESS_COLOR = "Green"
$ERROR_COLOR   = "Red"
$BORDER_COLOR  = "DarkGray"
$CYAN_COLOR    = "Cyan"  # Dùng cho STT và tiêu đề

# Reset console
function Reset-ConsoleStyle {
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = $TEXT_COLOR
    Clear-Host
}

# Kiểm tra hệ thống trước khi chạy
function Test-SystemRequirements {
    $os = Get-CimInstance Win32_OperatingSystem
    $build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId
    $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)

    Write-Host "Kiểm tra hệ thống:" -ForegroundColor $CYAN_COLOR
    Write-Host " - Windows: $($os.Caption) | Build: $build" -ForegroundColor $TEXT_COLOR
    Write-Host " - RAM: $ram GB" -ForegroundColor $TEXT_COLOR

    # RAM bus speed
    $ramSpeed = Get-CimInstance Win32_PhysicalMemory | Select-Object -First 1 -ExpandProperty Speed
    if ($ramSpeed) {
        Write-Host " - RAM Bus: $ramSpeed MHz" -ForegroundColor $TEXT_COLOR
    } else {
        Write-Host " - RAM Bus: Không lấy được" -ForegroundColor $ERROR_COLOR
    }

    Write-Host " - Disk C: Free $freeSpaceGB GB / Total $([math]::Round($disk.Size / 1GB, 2)) GB" -ForegroundColor $TEXT_COLOR

    if ([version]$os.Version -lt [version]"10.0.18362") {
        Write-Host "Yêu cầu Windows 10 1903 trở lên!" -ForegroundColor $ERROR_COLOR
        exit
    }
    if ($ram -lt 4) {
        Write-Host "Cảnh báo: RAM thấp (<4GB)" -ForegroundColor Yellow
    }
    if ($freeSpaceGB -lt 5) {
        Write-Host "Cảnh báo: Disk C: sắp đầy!" -ForegroundColor $ERROR_COLOR
    }
    Write-Host ""
}

# Header system info
function Show-SystemHeader {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cs = Get-CimInstance Win32_ComputerSystem
    $ram = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    $build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId

    Write-Host "==================================================================================" -ForegroundColor $BORDER_COLOR
    Write-Host "PMK TOOLBOX v3.2" -ForegroundColor $ACCENT_COLOR
    Write-Host "User: $($env:USERNAME) | PC: $($env:COMPUTERNAME) | OS: $($os.Caption) Build $build" -ForegroundColor $TEXT_COLOR
    Write-Host "CPU: $($cpu.Name.Split('@')[0].Trim()) | RAM: $ram GB" -ForegroundColor $TEXT_COLOR
    Write-Host "Author: Minh Khải (PMK) - https://www.facebook.com/khaiitcntt" -ForegroundColor $CYAN_COLOR
    Write-Host "==================================================================================" -ForegroundColor $BORDER_COLOR
    Write-Host ""
}

# Logo
$logo = @"
╔══════════════════════════════════════════════════════════════════════════╗
║ ██████╗ ███╗   ███╗██╗  ██╗      ████████╗ ██████╗  ██████╗ ██╗     ║
║ ██╔══██╗████╗ ████║██║ ██╔╝      ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ║
║ ██████╔╝██╔████╔██║█████╔╝          ██║   ██║   ██║██║   ██║██║     ║
║ ██╔═══╝ ██║╚██╔╝██║██╔═██╗          ██║   ██║   ██║██║   ██║██║     ║
║ ██║     ██║ ╚═╝ ██║██║  ██╗         ██║   ╚██████╔╝╚██████╔╝███████╗ ║
║ ╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝         ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝ ║
║                 PMK Toolbox - Tối ưu Windows                         ║
╚══════════════════════════════════════════════════════════════════════════╝
"@

# App categories (giữ nguyên như bản bạn)
$AppCategories = @{
    "TRÌNH DUYỆT" = @(
        @{STT=1; Name="Brave"; ID="Brave.Brave"},
        @{STT=2; Name="Google Chrome"; ID="Google.Chrome"},
        @{STT=3; Name="Mozilla Firefox"; ID="Mozilla.Firefox"},
        @{STT=4; Name="Microsoft Edge"; ID="Microsoft.Edge"},
        @{STT=5; Name="Opera"; ID="Opera.Opera"},
        @{STT=6; Name="Vivaldi"; ID="VivaldiTechnologies.Vivaldi"},
        @{STT=7; Name="LibreWolf"; ID="LibreWolf.LibreWolf"},
        @{STT=8; Name="Waterfox"; ID="Waterfox.Waterfox"},
        @{STT=9; Name="Thorium (AVX2)"; ID="Alex313031.Thorium.AVX2"},
        @{STT=10; Name="Zen Browser"; ID="Zen-Team.Zen-Browser"}
    )
        "TIỆN ÍCH" = @(
        @{STT=11; Name="7-Zip"; ID="7zip.7zip"},
        @{STT=12; Name="WinRAR"; ID="RARLab.WinRAR"},
        @{STT=13; Name="PowerToys"; ID="Microsoft.PowerToys"},
        @{STT=14; Name="Windows Terminal"; ID="Microsoft.WindowsTerminal"},
        @{STT=15; Name="Everything"; ID="voidtools.Everything"},
        @{STT=16; Name="EarTrumpet"; ID="File-New-Project.EarTrumpet"},
        @{STT=17; Name="QuickLook"; ID="QL-Win.QuickLook"},
        @{STT=18; Name="TranslucentTB"; ID="TranslucentTB.TranslucentTB"},
        @{STT=19; Name="Twinkle Tray"; ID="xanderfrangos.twinkletray"},
        @{STT=20; Name="AutoHotkey"; ID="AutoHotkey.AutoHotkey"},
        @{STT=21; Name="Flow Launcher"; ID="Flow-Launcher.Flow-Launcher"},
        @{STT=22; Name="WizTree"; ID="AntibodySoftware.WizTree"},
        @{STT=23; Name="WizFile"; ID="AntibodySoftware.WizFile"},
        @{STT=24; Name="LockHunter"; ID="CrystalRich.LockHunter"},
        @{STT=25; Name="Bulk Crap Uninstaller"; ID="Klocman.BulkCrapUninstaller"},
        @{STT=26; Name="Revo Uninstaller"; ID="RevoUninstaller.RevoUninstaller"},
        @{STT=27; Name="Glary Utilities"; ID="Glarysoft.GlaryUtilities"},
        @{STT=28; Name="CCleaner"; ID="Piriform.CCleaner"},
        @{STT=29; Name="BleachBit"; ID="BleachBit.BleachBit"},
        @{STT=30; Name="NanaZip"; ID="M2Team.NanaZip"}
    )
    
    "PHÁT TRIỂN" = @(
        @{STT=31; Name="Visual Studio Code"; ID="Microsoft.VisualStudioCode"},
        @{STT=32; Name="VSCodium"; ID="VSCodium.VSCodium"},
        @{STT=33; Name="Git"; ID="Git.Git"},
        @{STT=34; Name="GitHub Desktop"; ID="GitHub.GitHubDesktop"},
        @{STT=35; Name="GitKraken"; ID="Axosoft.GitKraken"},
        @{STT=36; Name="Notepad++"; ID="Notepad++.Notepad++"},
        @{STT=37; Name="Python 3"; ID="Python.Python.3.12"},
        @{STT=38; Name="Node.js"; ID="OpenJS.NodeJS"},
        @{STT=39; Name="Docker Desktop"; ID="Docker.DockerDesktop"},
        @{STT=40; Name="Postman"; ID="Postman.Postman"}
    )
    
    "ĐA PHƯƠNG TIỆN" = @(
        @{STT=41; Name="VLC Media Player"; ID="VideoLAN.VLC"},
        @{STT=42; Name="MPC-HC"; ID="clsid2.mpc-hc"},
        @{STT=43; Name="K-Lite Codec Pack"; ID="CodecGuide.K-LiteCodecPack.Standard"},
        @{STT=44; Name="Spotify"; ID="Spotify.Spotify"},
        @{STT=45; Name="OBS Studio"; ID="OBSProject.OBSStudio"},
        @{STT=46; Name="HandBrake"; ID="HandBrake.HandBrake"},
        @{STT=47; Name="Blender"; ID="BlenderFoundation.Blender"},
        @{STT=48; Name="GIMP"; ID="GIMP.GIMP.3"},
        @{STT=49; Name="Krita"; ID="KDE.Krita"},
        @{STT=50; Name="Inkscape"; ID="Inkscape.Inkscape"}
    )
    
    "VĂN PHÒNG & PDF" = @(
        @{STT=51; Name="LibreOffice"; ID="TheDocumentFoundation.LibreOffice"},
        @{STT=52; Name="ONLYOffice Desktop"; ID="ONLYOFFICE.DesktopEditors"},
        @{STT=53; Name="SumatraPDF"; ID="SumatraPDF.SumatraPDF"},
        @{STT=54; Name="Foxit PDF Reader"; ID="Foxit.FoxitReader"},
        @{STT=55; Name="Adobe Acrobat Reader"; ID="Adobe.Acrobat.Reader.64-bit"},
        @{STT=56; Name="Obsidian"; ID="Obsidian.Obsidian"},
        @{STT=57; Name="Joplin"; ID="Joplin.Joplin"},
        @{STT=58; Name="Calibre"; ID="calibre.calibre"}
    )
    
    "CÔNG CỤ HỆ THỐNG" = @(
        @{STT=59; Name="CrystalDiskInfo"; ID="CrystalDewWorld.CrystalDiskInfo"},
        @{STT=60; Name="CrystalDiskMark"; ID="CrystalDewWorld.CrystalDiskMark"},
        @{STT=61; Name="CPU-Z"; ID="CPUID.CPU-Z"},
        @{STT=62; Name="GPU-Z"; ID="TechPowerUp.GPU-Z"},
        @{STT=63; Name="HWiNFO"; ID="REALiX.HWiNFO"},
        @{STT=64; Name="Rufus"; ID="Rufus.Rufus"},
        @{STT=65; Name="Ventoy"; ID="Ventoy.Ventoy"},
        @{STT=66; Name="VirtualBox"; ID="Oracle.VirtualBox"},
        @{STT=67; Name="Sandboxie Plus"; ID="Sandboxie.Plus"}
    )
    
    "LIÊN LẠC" = @(
        @{STT=68; Name="Discord"; ID="Discord.Discord"},
        @{STT=69; Name="Telegram"; ID="Telegram.TelegramDesktop"},
        @{STT=70; Name="Signal"; ID="OpenWhisperSystems.Signal"},
        @{STT=71; Name="Zoom"; ID="Zoom.Zoom"},
        @{STT=72; Name="Microsoft Teams"; ID="Microsoft.Teams"}
    )
}

# Progress bar khi cài nhiều app
function Show-Progress {
    param($Current, $Total, $AppName)
    $percent = [math]::Round(($Current / $Total) * 100)
    $barLength = 50
    $bars = [math]::Round(($percent / 100) * $barLength)
    $spaces = $barLength - $bars
    
    Write-Host "`r[$('#' * $bars)$(' ' * $spaces)] $percent% - $AppName" -NoNewline -ForegroundColor $CYAN_COLOR
}

# Show app list
function Show-AppList {
    Reset-ConsoleStyle
    Show-SystemHeader
    Write-Host $logo -ForegroundColor $CYAN_COLOR
    Write-Host ""
    Write-Host "DANH SÁCH ỨNG DỤNG CÓ THỂ CÀI NHANH" -ForegroundColor $CYAN_COLOR
    Write-Host "====================================" -ForegroundColor $BORDER_COLOR
    Write-Host ""

    foreach ($category in $AppCategories.Keys) {
        $apps = $AppCategories[$category]
        Write-Host $category -ForegroundColor $CYAN_COLOR
        Write-Host "------------------------------------" -ForegroundColor $BORDER_COLOR

        $half = [Math]::Ceiling($apps.Count / 2)
        for ($j = 0; $j -lt $half; $j++) {
            $app1 = $apps[$j]
            $app2 = if ($j + $half -lt $apps.Count) { $apps[$j + $half] } else { $null }

            $line1 = " [$($app1.STT)] $($app1.Name.PadRight(35))"
            $line2 = if ($app2) { " [$($app2.STT)] $($app2.Name.PadRight(35))" } else { "" }

            Write-Host $line1 -NoNewline -ForegroundColor $CYAN_COLOR
            if ($app2) {
                Write-Host "  " -NoNewline
                Write-Host $line2 -ForegroundColor $CYAN_COLOR
            } else {
                Write-Host ""
            }
        }
        Write-Host ""
        Write-Host ""
        Write-Host ""
    }

    Write-Host "====================================" -ForegroundColor $BORDER_COLOR
    Write-Host ""
    Write-Host "Hướng dẫn:" -ForegroundColor $TEXT_COLOR
    Write-Host " - Nhập STT (ví dụ: 1,4,7) để cài nhiều app cùng lúc" -ForegroundColor $TEXT_COLOR
    Write-Host " - Nhập Winget ID trực tiếp (ví dụ: Google.Chrome)" -ForegroundColor $TEXT_COLOR
    Write-Host " - Nhấn ESC để thoát về menu chính" -ForegroundColor $TEXT_COLOR
    Write-Host ""

    Write-Host "Nhập lựa chọn của bạn (hoặc ESC để thoát): " -NoNewline -ForegroundColor $CYAN_COLOR
    $input = Read-Host

    if ([Console]::KeyAvailable -and [Console]::ReadKey($true).Key -eq "Escape") {
        Write-Host "`nThoát về menu chính..." -ForegroundColor $BORDER_COLOR
        return $null
    }
    return $input
}

# Install apps with progress bar
function Install-AppQuick {
    $input = Show-AppList
    if (-not $input) { return }

    Reset-ConsoleStyle
    Show-SystemHeader

    Write-Host "ĐANG CÀI ĐẶT ỨNG DỤNG" -ForegroundColor $CYAN_COLOR
    Write-Host "======================" -ForegroundColor $BORDER_COLOR
    Write-Host ""

    $items = $input.Split(',').Trim()
    $total = $items.Count
    $current = 0
    $success = 0
    $fail = 0

    foreach ($item in $items) {
        $current++
        $appName = $item
        $app = $null

        if ($item -match '^\d+$') {
            foreach ($category in $AppCategories.Values) {
                $app = $category | Where-Object { $_.STT -eq [int]$item }
                if ($app) { $appName = $app.Name; break }
            }
        }

        Show-Progress -Current $current -Total $total -AppName $appName

        try {
            if ($app) {
                winget install --id $app.ID --silent --accept-package-agreements --accept-source-agreements
            } else {
                winget install --id $item --silent --accept-package-agreements --accept-source-agreements
            }
            $success++
        } catch {
            $fail++
        }
    }

    Write-Host "`n======================" -ForegroundColor $BORDER_COLOR
    Write-Host "Kết quả: $success thành công, $fail thất bại" -ForegroundColor $(if ($fail -eq 0) { $SUCCESS_COLOR } else { $ERROR_COLOR })
    Write-Host ""
    Write-Host "Nhấn phím bất kỳ để tiếp tục..." -ForegroundColor $CYAN_COLOR
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Các hàm khác (giữ nguyên, bạn copy từ code cũ nếu cần)

# Main menu (đơn giản, fix input)
do {
    Reset-ConsoleStyle
    Show-SystemHeader
    Write-Host $logo -ForegroundColor $CYAN_COLOR

    Write-Host "MENU CHÍNH - PMK TOOLBOX" -ForegroundColor $CYAN_COLOR
    Write-Host "=========================" -ForegroundColor $BORDER_COLOR
    Write-Host ""

    Write-Host " [1] Cài đặt ứng dụng nhanh" -ForegroundColor $CYAN_COLOR
    Write-Host " [2] Vô hiệu hóa Telemetry" -ForegroundColor $CYAN_COLOR
    Write-Host " [3] Dọn dẹp file tạm" -ForegroundColor $CYAN_COLOR
    Write-Host " [4] Tắt dịch vụ không cần thiết" -ForegroundColor $CYAN_COLOR
    Write-Host " [5] Thoát" -ForegroundColor $CYAN_COLOR

    Write-Host ""
    Write-Host "Nhập số lựa chọn (1-5) rồi nhấn Enter (hoặc ESC để thoát): " -NoNewline -ForegroundColor $CYAN_COLOR

    $input = Read-Host

    if ([Console]::KeyAvailable -and [Console]::ReadKey($true).Key -eq "Escape") {
        Write-Host "`nThoát chương trình..." -ForegroundColor $CYAN_COLOR
        exit
    }

    switch ($input) {
        "1" { Install-AppQuick }
        "2" { Disable-TelemetryQuick }
        "3" { Clean-TempFiles }
        "4" { Disable-UnneededServices }
        "5" { Write-Host "Tạm biệt! Cảm ơn đã sử dụng PMK Toolbox!" -ForegroundColor $CYAN_COLOR; exit }
        default { Write-Host "Lựa chọn không hợp lệ! Vui lòng chọn 1-5" -ForegroundColor $ERROR_COLOR; Start-Sleep 1 }
    }
} while ($true)
