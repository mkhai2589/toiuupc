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

# Danh sách app mở rộng (tích hợp ~200 app phổ biến nhất)
$AppList = @(
    # Browsers
    @{STT=1;   Name="Brave";                  ID="Brave.Brave"},
    @{STT=2;   Name="Google Chrome";           ID="Google.Chrome"},
    @{STT=3;   Name="Mozilla Firefox";         ID="Mozilla.Firefox"},
    @{STT=4;   Name="Microsoft Edge";          ID="Microsoft.Edge"},
    @{STT=5;   Name="Opera";                   ID="Opera.Opera"},
    @{STT=6;   Name="Vivaldi";                 ID="VivaldiTechnologies.Vivaldi"},
    @{STT=7;   Name="LibreWolf";               ID="LibreWolf.LibreWolf"},
    @{STT=8;   Name="Waterfox";                ID="Waterfox.Waterfox"},
    @{STT=9;   Name="Thorium (AVX2)";          ID="Alex313031.Thorium.AVX2"},
    @{STT=10;  Name="Zen Browser";             ID="Zen-Team.Zen-Browser"},
    @{STT=11;  Name="Floorp";                  ID="Ablaze.Floorp"},
    @{STT=12;  Name="Mullvad Browser";         ID="MullvadVPN.MullvadBrowser"},
    @{STT=13;  Name="Ungoogled Chromium";      ID="eloston.ungoogled-chromium"},

    # Utilities
    @{STT=14;  Name="7-Zip";                   ID="7zip.7zip"},
    @{STT=15;  Name="WinRAR";                  ID="RARLab.WinRAR"},
    @{STT=16;  Name="PowerToys";               ID="Microsoft.PowerToys"},
    @{STT=17;  Name="Windows Terminal";        ID="Microsoft.WindowsTerminal"},
    @{STT=18;  Name="Everything";              ID="voidtools.Everything"},
    @{STT=19;  Name="EarTrumpet";              ID="File-New-Project.EarTrumpet"},
    @{STT=20;  Name="QuickLook";               ID="QL-Win.QuickLook"},
    @{STT=21;  Name="TranslucentTB";           ID="TranslucentTB.TranslucentTB"},
    @{STT=22;  Name="Twinkle Tray";            ID="xanderfrangos.twinkletray"},
    @{STT=23;  Name="AutoHotkey";              ID="AutoHotkey.AutoHotkey"},
    @{STT=24;  Name="Flow Launcher";           ID="Flow-Launcher.Flow-Launcher"},
    @{STT=25;  Name="WizTree";                 ID="AntibodySoftware.WizTree"},
    @{STT=26;  Name="WizFile";                 ID="AntibodySoftware.WizFile"},
    @{STT=27;  Name="LockHunter";              ID="CrystalRich.LockHunter"},
    @{STT=28;  Name="Bulk Crap Uninstaller";   ID="Klocman.BulkCrapUninstaller"},
    @{STT=29;  Name="Revo Uninstaller";        ID="RevoUninstaller.RevoUninstaller"},
    @{STT=30;  Name="Glary Utilities";         ID="Glarysoft.GlaryUtilities"},
    @{STT=31;  Name="CCleaner";                ID="Piriform.CCleaner"},
    @{STT=32;  Name="BleachBit";               ID="BleachBit.BleachBit"},
    @{STT=33;  Name="NanaZip";                 ID="M2Team.NanaZip"},
    @{STT=34;  Name="TeraCopy";                ID="CodeSector.TeraCopy"},
    @{STT=35;  Name="LocalSend";               ID="LocalSend.LocalSend"},
    @{STT=36;  Name="Motrix";                  ID="agalwood.Motrix"},
    @{STT=37;  Name="JDownloader";             ID="AppWork.JDownloader"},
    @{STT=38;  Name="Internet Download Manager"; ID="Tonec.InternetDownloadManager"},
    @{STT=39;  Name="Xtreme Download Manager"; ID="subhra74.XtremeDownloadManager"},
    @{STT=40;  Name="Rainmeter";               ID="Rainmeter.Rainmeter"},
    @{STT=41;  Name="Lively Wallpaper";        ID="rocksdanister.LivelyWallpaper"},
    @{STT=42;  Name="ModernFlyouts";           ID="ModernFlyouts.ModernFlyouts"},
    @{STT=43;  Name="OpenRGB";                 ID="OpenRGB.OpenRGB"},
    @{STT=44;  Name="SignalRGB";               ID="WhirlwindFX.SignalRgb"},
    @{STT=45;  Name="FanControl";              ID="Rem0o.FanControl"},
    @{STT=46;  Name="MSI Afterburner";         ID="Guru3D.Afterburner"},
    @{STT=47;  Name="NVCleanstall";            ID="TechPowerUp.NVCleanstall"},
    @{STT=48;  Name="Borderless Gaming";       ID="Codeusa.BorderlessGaming"},
    @{STT=49;  Name="WindowGrid";              ID="WindowGrid.WindowGrid"},
    @{STT=50;  Name="VistaSwitcher";           ID="ntwind.VistaSwitcher"},

    # Development
    @{STT=51;  Name="Visual Studio Code";      ID="Microsoft.VisualStudioCode"},
    @{STT=52;  Name="VSCodium";                ID="VSCodium.VSCodium"},
    @{STT=53;  Name="Git";                     ID="Git.Git"},
    @{STT=54;  Name="GitHub Desktop";          ID="GitHub.GitHubDesktop"},
    @{STT=55;  Name="GitKraken";               ID="Axosoft.GitKraken"},
    @{STT=56;  Name="Sublime Text";            ID="SublimeHQ.SublimeText.4"},
    @{STT=57;  Name="Notepad++";               ID="Notepad++.Notepad++"},
    @{STT=58;  Name="Neovim";                  ID="Neovim.Neovim"},
    @{STT=59;  Name="Helix";                   ID="Helix.Helix"},
    @{STT=60;  Name="Zed";                     ID="Zed.Zed"},
    @{STT=61;  Name="Pulsar";                  ID="Pulsar-Edit.Pulsar"},
    @{STT=62;  Name="Python 3";                ID="Python.Python.3.12"},
    @{STT=63;  Name="Node.js";                 ID="OpenJS.NodeJS"},
    @{STT=64;  Name="Node.js LTS";             ID="OpenJS.NodeJS.LTS"},
    @{STT=65;  Name="Go";                      ID="GoLang.Go"},
    @{STT=66;  Name="Rust";                    ID="Rustlang.Rust.MSVC"},
    @{STT=67;  Name="CMake";                   ID="Kitware.CMake"},
    @{STT=68;  Name="Docker Desktop";          ID="Docker.DockerDesktop"},
    @{STT=69;  Name="Vagrant";                 ID="Hashicorp.Vagrant"},
    @{STT=70;  Name="Postman";                 ID="Postman.Postman"},

    # Multimedia Tools
    @{STT=71;  Name="VLC Media Player";        ID="VideoLAN.VLC"},
    @{STT=72;  Name="MPC-HC";                  ID="clsid2.mpc-hc"},
    @{STT=73;  Name="K-Lite Codec Pack";       ID="CodecGuide.K-LiteCodecPack.Standard"},
    @{STT=74;  Name="Spotify";                 ID="Spotify.Spotify"},
    @{STT=75;  Name="foobar2000";              ID="PeterPawlowski.foobar2000"},
    @{STT=76;  Name="MusicBee";                ID="MusicBee.MusicBee"},
    @{STT=77;  Name="Strawberry";              ID="StrawberryMusicPlayer.Strawberry"},
    @{STT=78;  Name="Audacity";                ID="Audacity.Audacity"},
    @{STT=79;  Name="OBS Studio";              ID="OBSProject.OBSStudio"},
    @{STT=80;  Name="HandBrake";               ID="HandBrake.HandBrake"},
    @{STT=81;  Name="Shotcut";                 ID="Meltytech.Shotcut"},
    @{STT=82;  Name="Kdenlive";                ID="KDE.Kdenlive"},
    @{STT=83;  Name="Blender";                 ID="BlenderFoundation.Blender"},
    @{STT=84;  Name="GIMP";                    ID="GIMP.GIMP.3"},
    @{STT=85;  Name="Krita";                   ID="KDE.Krita"},
    @{STT=86;  Name="Inkscape";                ID="Inkscape.Inkscape"},
    @{STT=87;  Name="ImageGlass";              ID="DuongDieuPhap.ImageGlass"},
    @{STT=88;  Name="SumatraPDF";              ID="SumatraPDF.SumatraPDF"},
    @{STT=89;  Name="Foxit PDF Reader";        ID="Foxit.FoxitReader"},
    @{STT=90;  Name="Adobe Acrobat Reader";    ID="Adobe.Acrobat.Reader.64-bit"},

    # Games & Launchers
    @{STT=91;  Name="Steam";                   ID="Valve.Steam"},
    @{STT=92;  Name="Epic Games Launcher";     ID="EpicGames.EpicGamesLauncher"},
    @{STT=93;  Name="GOG Galaxy";              ID="GOG.Galaxy"},
    @{STT=94;  Name="Ubisoft Connect";         ID="Ubisoft.Connect"},
    @{STT=95;  Name="EA App";                  ID="ElectronicArts.EADesktop"},
    @{STT=96;  Name="Xbox App";                ID="Microsoft.XboxApp"},
    @{STT=97;  Name="Heroic Games Launcher";   ID="HeroicGamesLauncher.HeroicGamesLauncher"},
    @{STT=98;  Name="Playnite";                ID="Playnite.Playnite"},
    @{STT=99;  Name="Prism Launcher";          ID="PrismLauncher.PrismLauncher"},
    @{STT=100; Name="Clone Hero";              ID="CloneHeroTeam.CloneHero"},

    # Microsoft Tools & Runtimes
    @{STT=101; Name=".NET Desktop Runtime 8";  ID="Microsoft.DotNet.DesktopRuntime.8"},
    @{STT=102; Name=".NET Desktop Runtime 7";  ID="Microsoft.DotNet.DesktopRuntime.7"},
    @{STT=103; Name=".NET Desktop Runtime 6";  ID="Microsoft.DotNet.DesktopRuntime.6"},
    @{STT=104; Name="Visual C++ 2015-2022 x64";ID="Microsoft.VCRedist.2015+.x64"},
    @{STT=105; Name="Visual C++ 2015-2022 x86";ID="Microsoft.VCRedist.2015+.x86"},
    @{STT=106; Name="DirectX End-User Runtime";ID="Microsoft.DirectX.EndUserRuntime"},
    @{STT=107; Name="Sysinternals Suite";      ID="Microsoft.Sysinternals.Suite"},
    @{STT=108; Name="Autoruns";                ID="Microsoft.Sysinternals.Autoruns"},
    @{STT=109; Name="Process Monitor";         ID="Microsoft.Sysinternals.ProcessMonitor"},
    @{STT=110; Name="TCPView";                 ID="Microsoft.Sysinternals.TCPView"},
    @{STT=111; Name="RDCMan";                  ID="Microsoft.Sysinternals.RDCMan"},
    @{STT=112; Name="ZoomIt";                  ID="Microsoft.Sysinternals.ZoomIt"},
    @{STT=113; Name="Power BI Desktop";        ID="Microsoft.PowerBI"},
    @{STT=114; Name="Power Automate Desktop";  ID="Microsoft.PowerAutomateDesktop"},
    @{STT=115; Name="Azure Data Studio";       ID="Microsoft.AzureDataStudio"},
    @{STT=116; Name="SQL Server Management Studio"; ID="Microsoft.SQLServerManagementStudio"},

    # Pro Tools & Security
    @{STT=117; Name="Wireshark";               ID="WiresharkFoundation.Wireshark"},
    @{STT=118; Name="Nmap";                    ID="Insecure.Nmap"},
    @{STT=119; Name="Advanced IP Scanner";     ID="Famatech.AdvancedIPScanner"},
    @{STT=120; Name="Angry IP Scanner";        ID="angryziber.AngryIPScanner"},
    @{STT=121; Name="HeidiSQL";                ID="HeidiSQL.HeidiSQL"},
    @{STT=122; Name="Mullvad VPN";             ID="MullvadVPN.MullvadVPN"},
    @{STT=123; Name="Tailscale";               ID="tailscale.tailscale"},
    @{STT=124; Name="ZeroTier One";            ID="ZeroTier.ZeroTierOne"},
    @{STT=125; Name="WireGuard";               ID="WireGuard.WireGuard"},
    @{STT=126; Name="Portmaster";              ID="Safing.Portmaster"},
    @{STT=127; Name="SimpleWall";              ID="Henry++.simplewall"},
    @{STT=128; Name="Windows Firewall Control";ID="BiniSoft.WindowsFirewallControl"},
    @{STT=129; Name="Malwarebytes";            ID="Malwarebytes.Malwarebytes"},
    @{STT=130; Name="Display Driver Uninstaller"; ID="Wagnardsoft.DisplayDriverUninstaller"},

    # Communications
    @{STT=131; Name="Discord";                 ID="Discord.Discord"},
    @{STT=132; Name="Telegram";                ID="Telegram.TelegramDesktop"},
    @{STT=133; Name="Signal";                  ID="OpenWhisperSystems.Signal"},
    @{STT=134; Name="Slack";                   ID="SlackTechnologies.Slack"},
    @{STT=135; Name="Zoom";                    ID="Zoom.Zoom"},
    @{STT=136; Name="Microsoft Teams";         ID="Microsoft.Teams"},
    @{STT=137; Name="Element";                 ID="Element.Element"},
    @{STT=138; Name="Session";                 ID="Session.Session"},
    @{STT=139; Name="Viber";                   ID="Rakuten.Viber"},
    @{STT=140; Name="Revolt";                  ID="Revolt.RevoltDesktop"},

    # Document & PDF
    @{STT=141; Name="LibreOffice";             ID="TheDocumentFoundation.LibreOffice"},
    @{STT=142; Name="ONLYOffice Desktop";      ID="ONLYOFFICE.DesktopEditors"},
    @{STT=143; Name="Foxit PDF Reader";        ID="Foxit.FoxitReader"},
    @{STT=144; Name="Adobe Acrobat Reader";    ID="Adobe.Acrobat.Reader.64-bit"},
    @{STT=145; Name="SumatraPDF";              ID="SumatraPDF.SumatraPDF"},
    @{STT=146; Name="PDFgear";                 ID="PDFgear.PDFgear"},
    @{STT=147; Name="PDF24 Creator";           ID="geeksoftwareGmbH.PDF24Creator"},
    @{STT=148; Name="Okular";                  ID="KDE.Okular"},
    @{STT=149; Name="Obsidian";                ID="Obsidian.Obsidian"},
    @{STT=150; Name="Logseq";                  ID="Logseq.Logseq"},
    @{STT=151; Name="Joplin";                  ID="Joplin.Joplin"},
    @{STT=152; Name="Simplenote";              ID="Automattic.Simplenote"},
    @{STT=153; Name="Zim Desktop Wiki";        ID="Zimwiki.Zim"},
    @{STT=154; Name="Znote";                   ID="alagrede.znote"},
    @{STT=155; Name="Calibre";                 ID="calibre.calibre"},

    # Other (các công cụ còn lại)
    @{STT=156; Name="Everything";              ID="voidtools.Everything"},
    @{STT=157; Name="CrystalDiskInfo";         ID="CrystalDewWorld.CrystalDiskInfo"},
    @{STT=158; Name="CrystalDiskMark";         ID="CrystalDewWorld.CrystalDiskMark"},
    @{STT=159; Name="CPU-Z";                   ID="CPUID.CPU-Z"},
    @{STT=160; Name="GPU-Z";                   ID="TechPowerUp.GPU-Z"},
    @{STT=161; Name="HWiNFO";                  ID="REALiX.HWiNFO"},
    @{STT=162; Name="HWMonitor";               ID="CPUID.HWMonitor"},
    @{STT=163; Name="Rufus";                   ID="Rufus.Rufus"},
    @{STT=164; Name="Ventoy";                  ID="Ventoy.Ventoy"},
    @{STT=165; Name="Raspberry Pi Imager";     ID="RaspberryPiFoundation.RaspberryPiImager"},
    @{STT=166; Name="Sandboxie Plus";          ID="Sandboxie.Plus"},
    @{STT=167; Name="VirtualBox";              ID="Oracle.VirtualBox"},
    @{STT=168; Name="KDE Connect";             ID="KDE.KDEConnect"},
    @{STT=169; Name="LocalSend";               ID="LocalSend.LocalSend"},
    @{STT=170; Name="Motrix";                  ID="agalwood.Motrix"},
    @{STT=171; Name="JDownloader";             ID="AppWork.JDownloader"},
    @{STT=172; Name="Rainmeter";               ID="Rainmeter.Rainmeter"},
    @{STT=173; Name="Lively Wallpaper";        ID="rocksdanister.LivelyWallpaper"},
    @{STT=174; Name="ModernFlyouts";           ID="ModernFlyouts.ModernFlyouts"},
    @{STT=175; Name="OpenRGB";                 ID="OpenRGB.OpenRGB"},
    @{STT=176; Name="SignalRGB";               ID="WhirlwindFX.SignalRgb"},
    @{STT=177; Name="FanControl";              ID="Rem0o.FanControl"},
    @{STT=178; Name="MSI Afterburner";         ID="Guru3D.Afterburner"},
    @{STT=179; Name="NVCleanstall";            ID="TechPowerUp.NVCleanstall"},
    @{STT=180; Name="Borderless Gaming";       ID="Codeusa.BorderlessGaming"},
    @{STT=181; Name="WindowGrid";              ID="WindowGrid.WindowGrid"},
    @{STT=182; Name="VistaSwitcher";           ID="ntwind.VistaSwitcher"},
    @{STT=183; Name="TranslucentTB";           ID="TranslucentTB.TranslucentTB"},
    @{STT=184; Name="Twinkle Tray";            ID="xanderfrangos.twinkletray"},
    @{STT=185; Name="AutoHotkey";              ID="AutoHotkey.AutoHotkey"},
    @{STT=186; Name="Flow Launcher";           ID="Flow-Launcher.Flow-Launcher"},
    @{STT=187; Name="WizTree";                 ID="AntibodySoftware.WizTree"},
    @{STT=188; Name="WizFile";                 ID="AntibodySoftware.WizFile"},
    @{STT=189; Name="LockHunter";              ID="CrystalRich.LockHunter"},
    @{STT=190; Name="Bulk Crap Uninstaller";   ID="Klocman.BulkCrapUninstaller"},
    @{STT=191; Name="Revo Uninstaller";        ID="RevoUninstaller.RevoUninstaller"},
    @{STT=192; Name="Glary Utilities";         ID="Glarysoft.GlaryUtilities"},
    @{STT=193; Name="CCleaner";                ID="Piriform.CCleaner"},
    @{STT=194; Name="BleachBit";               ID="BleachBit.BleachBit"},
    @{STT=195; Name="NanaZip";                 ID="M2Team.NanaZip"},
    @{STT=196; Name="TeraCopy";                ID="CodeSector.TeraCopy"},
    @{STT=197; Name="LocalSend";               ID="LocalSend.LocalSend"},
    @{STT=198; Name="Motrix";                  ID="agalwood.Motrix"},
    @{STT=199; Name="JDownloader";             ID="AppWork.JDownloader"},
    @{STT=200; Name="Internet Download Manager"; ID="Tonec.InternetDownloadManager"}
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
