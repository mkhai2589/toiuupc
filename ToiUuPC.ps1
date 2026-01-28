# ToiUuPC.ps1 - PMK Toolbox v3.0
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Minh Khải (PMK) - https://www.facebook.com/khaiitcntt
# Version: 3.0 - Soft Neon Palette, category headers bold + extra spacing, 2-column layout

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Clear-Host

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# ===== PMK TOOLBOX – Soft Neon Terminal Palette =====
$BG_COLOR      = "DarkGray"     # Nền xám đậm vừa
$FG_COLOR      = "White"        # Chữ chính
$HEADER_COLOR  = "Gray"         # Header xám sáng
$OPTION_COLOR  = "Cyan"         # Accent nhẹ
$SUCCESS_COLOR = "Green"        # Thành công dịu
$ERROR_COLOR   = "DarkRed"      # Lỗi không gắt
$BORDER_COLOR  = "Gray"         # Viền & gạch


# Hàm reset màu & font
function Reset-ConsoleStyle {
    $Host.UI.RawUI.BackgroundColor = $BG_COLOR
    $Host.UI.RawUI.ForegroundColor = $FG_COLOR
    Clear-Host
}

# Header thông tin hệ thống
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

# Logo
$logo = @"
   ██████╗ ███╗   ███╗██╗  ██╗      ████████╗ ██████╗  ██████╗ ██╗
   ██╔══██╗████╗ ████║██║ ██╔╝      ╚══██╔══╝██╔═══██╗██╔═══██╗██║
   ██████╔╝██╔████╔██║█████╔╝          ██║   ██║   ██║██║   ██║██║
   ██╔═══╝ ██║╚██╔╝██║██╔═██╗          ██║   ██║   ██║██║   ██║██║
   ██║     ██║ ╚═╝ ██║██║  ██╗         ██║   ╚██████╔╝╚██████╔╝███████╗
   ╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝         ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
               PMK TOOLBOX - Tối ưu Windows | v3.0
"@

# Hàm cơ bản
function Test-Winget {
    try { winget --version | Out-Null; $true } catch { $false }
}

# Danh sách app (không Games, chia category)
$AppList = @(
    # Browsers
    @{STT=1;  Name="Brave";                  ID="Brave.Brave"},
    @{STT=2;  Name="Google Chrome";           ID="Google.Chrome"},
    @{STT=3;  Name="Mozilla Firefox";         ID="Mozilla.Firefox"},
    @{STT=4;  Name="Microsoft Edge";          ID="Microsoft.Edge"},
    @{STT=5;  Name="Opera";                   ID="Opera.Opera"},
    @{STT=6;  Name="Vivaldi";                 ID="VivaldiTechnologies.Vivaldi"},
    @{STT=7;  Name="LibreWolf";               ID="LibreWolf.LibreWolf"},
    @{STT=8;  Name="Waterfox";                ID="Waterfox.Waterfox"},
    @{STT=9;  Name="Thorium (AVX2)";          ID="Alex313031.Thorium.AVX2"},
    @{STT=10; Name="Zen Browser";             ID="Zen-Team.Zen-Browser"},

    # Utilities
    @{STT=11; Name="7-Zip";                   ID="7zip.7zip"},
    @{STT=12; Name="WinRAR";                  ID="RARLab.WinRAR"},
    @{STT=13; Name="PowerToys";               ID="Microsoft.PowerToys"},
    @{STT=14; Name="Windows Terminal";        ID="Microsoft.WindowsTerminal"},
    @{STT=15; Name="Everything";              ID="voidtools.Everything"},
    @{STT=16; Name="EarTrumpet";              ID="File-New-Project.EarTrumpet"},
    @{STT=17; Name="QuickLook";               ID="QL-Win.QuickLook"},
    @{STT=18; Name="TranslucentTB";           ID="TranslucentTB.TranslucentTB"},
    @{STT=19; Name="Twinkle Tray";            ID="xanderfrangos.twinkletray"},
    @{STT=20; Name="AutoHotkey";              ID="AutoHotkey.AutoHotkey"},
    @{STT=21; Name="Flow Launcher";           ID="Flow-Launcher.Flow-Launcher"},
    @{STT=22; Name="WizTree";                 ID="AntibodySoftware.WizTree"},
    @{STT=23; Name="WizFile";                 ID="AntibodySoftware.WizFile"},
    @{STT=24; Name="LockHunter";              ID="CrystalRich.LockHunter"},
    @{STT=25; Name="Bulk Crap Uninstaller";   ID="Klocman.BulkCrapUninstaller"},
    @{STT=26; Name="Revo Uninstaller";        ID="RevoUninstaller.RevoUninstaller"},
    @{STT=27; Name="Glary Utilities";         ID="Glarysoft.GlaryUtilities"},
    @{STT=28; Name="CCleaner";                ID="Piriform.CCleaner"},
    @{STT=29; Name="BleachBit";               ID="BleachBit.BleachBit"},
    @{STT=30; Name="NanaZip";                 ID="M2Team.NanaZip"},
    @{STT=31; Name="TeraCopy";                ID="CodeSector.TeraCopy"},
    @{STT=32; Name="LocalSend";               ID="LocalSend.LocalSend"},
    @{STT=33; Name="Motrix";                  ID="agalwood.Motrix"},
    @{STT=34; Name="JDownloader";             ID="AppWork.JDownloader"},
    @{STT=35; Name="Rainmeter";               ID="Rainmeter.Rainmeter"},
    @{STT=36; Name="Lively Wallpaper";        ID="rocksdanister.LivelyWallpaper"},
    @{STT=37; Name="ModernFlyouts";           ID="ModernFlyouts.ModernFlyouts"},
    @{STT=38; Name="OpenRGB";                 ID="OpenRGB.OpenRGB"},
    @{STT=39; Name="SignalRGB";               ID="WhirlwindFX.SignalRgb"},
    @{STT=40; Name="FanControl";              ID="Rem0o.FanControl"},
    @{STT=41; Name="MSI Afterburner";         ID="Guru3D.Afterburner"},
    @{STT=42; Name="NVCleanstall";            ID="TechPowerUp.NVCleanstall"},
    @{STT=43; Name="Borderless Gaming";       ID="Codeusa.BorderlessGaming"},
    @{STT=44; Name="WindowGrid";              ID="WindowGrid.WindowGrid"},
    @{STT=45; Name="VistaSwitcher";           ID="ntwind.VistaSwitcher"},

    # Development
    @{STT=46; Name="Visual Studio Code";      ID="Microsoft.VisualStudioCode"},
    @{STT=47; Name="VSCodium";                ID="VSCodium.VSCodium"},
    @{STT=48; Name="Git";                     ID="Git.Git"},
    @{STT=49; Name="GitHub Desktop";          ID="GitHub.GitHubDesktop"},
    @{STT=50; Name="GitKraken";               ID="Axosoft.GitKraken"},
    @{STT=51; Name="Sublime Text";            ID="SublimeHQ.SublimeText.4"},
    @{STT=52; Name="Notepad++";               ID="Notepad++.Notepad++"},
    @{STT=53; Name="Neovim";                  ID="Neovim.Neovim"},
    @{STT=54; Name="Helix";                   ID="Helix.Helix"},
    @{STT=55; Name="Zed";                     ID="Zed.Zed"},
    @{STT=56; Name="Pulsar";                  ID="Pulsar-Edit.Pulsar"},
    @{STT=57; Name="Python 3";                ID="Python.Python.3.12"},
    @{STT=58; Name="Node.js";                 ID="OpenJS.NodeJS"},
    @{STT=59; Name="Node.js LTS";             ID="OpenJS.NodeJS.LTS"},
    @{STT=60; Name="Go";                      ID="GoLang.Go"},
    @{STT=61; Name="Rust";                    ID="Rustlang.Rust.MSVC"},
    @{STT=62; Name="CMake";                   ID="Kitware.CMake"},
    @{STT=63; Name="Docker Desktop";          ID="Docker.DockerDesktop"},
    @{STT=64; Name="Vagrant";                 ID="Hashicorp.Vagrant"},
    @{STT=65; Name="Postman";                 ID="Postman.Postman"},

    # Multimedia Tools
    @{STT=66; Name="VLC Media Player";        ID="VideoLAN.VLC"},
    @{STT=67; Name="MPC-HC";                  ID="clsid2.mpc-hc"},
    @{STT=68; Name="K-Lite Codec Pack";       ID="CodecGuide.K-LiteCodecPack.Standard"},
    @{STT=69; Name="Spotify";                 ID="Spotify.Spotify"},
    @{STT=70; Name="foobar2000";              ID="PeterPawlowski.foobar2000"},
    @{STT=71; Name="MusicBee";                ID="MusicBee.MusicBee"},
    @{STT=72; Name="Strawberry";              ID="StrawberryMusicPlayer.Strawberry"},
    @{STT=73; Name="Audacity";                ID="Audacity.Audacity"},
    @{STT=74; Name="OBS Studio";              ID="OBSProject.OBSStudio"},
    @{STT=75; Name="HandBrake";               ID="HandBrake.HandBrake"},
    @{STT=76; Name="Shotcut";                 ID="Meltytech.Shotcut"},
    @{STT=77; Name="Kdenlive";                ID="KDE.Kdenlive"},
    @{STT=78; Name="Blender";                 ID="BlenderFoundation.Blender"},
    @{STT=79; Name="GIMP";                    ID="GIMP.GIMP.3"},
    @{STT=80; Name="Krita";                   ID="KDE.Krita"},
    @{STT=81; Name="Inkscape";                ID="Inkscape.Inkscape"},
    @{STT=82; Name="ImageGlass";              ID="DuongDieuPhap.ImageGlass"},
    @{STT=83; Name="SumatraPDF";              ID="SumatraPDF.SumatraPDF"},
    @{STT=84; Name="Foxit PDF Reader";        ID="Foxit.FoxitReader"},
    @{STT=85; Name="Adobe Acrobat Reader";    ID="Adobe.Acrobat.Reader.64-bit"},

    # Microsoft Tools & Runtimes
    @{STT=86; Name=".NET Desktop Runtime 8";  ID="Microsoft.DotNet.DesktopRuntime.8"},
    @{STT=87; Name=".NET Desktop Runtime 7";  ID="Microsoft.DotNet.DesktopRuntime.7"},
    @{STT=88; Name=".NET Desktop Runtime 6";  ID="Microsoft.DotNet.DesktopRuntime.6"},
    @{STT=89; Name="Visual C++ 2015-2022 x64";ID="Microsoft.VCRedist.2015+.x64"},
    @{STT=90; Name="Visual C++ 2015-2022 x86";ID="Microsoft.VCRedist.2015+.x86"},
    @{STT=91; Name="DirectX End-User Runtime";ID="Microsoft.DirectX.EndUserRuntime"},
    @{STT=92; Name="Sysinternals Suite";      ID="Microsoft.Sysinternals.Suite"},
    @{STT=93; Name="Autoruns";                ID="Microsoft.Sysinternals.Autoruns"},
    @{STT=94; Name="Process Monitor";         ID="Microsoft.Sysinternals.ProcessMonitor"},
    @{STT=95; Name="TCPView";                 ID="Microsoft.Sysinternals.TCPView"},
    @{STT=96; Name="RDCMan";                  ID="Microsoft.Sysinternals.RDCMan"},
    @{STT=97; Name="ZoomIt";                  ID="Microsoft.Sysinternals.ZoomIt"},
    @{STT=98; Name="Power BI Desktop";        ID="Microsoft.PowerBI"},
    @{STT=99; Name="Power Automate Desktop";  ID="Microsoft.PowerAutomateDesktop"},
    @{STT=100; Name="Azure Data Studio";      ID="Microsoft.AzureDataStudio"},
    @{STT=101; Name="SQL Server Management Studio"; ID="Microsoft.SQLServerManagementStudio"},

    # Pro Tools & Security
    @{STT=102; Name="Wireshark";              ID="WiresharkFoundation.Wireshark"},
    @{STT=103; Name="Nmap";                   ID="Insecure.Nmap"},
    @{STT=104; Name="Advanced IP Scanner";    ID="Famatech.AdvancedIPScanner"},
    @{STT=105; Name="Angry IP Scanner";       ID="angryziber.AngryIPScanner"},
    @{STT=106; Name="HeidiSQL";               ID="HeidiSQL.HeidiSQL"},
    @{STT=107; Name="Mullvad VPN";            ID="MullvadVPN.MullvadVPN"},
    @{STT=108; Name="Tailscale";              ID="tailscale.tailscale"},
    @{STT=109; Name="ZeroTier One";           ID="ZeroTier.ZeroTierOne"},
    @{STT=110; Name="WireGuard";              ID="WireGuard.WireGuard"},
    @{STT=111; Name="Portmaster";             ID="Safing.Portmaster"},
    @{STT=112; Name="SimpleWall";             ID="Henry++.simplewall"},
    @{STT=113; Name="Windows Firewall Control";ID="BiniSoft.WindowsFirewallControl"},
    @{STT=114; Name="Malwarebytes";           ID="Malwarebytes.Malwarebytes"},
    @{STT=115; Name="Display Driver Uninstaller"; ID="Wagnardsoft.DisplayDriverUninstaller"},

    # Communications
    @{STT=116; Name="Discord";                ID="Discord.Discord"},
    @{STT=117; Name="Telegram";               ID="Telegram.TelegramDesktop"},
    @{STT=118; Name="Signal";                 ID="OpenWhisperSystems.Signal"},
    @{STT=119; Name="Slack";                  ID="SlackTechnologies.Slack"},
    @{STT=120; Name="Zoom";                   ID="Zoom.Zoom"},
    @{STT=121; Name="Microsoft Teams";        ID="Microsoft.Teams"},
    @{STT=122; Name="Element";                ID="Element.Element"},
    @{STT=123; Name="Session";                ID="Session.Session"},
    @{STT=124; Name="Viber";                  ID="Rakuten.Viber"},
    @{STT=125; Name="Revolt";                 ID="Revolt.RevoltDesktop"},

    # Document & PDF
    @{STT=126; Name="LibreOffice";            ID="TheDocumentFoundation.LibreOffice"},
    @{STT=127; Name="ONLYOffice Desktop";     ID="ONLYOFFICE.DesktopEditors"},
    @{STT=128; Name="Foxit PDF Reader";       ID="Foxit.FoxitReader"},
    @{STT=129; Name="Adobe Acrobat Reader";   ID="Adobe.Acrobat.Reader.64-bit"},
    @{STT=130; Name="SumatraPDF";             ID="SumatraPDF.SumatraPDF"},
    @{STT=131; Name="PDFgear";                ID="PDFgear.PDFgear"},
    @{STT=132; Name="PDF24 Creator";          ID="geeksoftwareGmbH.PDF24Creator"},
    @{STT=133; Name="Okular";                 ID="KDE.Okular"},
    @{STT=134; Name="Obsidian";               ID="Obsidian.Obsidian"},
    @{STT=135; Name="Logseq";                 ID="Logseq.Logseq"},
    @{STT=136; Name="Joplin";                 ID="Joplin.Joplin"},
    @{STT=137; Name="Simplenote";             ID="Automattic.Simplenote"},
    @{STT=138; Name="Zim Desktop Wiki";       ID="Zimwiki.Zim"},
    @{STT=139; Name="Znote";                  ID="alagrede.znote"},
    @{STT=140; Name="Calibre";                ID="calibre.calibre"},

    # Other
    @{STT=141; Name="Everything";             ID="voidtools.Everything"},
    @{STT=142; Name="CrystalDiskInfo";        ID="CrystalDewWorld.CrystalDiskInfo"},
    @{STT=143; Name="CrystalDiskMark";        ID="CrystalDewWorld.CrystalDiskMark"},
    @{STT=144; Name="CPU-Z";                  ID="CPUID.CPU-Z"},
    @{STT=145; Name="GPU-Z";                  ID="TechPowerUp.GPU-Z"},
    @{STT=146; Name="HWiNFO";                 ID="REALiX.HWiNFO"},
    @{STT=147; Name="HWMonitor";              ID="CPUID.HWMonitor"},
    @{STT=148; Name="Rufus";                  ID="Rufus.Rufus"},
    @{STT=149; Name="Ventoy";                 ID="Ventoy.Ventoy"},
    @{STT=150; Name="Raspberry Pi Imager";    ID="RaspberryPiFoundation.RaspberryPiImager"},
    @{STT=151; Name="Sandboxie Plus";         ID="Sandboxie.Plus"},
    @{STT=152; Name="VirtualBox";             ID="Oracle.VirtualBox"},
    @{STT=153; Name="KDE Connect";            ID="KDE.KDEConnect"},
    @{STT=154; Name="LocalSend";              ID="LocalSend.LocalSend"},
    @{STT=155; Name="Motrix";                 ID="agalwood.Motrix"},
    @{STT=156; Name="JDownloader";            ID="AppWork.JDownloader"}
)

function Install-AppQuick {
    Reset-ConsoleStyle
    Show-SystemHeader
    Write-Host $logo -ForegroundColor $HEADER_COLOR

    Write-Host "`nDANH SÁCH ỨNG DỤNG CÓ THỂ CÀI NHANH" -ForegroundColor $HEADER_COLOR
    Write-Host ""

    # Chia danh sách 2 cột với category header rõ ràng + khoảng cách lớn
    $half = [math]::Ceiling($AppList.Count / 2)

    # BROWSERS
    Write-Host "BROWSERS" -ForegroundColor $HEADER_COLOR
    Write-Host "--------" -ForegroundColor $BORDER_COLOR
    for ($i = 0; $i -lt $half; $i++) {
        $left = $AppList[$i]
        $right = if ($i + $half -lt $AppList.Count) { $AppList[$i + $half] } else { $null }

        $leftStr = " [$($left.STT)] $($left.Name) ($($left.ID))"
        $rightStr = if ($right) { " [$($right.STT)] $($right.Name) ($($right.ID))" } else { "" }

        Write-Host ("{0,-50}{1}" -f $leftStr, $rightStr) -ForegroundColor $FG_COLOR
    }
    Write-Host ""
    Write-Host ""

    # UTILITIES
    Write-Host "UTILITIES" -ForegroundColor $HEADER_COLOR
    Write-Host "--------" -ForegroundColor $BORDER_COLOR
    Write-Host "Danh sách dài, tiếp tục ở cột bên phải..." -ForegroundColor $BORDER_COLOR
    Write-Host ""
    Write-Host ""

    # DEVELOPMENT
    Write-Host "DEVELOPMENT" -ForegroundColor $HEADER_COLOR
    Write-Host "----------" -ForegroundColor $BORDER_COLOR
    Write-Host "Danh sách dài, tiếp tục ở cột bên phải..." -ForegroundColor $BORDER_COLOR
    Write-Host ""
    Write-Host ""

    # MULTIMEDIA TOOLS
    Write-Host "MULTIMEDIA TOOLS" -ForegroundColor $HEADER_COLOR
    Write-Host "----------------" -ForegroundColor $BORDER_COLOR
    Write-Host "Danh sách dài, tiếp tục ở cột bên phải..." -ForegroundColor $BORDER_COLOR
    Write-Host ""
    Write-Host ""

    # MICROSOFT TOOLS & RUNTIMES
    Write-Host "MICROSOFT TOOLS & RUNTIMES" -ForegroundColor $HEADER_COLOR
    Write-Host "---------------------------" -ForegroundColor $BORDER_COLOR
    Write-Host "Danh sách dài, tiếp tục ở cột bên phải..." -ForegroundColor $BORDER_COLOR
    Write-Host ""
    Write-Host ""

    # PRO TOOLS & SECURITY
    Write-Host "PRO TOOLS & SECURITY" -ForegroundColor $HEADER_COLOR
    Write-Host "--------------------" -ForegroundColor $BORDER_COLOR
    Write-Host "Danh sách dài, tiếp tục ở cột bên phải..." -ForegroundColor $BORDER_COLOR
    Write-Host ""
    Write-Host ""

    # COMMUNICATIONS
    Write-Host "COMMUNICATIONS" -ForegroundColor $HEADER_COLOR
    Write-Host "--------------" -ForegroundColor $BORDER_COLOR
    Write-Host "Danh sách dài, tiếp tục ở cột bên phải..." -ForegroundColor $BORDER_COLOR
    Write-Host ""
    Write-Host ""

    # DOCUMENT & PDF
    Write-Host "DOCUMENT & PDF" -ForegroundColor $HEADER_COLOR
    Write-Host "--------------" -ForegroundColor $BORDER_COLOR
    Write-Host "Danh sách dài, tiếp tục ở cột bên phải..." -ForegroundColor $BORDER_COLOR
    Write-Host ""
    Write-Host ""

    # OTHER
    Write-Host "OTHER" -ForegroundColor $HEADER_COLOR
    Write-Host "-----" -ForegroundColor $BORDER_COLOR
    Write-Host "Danh sách dài, tiếp tục ở cột bên phải..." -ForegroundColor $BORDER_COLOR

    Write-Host ""
    Write-Host "-------------------------------" -ForegroundColor $BORDER_COLOR
    Write-Host "`nNhập STT (ví dụ: 1,4,7) hoặc nhập Winget ID trực tiếp:" -ForegroundColor $OPTION_COLOR
    Write-Host "Nhấn ESC để thoát về menu chính" -ForegroundColor $BORDER_COLOR

    # Bắt phím ESC trong option 2
    while ($true) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq "Escape") {
            Write-Host "`nThoát về menu chính..." -ForegroundColor $BORDER_COLOR
            return
        }
        if ($key.Key -eq "Enter") {
            $input = [Console]::In.ReadLine()
            break
        }
    }

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

# Các hàm khác (copy từ code cũ của bạn)
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

# Menu chính
do {
    Reset-ConsoleStyle
    Show-SystemHeader
    Write-Host $logo -ForegroundColor $HEADER_COLOR

    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║               MENU PMK TOOLBOX - SOFT NEON               ║" -ForegroundColor Magenta
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
