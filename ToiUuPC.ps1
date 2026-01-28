# ToiUuPC.ps1 - PMK Toolbox v3.0
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Minh Khải (PMK) - https://www.facebook.com/khaiitcntt
# Version: 3.2 - Clean Design, No Emoji, Single Page

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Check Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yeu cau chay voi quyen Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# ===== COLOR PALETTE =====
$TEXT_COLOR = "White"
$ACCENT_COLOR = "Cyan"
$SUCCESS_COLOR = "Green"
$ERROR_COLOR = "Red"
$BORDER_COLOR = "DarkGray"

# Reset console
function Reset-ConsoleStyle {
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = $TEXT_COLOR
    Clear-Host
}

# Header system info
function Show-SystemHeader {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cs = Get-CimInstance Win32_ComputerSystem
    $ram = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    
    Write-Host "==================================================================================" -ForegroundColor $BORDER_COLOR
    Write-Host "PMK TOOLBOX v3.2" -ForegroundColor $ACCENT_COLOR
    Write-Host "User: $($env:USERNAME) | PC: $($env:COMPUTERNAME) | OS: $($os.Caption)" -ForegroundColor $TEXT_COLOR
    Write-Host "CPU: $($cpu.Name.Split('@')[0].Trim()) | RAM: $ram GB" -ForegroundColor $TEXT_COLOR
    Write-Host "==================================================================================" -ForegroundColor $BORDER_COLOR
    Write-Host ""
}

# Logo
$logo = @"
   _____  __  __ _     _     _____          _       ____  
  |  __ \|  \/  | |   | |   / ____|        | |     / __ \ 
  | |__) | \  / | |   | |  | |     ___   __| | ___| |  | |
  |  ___/| |\/| | |   | |  | |    / _ \ / _` |/ _ \ |  | |
  | |    | |  | | |___| |__| |___| (_) | (_| |  __/ |__| |
  |_|    |_|  |_|______\_____\_____\___/ \__,_|\___|\____/ 
                     Toi Uu Windows Toan Dien
"@

# App categories
$AppCategories = @{
    "TRINH DUYET" = @(
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
    
    "TIEN ICH" = @(
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
    
    "PHAT TRIEN" = @(
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
    
    "DA PHUONG TIEN" = @(
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
    
    "VAN PHONG & PDF" = @(
        @{STT=51; Name="LibreOffice"; ID="TheDocumentFoundation.LibreOffice"},
        @{STT=52; Name="ONLYOffice Desktop"; ID="ONLYOFFICE.DesktopEditors"},
        @{STT=53; Name="SumatraPDF"; ID="SumatraPDF.SumatraPDF"},
        @{STT=54; Name="Foxit PDF Reader"; ID="Foxit.FoxitReader"},
        @{STT=55; Name="Adobe Acrobat Reader"; ID="Adobe.Acrobat.Reader.64-bit"},
        @{STT=56; Name="Obsidian"; ID="Obsidian.Obsidian"},
        @{STT=57; Name="Joplin"; ID="Joplin.Joplin"},
        @{STT=58; Name="Calibre"; ID="calibre.calibre"}
    )
    
    "CONG CU HE THONG" = @(
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
    
    "LIEN LAC" = @(
        @{STT=68; Name="Discord"; ID="Discord.Discord"},
        @{STT=69; Name="Telegram"; ID="Telegram.TelegramDesktop"},
        @{STT=70; Name="Signal"; ID="OpenWhisperSystems.Signal"},
        @{STT=71; Name="Zoom"; ID="Zoom.Zoom"},
        @{STT=72; Name="Microsoft Teams"; ID="Microsoft.Teams"}
    )
}

# Show app list
function Show-AppList {
    Reset-ConsoleStyle
    Show-SystemHeader
    
    Write-Host $logo -ForegroundColor $ACCENT_COLOR
    Write-Host ""
    Write-Host "DANH SACH UNG DUNG CO THE CAI NHANH" -ForegroundColor $ACCENT_COLOR
    Write-Host "====================================" -ForegroundColor $BORDER_COLOR
    Write-Host ""
    
    # Display all categories in one page
    foreach ($category in $AppCategories.Keys) {
        $apps = $AppCategories[$category]
        
        # Category header with spacing
        Write-Host $category -ForegroundColor $ACCENT_COLOR
        Write-Host "------------------------------------" -ForegroundColor $BORDER_COLOR
        
        # Apps in 2 columns
        $half = [Math]::Ceiling($apps.Count / 2)
        
        for ($j = 0; $j -lt $half; $j++) {
            $app1 = $apps[$j]
            $app2 = if ($j + $half -lt $apps.Count) { $apps[$j + $half] } else { $null }
            
            $line1 = " [$($app1.STT.ToString().PadLeft(2))] $($app1.Name.PadRight(25))"
            $line2 = if ($app2) { " [$($app2.STT.ToString().PadLeft(2))] $($app2.Name.PadRight(25))" } else { "" }
            
            Write-Host $line1 -NoNewline -ForegroundColor $TEXT_COLOR
            if ($app2) {
                Write-Host "    " -NoNewline
                Write-Host $line2 -ForegroundColor $TEXT_COLOR
            } else {
                Write-Host ""
            }
        }
        
        # Big spacing between categories
        Write-Host ""
        Write-Host ""
        Write-Host ""
    }
    
    Write-Host "====================================" -ForegroundColor $BORDER_COLOR
    Write-Host ""
    Write-Host "Huong dan:" -ForegroundColor $TEXT_COLOR
    Write-Host "  - Nhap STT (vi du: 1,4,7) de cai nhieu app cung luc" -ForegroundColor $TEXT_COLOR
    Write-Host "  - Nhap Winget ID truc tiep (vi du: Google.Chrome)" -ForegroundColor $TEXT_COLOR
    Write-Host "  - ESC: Thoat ve menu chinh" -ForegroundColor $TEXT_COLOR
    Write-Host ""
    Write-Host "Nhap lua chon cua ban: " -NoNewline -ForegroundColor $ACCENT_COLOR
    
    $input = Read-Host
    if ($input -eq "ESC" -or $input -eq "esc") {
        return $null
    }
    
    return $input
}

# Install apps
function Install-AppQuick {
    $input = Show-AppList
    if (-not $input) { return }
    
    Reset-ConsoleStyle
    Show-SystemHeader
    
    Write-Host "DANG CAI DAT UNG DUNG" -ForegroundColor $ACCENT_COLOR
    Write-Host "=====================" -ForegroundColor $BORDER_COLOR
    Write-Host ""
    
    $items = $input.Split(',').Trim()
    $successCount = 0
    $failCount = 0
    
    foreach ($item in $items) {
        $app = $null
        
        # Find app by STT
        if ($item -match '^\d+$') {
            foreach ($category in $AppCategories.Values) {
                $app = $category | Where-Object { $_.STT -eq [int]$item }
                if ($app) { break }
            }
        }
        
        if ($app) {
            Write-Host "Cai dat: " -NoNewline -ForegroundColor $TEXT_COLOR
            Write-Host $app.Name -ForegroundColor $ACCENT_COLOR
            Write-Host "Winget ID: " -NoNewline -ForegroundColor $TEXT_COLOR
            Write-Host $app.ID -ForegroundColor $TEXT_COLOR
            
            try {
                winget install --id $app.ID --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
                Write-Host "  Da cai thanh cong!" -ForegroundColor $SUCCESS_COLOR
                $successCount++
            }
            catch {
                Write-Host "  Loi khi cai dat!" -ForegroundColor $ERROR_COLOR
                $failCount++
            }
        }
        else {
            # Install by Winget ID directly
            Write-Host "Cai dat: " -NoNewline -ForegroundColor $TEXT_COLOR
            Write-Host $item -ForegroundColor $ACCENT_COLOR
            
            try {
                winget install --id $item --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
                Write-Host "  Da cai thanh cong!" -ForegroundColor $SUCCESS_COLOR
                $successCount++
            }
            catch {
                Write-Host "  Loi khi cai dat!" -ForegroundColor $ERROR_COLOR
                $failCount++
            }
        }
        Write-Host ""
    }
    
    Write-Host "=====================" -ForegroundColor $BORDER_COLOR
    Write-Host "Ket qua: " -NoNewline -ForegroundColor $TEXT_COLOR
    Write-Host "$successCount thanh cong, $failCount that bai" -ForegroundColor $(if ($failCount -eq 0) { $SUCCESS_COLOR } else { $ACCENT_COLOR })
    Write-Host ""
    
    Write-Host "Nhan phim bat ky de tiep tuc..." -ForegroundColor $TEXT_COLOR
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Disable telemetry
function Disable-TelemetryQuick {
    Reset-ConsoleStyle
    Show-SystemHeader
    
    Write-Host "VO HIEU HOA TELEMETRY" -ForegroundColor $ACCENT_COLOR
    Write-Host "======================" -ForegroundColor $BORDER_COLOR
    Write-Host ""
    
    $telemetryPaths = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
    )
    
    $success = 0
    
    foreach ($path in $telemetryPaths) {
        try {
            if (-not (Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }
            Set-ItemProperty -Path $path -Name "AllowTelemetry" -Value 0 -Type DWord -Force
            Write-Host "  Da vo hieu hoa: $($path.Split('\')[-1])" -ForegroundColor $SUCCESS_COLOR
            $success++
        }
        catch {
            Write-Host "  Loi: $($path.Split('\')[-1])" -ForegroundColor $ERROR_COLOR
        }
    }
    
    Write-Host ""
    Write-Host "Ket qua: " -NoNewline -ForegroundColor $TEXT_COLOR
    Write-Host "$success/$($telemetryPaths.Count) thanh cong" -ForegroundColor $(if ($success -eq $telemetryPaths.Count) { $SUCCESS_COLOR } else { $ACCENT_COLOR })
    Write-Host ""
    Write-Host "Can khoi dong lai de ap dung day du" -ForegroundColor $TEXT_COLOR
    Write-Host ""
    
    Write-Host "Nhan phim bat ky de tiep tuc..." -ForegroundColor $TEXT_COLOR
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Clean temp files
function Clean-TempFiles {
    Reset-ConsoleStyle
    Show-SystemHeader
    
    Write-Host "DON DEP FILE TAM" -ForegroundColor $ACCENT_COLOR
    Write-Host "=================" -ForegroundColor $BORDER_COLOR
    Write-Host ""
    
    $tempPaths = @(
        "$env:TEMP\*",
        "$env:SystemRoot\Temp\*",
        "$env:USERPROFILE\AppData\Local\Temp\*"
    )
    
    $totalFreed = 0
    
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            try {
                $files = Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue
                $size = ($files | Measure-Object -Property Length -Sum).Sum / 1MB
                
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                
                Write-Host "  Da don: " -NoNewline -ForegroundColor $TEXT_COLOR
                Write-Host "$([math]::Round($size, 2)) MB" -ForegroundColor $SUCCESS_COLOR
                
                $totalFreed += $size
            }
            catch {
                Write-Host "  Khong the don: $($path.Split('\')[-1])" -ForegroundColor $ERROR_COLOR
            }
        }
    }
    
    Write-Host ""
    Write-Host "Tong dung luong da giai phong: " -NoNewline -ForegroundColor $TEXT_COLOR
    Write-Host "$([math]::Round($totalFreed, 2)) MB" -ForegroundColor $SUCCESS_COLOR
    Write-Host ""
    
    Write-Host "Nhan phim bat ky de tiep tuc..." -ForegroundColor $TEXT_COLOR
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Disable unneeded services
function Disable-UnneededServices {
    Reset-ConsoleStyle
    Show-SystemHeader
    
    Write-Host "TAT DICH VU KHONG CAN THIET" -ForegroundColor $ACCENT_COLOR
    Write-Host "===========================" -ForegroundColor $BORDER_COLOR
    Write-Host ""
    
    $services = @(
        @{Name="DiagTrack"; Description="Windows Telemetry"},
        @{Name="dmwappushservice"; Description="Device Management"},
        @{Name="WMPNetworkSvc"; Description="Windows Media Player Sharing"},
        @{Name="RemoteRegistry"; Description="Remote Registry Access"},
        @{Name="XblAuthManager"; Description="Xbox Live Auth Manager"},
        @{Name="XblGameSave"; Description="Xbox Live Game Save"},
        @{Name="XboxNetApiSvc"; Description="Xbox Live Networking"}
    )
    
    $success = 0
    
    foreach ($svc in $services) {
        try {
            if (Get-Service $svc.Name -ErrorAction SilentlyContinue) {
                Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
                Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
                Write-Host "  Da tat: " -NoNewline -ForegroundColor $TEXT_COLOR
                Write-Host $svc.Description -ForegroundColor $SUCCESS_COLOR
                $success++
            }
        }
        catch {
            Write-Host "  Khong the tat: " -NoNewline -ForegroundColor $TEXT_COLOR
            Write-Host $svc.Description -ForegroundColor $ERROR_COLOR
        }
    }
    
    Write-Host ""
    Write-Host "Da tat thanh cong: " -NoNewline -ForegroundColor $TEXT_COLOR
    Write-Host "$success/$($services.Count) dich vu" -ForegroundColor $(if ($success -eq $services.Count) { $SUCCESS_COLOR } else { $ACCENT_COLOR })
    Write-Host ""
    
    Write-Host "Nhan phim bat ky de tiep tuc..." -ForegroundColor $TEXT_COLOR
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Create restore point
function Create-RestorePoint {
    Reset-ConsoleStyle
    Show-SystemHeader
    
    Write-Host "TAO DIEM KHOI PHUC HE THONG" -ForegroundColor $ACCENT_COLOR
    Write-Host "===========================" -ForegroundColor $BORDER_COLOR
    Write-Host ""
    
    try {
        $description = "PMK Toolbox - $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
        
        Write-Host "  Dang tao diem khoi phuc..." -ForegroundColor $TEXT_COLOR
        Write-Host "  Mo ta: $description" -ForegroundColor $TEXT_COLOR
        
        Checkpoint-Computer -Description $description -RestorePointType MODIFY_SETTINGS
        
        Write-Host ""
        Write-Host "  Da tao diem khoi phuc thanh cong!" -ForegroundColor $SUCCESS_COLOR
    }
    catch {
        Write-Host ""
        Write-Host "  Loi khi tao diem khoi phuc!" -ForegroundColor $ERROR_COLOR
        Write-Host "  Kich hoat System Restore trong Control Panel" -ForegroundColor $TEXT_COLOR
    }
    
    Write-Host ""
    
    Write-Host "Nhan phim bat ky de tiep tuc..." -ForegroundColor $TEXT_COLOR
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Main menu
function Show-MainMenu {
    do {
        Reset-ConsoleStyle
        Show-SystemHeader
        
        Write-Host $logo -ForegroundColor $ACCENT_COLOR
        Write-Host ""
        Write-Host "MENU CHINH - PMK TOOLBOX" -ForegroundColor $ACCENT_COLOR
        Write-Host "=========================" -ForegroundColor $BORDER_COLOR
        Write-Host ""
        
        Write-Host " [1] Cai dat ung dung nhanh" -ForegroundColor $ACCENT_COLOR
        Write-Host " [2] Vo hieu hoa Telemetry" -ForegroundColor $ACCENT_COLOR
        Write-Host " [3] Don dep file tam" -ForegroundColor $ACCENT_COLOR
        Write-Host " [4] Tat dich vu khong can thiet" -ForegroundColor $ACCENT_COLOR
        Write-Host " [5] Tao diem khoi phuc" -ForegroundColor $ACCENT_COLOR
        Write-Host " [6] Thoat" -ForegroundColor $ACCENT_COLOR
        Write-Host ""
        Write-Host "=========================" -ForegroundColor $BORDER_COLOR
        Write-Host ""
        Write-Host "Nhap so lua chon (1-6): " -NoNewline -ForegroundColor $ACCENT_COLOR
        
        $choice = Read-Host
        
        switch ($choice) {
            "1" { Install-AppQuick }
            "2" { Disable-TelemetryQuick }
            "3" { Clean-TempFiles }
            "4" { Disable-UnneededServices }
            "5" { Create-RestorePoint }
            "6" { 
                Write-Host ""
                Write-Host "Tam biet! Cam on da su dung PMK Toolbox!" -ForegroundColor $ACCENT_COLOR
                Start-Sleep 2
                exit 
            }
            default {
                Write-Host ""
                Write-Host "Lua chon khong hop le! Vui long chon 1-6" -ForegroundColor $ERROR_COLOR
                Start-Sleep 1
            }
        }
        
    } while ($true)
}

# Run program
try {
    Show-MainMenu
}
catch {
    Write-Host ""
    Write-Host "Da xay ra loi!" -ForegroundColor $ERROR_COLOR
    Write-Host ""
    Write-Host "Nhan phim bat ky de thoat..." -ForegroundColor $TEXT_COLOR
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
