# ToiUuPC.ps1 - PMK Toolbox v3.0
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Minh Khải (PMK) - https://www.facebook.com/khaiitcntt
# Version: 3.1 - Modern Clean Design with Category Layout

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Check Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# ===== MODERN COLOR PALETTE =====
$BG_COLOR      = "Black"
$PRIMARY_COLOR = "Cyan"
$ACCENT_COLOR  = "Magenta"
$SUCCESS_COLOR = "Green"
$WARNING_COLOR = "Yellow"
$ERROR_COLOR   = "Red"
$INFO_COLOR    = "DarkGray"
$TEXT_COLOR    = "White"
$CATEGORY_COLOR = "DarkCyan"
$BORDER_COLOR  = "Gray"

# Reset console
function Reset-ConsoleStyle {
    $Host.UI.RawUI.BackgroundColor = $BG_COLOR
    $Host.UI.RawUI.ForegroundColor = $TEXT_COLOR
    Clear-Host
}

# Header hệ thống
function Show-SystemHeader {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cs = Get-CimInstance Win32_ComputerSystem
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    $ram = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    
    $time = Get-Date -Format "HH:mm:ss dd/MM/yyyy"
    
    Write-Host "╔════════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $PRIMARY_COLOR
    Write-Host "║" -NoNewline -ForegroundColor $PRIMARY_COLOR
    Write-Host " PMK TOOLBOX v3.1 " -NoNewline -ForegroundColor $ACCENT_COLOR
    Write-Host "|" -NoNewline -ForegroundColor $PRIMARY_COLOR
    Write-Host " User: $($env:USERNAME) " -NoNewline -ForegroundColor $TEXT_COLOR
    Write-Host "|" -NoNewline -ForegroundColor $PRIMARY_COLOR
    Write-Host " PC: $($env:COMPUTERNAME) " -NoNewline -ForegroundColor $TEXT_COLOR
    Write-Host "|" -NoNewline -ForegroundColor $PRIMARY_COLOR
    Write-Host " Time: $time " -NoNewline -ForegroundColor $TEXT_COLOR
    Write-Host "║" -ForegroundColor $PRIMARY_COLOR
    
    Write-Host "║" -NoNewline -ForegroundColor $PRIMARY_COLOR
    Write-Host " OS: $($os.Caption) ($($os.OSArchitecture)) " -NoNewline -ForegroundColor $TEXT_COLOR
    Write-Host "|" -NoNewline -ForegroundColor $PRIMARY_COLOR
    Write-Host " CPU: $($cpu.Name.Split('@')[0].Trim()) " -NoNewline -ForegroundColor $TEXT_COLOR
    Write-Host "|" -NoNewline -ForegroundColor $PRIMARY_COLOR
    Write-Host " RAM: $ram GB " -NoNewline -ForegroundColor $TEXT_COLOR
    Write-Host "║" -ForegroundColor $PRIMARY_COLOR
    
    Write-Host "╚════════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $PRIMARY_COLOR
    Write-Host ""
}

# Logo đơn giản
$logo = @"
   ██████╗ ███╗   ███╗██╗  ██╗      ████████╗ ██████╗  ██████╗ ██╗     
   ██╔══██╗████╗ ████║██║ ██╔╝      ╚══██╔══╝██╔═══██╗██╔═══██╗██║     
   ██████╔╝██╔████╔██║█████╔╝          ██║   ██║   ██║██║   ██║██║     
   ██╔═══╝ ██║╚██╔╝██║██╔═██╗          ██║   ██║   ██║██║   ██║██║     
   ██║     ██║ ╚═╝ ██║██║  ██╗         ██║   ╚██████╔╝╚██████╔╝███████╗
   ╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝         ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
                     Tối Ưu Hóa Windows Toàn Diện
"@

# Danh sách app với categories
$AppCategories = @{
    "🌐 TRÌNH DUYỆT" = @(
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
    
    "🛠️ TIỆN ÍCH" = @(
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
    
    "💻 PHÁT TRIỂN" = @(
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
    
    "🎬 ĐA PHƯƠNG TIỆN" = @(
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
    
    "📁 VĂN PHÒNG & PDF" = @(
        @{STT=51; Name="LibreOffice"; ID="TheDocumentFoundation.LibreOffice"},
        @{STT=52; Name="ONLYOffice Desktop"; ID="ONLYOFFICE.DesktopEditors"},
        @{STT=53; Name="SumatraPDF"; ID="SumatraPDF.SumatraPDF"},
        @{STT=54; Name="Foxit PDF Reader"; ID="Foxit.FoxitReader"},
        @{STT=55; Name="Adobe Acrobat Reader"; ID="Adobe.Acrobat.Reader.64-bit"},
        @{STT=56; Name="Obsidian"; ID="Obsidian.Obsidian"},
        @{STT=57; Name="Joplin"; ID="Joplin.Joplin"},
        @{STT=58; Name="Calibre"; ID="calibre.calibre"}
    )
    
    "🔧 CÔNG CỤ HỆ THỐNG" = @(
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
    
    "📞 LIÊN LẠC" = @(
        @{STT=68; Name="Discord"; ID="Discord.Discord"},
        @{STT=69; Name="Telegram"; ID="Telegram.TelegramDesktop"},
        @{STT=70; Name="Signal"; ID="OpenWhisperSystems.Signal"},
        @{STT=71; Name="Zoom"; ID="Zoom.Zoom"},
        @{STT=72; Name="Microsoft Teams"; ID="Microsoft.Teams"}
    )
}

# Hàm hiển thị danh sách app theo category
function Show-AppList {
    Reset-ConsoleStyle
    Show-SystemHeader
    
    # Logo centered
    $logoLines = $logo -split "`n"
    foreach ($line in $logoLines) {
        Write-Host $line -ForegroundColor $PRIMARY_COLOR
    }
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $ACCENT_COLOR
    Write-Host "║" -NoNewline -ForegroundColor $ACCENT_COLOR
    Write-Host "                          DANH SÁCH ỨNG DỤNG CÓ THỂ CÀI NHANH                          " -ForegroundColor $WARNING_COLOR
    Write-Host "║" -ForegroundColor $ACCENT_COLOR
    Write-Host "╚════════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $ACCENT_COLOR
    
    Write-Host ""
    
    $currentPage = 0
    $categoriesPerPage = 3
    $categoryKeys = @($AppCategories.Keys)
    $totalPages = [Math]::Ceiling($categoryKeys.Count / $categoriesPerPage)
    
    do {
        Reset-ConsoleStyle
        Show-SystemHeader
        
        Write-Host "Trang $($currentPage + 1)/$totalPages" -ForegroundColor $INFO_COLOR
        Write-Host "─────────────────────────────────────────────────────────────────────────────────────" -ForegroundColor $BORDER_COLOR
        Write-Host ""
        
        # Hiển thị các category trong trang hiện tại
        $startIdx = $currentPage * $categoriesPerPage
        $endIdx = [Math]::Min($startIdx + $categoriesPerPage - 1, $categoryKeys.Count - 1)
        
        for ($i = $startIdx; $i -le $endIdx; $i++) {
            $category = $categoryKeys[$i]
            $apps = $AppCategories[$category]
            
            # Category header
            Write-Host " " -NoNewline
            Write-Host $category -ForegroundColor $CATEGORY_COLOR
            Write-Host " ──────────────────────────────────────────────────────" -ForegroundColor $BORDER_COLOR
            
            # Apps in 2 columns
            $half = [Math]::Ceiling($apps.Count / 2)
            
            for ($j = 0; $j -lt $half; $j++) {
                $app1 = $apps[$j]
                $app2 = if ($j + $half -lt $apps.Count) { $apps[$j + $half] } else { $null }
                
                $line1 = "  [$($app1.STT.ToString().PadLeft(2))] $($app1.Name.PadRight(25))"
                $line2 = if ($app2) { "  [$($app2.STT.ToString().PadLeft(2))] $($app2.Name.PadRight(25))" } else { "" }
                
                Write-Host $line1 -NoNewline -ForegroundColor $TEXT_COLOR
                if ($app2) {
                    Write-Host "│" -NoNewline -ForegroundColor $BORDER_COLOR
                    Write-Host $line2 -ForegroundColor $TEXT_COLOR
                } else {
                    Write-Host ""
                }
            }
            
            Write-Host ""
            Write-Host ""
        }
        
        Write-Host "═══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor $BORDER_COLOR
        Write-Host ""
        Write-Host "Hướng dẫn:" -ForegroundColor $INFO_COLOR
        Write-Host "  • Nhập STT (ví dụ: 1,4,7) để cài nhiều app cùng lúc" -ForegroundColor $TEXT_COLOR
        Write-Host "  • Nhập Winget ID trực tiếp (ví dụ: Google.Chrome)" -ForegroundColor $TEXT_COLOR
        Write-Host "  • N: Trang tiếp | P: Trang trước | ESC: Thoát" -ForegroundColor $TEXT_COLOR
        Write-Host ""
        Write-Host "Nhập lựa chọn của bạn: " -NoNewline -ForegroundColor $PRIMARY_COLOR
        
        $key = [Console]::ReadKey($true)
        
        if ($key.Key -eq "Escape") {
            return $null
        }
        elseif ($key.Key -eq "N" -or $key.Key -eq "RightArrow") {
            if ($currentPage -lt $totalPages - 1) {
                $currentPage++
            }
        }
        elseif ($key.Key -eq "P" -or $key.Key -eq "LeftArrow") {
            if ($currentPage -gt 0) {
                $currentPage--
            }
        }
        elseif ($key.Key -eq "Enter") {
            $input = Read-Host "`nNhập STT hoặc Winget ID"
            return $input
        }
        
    } while ($true)
}

# Hàm cài app
function Install-AppQuick {
    $input = Show-AppList
    if (-not $input) { return }
    
    Reset-ConsoleStyle
    Show-SystemHeader
    
    Write-Host "╔════════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $ACCENT_COLOR
    Write-Host "║" -NoNewline -ForegroundColor $ACCENT_COLOR
    Write-Host "                              ĐANG CÀI ĐẶT ỨNG DỤNG                              " -ForegroundColor $WARNING_COLOR
    Write-Host "║" -ForegroundColor $ACCENT_COLOR
    Write-Host "╚════════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $ACCENT_COLOR
    Write-Host ""
    
    $items = $input.Split(',').Trim()
    $successCount = 0
    $failCount = 0
    
    foreach ($item in $items) {
        $app = $null
        
        # Tìm app theo STT
        if ($item -match '^\d+$') {
            foreach ($category in $AppCategories.Values) {
                $app = $category | Where-Object { $_.STT -eq [int]$item }
                if ($app) { break }
            }
        }
        
        if ($app) {
            Write-Host "┌─" -ForegroundColor $BORDER_COLOR
            Write-Host "│ Đang cài đặt: " -NoNewline -ForegroundColor $TEXT_COLOR
            Write-Host $app.Name -ForegroundColor $PRIMARY_COLOR
            Write-Host "│ Winget ID: " -NoNewline -ForegroundColor $TEXT_COLOR
            Write-Host $app.ID -ForegroundColor $INFO_COLOR
            Write-Host "└─" -ForegroundColor $BORDER_COLOR
            
            try {
                winget install --id $app.ID --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
                Write-Host "   ✅ Đã cài thành công!" -ForegroundColor $SUCCESS_COLOR
                $successCount++
            }
            catch {
                Write-Host "   ❌ Lỗi khi cài đặt: $_" -ForegroundColor $ERROR_COLOR
                $failCount++
            }
        }
        else {
            # Cài bằng Winget ID trực tiếp
            Write-Host "┌─" -ForegroundColor $BORDER_COLOR
            Write-Host "│ Đang cài đặt: " -NoNewline -ForegroundColor $TEXT_COLOR
            Write-Host $item -ForegroundColor $PRIMARY_COLOR
            Write-Host "└─" -ForegroundColor $BORDER_COLOR
            
            try {
                winget install --id $item --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
                Write-Host "   ✅ Đã cài thành công!" -ForegroundColor $SUCCESS_COLOR
                $successCount++
            }
            catch {
                Write-Host "   ❌ Lỗi khi cài đặt: $_" -ForegroundColor $ERROR_COLOR
                $failCount++
            }
        }
        Write-Host ""
    }
    
    Write-Host "═══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor $BORDER_COLOR
    Write-Host "Kết quả: " -NoNewline -ForegroundColor $TEXT_COLOR
    Write-Host "$successCount thành công, $failCount thất bại" -ForegroundColor $(if ($failCount -eq 0) { $SUCCESS_COLOR } else { $WARNING_COLOR })
    Write-Host ""
    
    Write-Host "Nhấn phím bất kỳ để tiếp tục..." -ForegroundColor $INFO_COLOR
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Các hàm tối ưu hệ thống
function Disable-TelemetryQuick {
    Reset-ConsoleStyle
    Show-SystemHeader
    
    Write-Host "╔════════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $ACCENT_COLOR
    Write-Host "║" -NoNewline -ForegroundColor $ACCENT_COLOR
    Write-Host "                              VÔ HIỆU HÓA TELEMETRY                              " -ForegroundColor $WARNING_COLOR
    Write-Host "║" -ForegroundColor $ACCENT_COLOR
    Write-Host "╚════════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $ACCENT_COLOR
    Write-Host ""
    
    $telemetryPaths = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
    )
    
    $success = 0
    $total = $telemetryPaths.Count
    
    foreach ($path in $telemetryPaths) {
        try {
            if (-not (Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }
            Set-ItemProperty -Path $path -Name "AllowTelemetry" -Value 0 -Type DWord -Force
            Write-Host "  ✅ $($path.Split('\')[-1])" -ForegroundColor $SUCCESS_COLOR
            $success++
        }
        catch {
            Write-Host "  ❌ $($path.Split('\')[-1]): $_" -ForegroundColor $ERROR_COLOR
        }
    }
    
    Write-Host ""
    Write-Host "═" * 80 -ForegroundColor $BORDER_COLOR
    Write-Host "Kết quả: " -NoNewline -ForegroundColor $TEXT_COLOR
    Write-Host "$success/$total thành công" -ForegroundColor $(if ($success -eq $total) { $SUCCESS_COLOR } else { $WARNING_COLOR })
    Write-Host ""
    Write-Host "Lưu ý: Cần khởi động lại để áp dụng đầy đủ" -ForegroundColor $INFO_COLOR
    Write-Host ""
    
    Write-Host "Nhấn phím bất kỳ để tiếp tục..." -ForegroundColor $INFO_COLOR
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Clean-TempFiles {
    Reset-ConsoleStyle
    Show-SystemHeader
    
    Write-Host "╔════════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $ACCENT_COLOR
    Write-Host "║" -NoNewline -ForegroundColor $ACCENT_COLOR
    Write-Host "                               DỌN DẸP FILE TẠM                                " -ForegroundColor $WARNING_COLOR
    Write-Host "║" -ForegroundColor $ACCENT_COLOR
    Write-Host "╚════════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $ACCENT_COLOR
    Write-Host ""
    
    $tempPaths = @(
        "$env:TEMP\*",
        "$env:SystemRoot\Temp\*",
        "$env:SystemRoot\Prefetch\*",
        "$env:USERPROFILE\AppData\Local\Temp\*"
    )
    
    $totalFreed = 0
    
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            try {
                $files = Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue
                $size = ($files | Measure-Object -Property Length -Sum).Sum / 1MB
                
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                
                Write-Host "  🗑️  Đã dọn: " -NoNewline -ForegroundColor $TEXT_COLOR
                Write-Host "$([math]::Round($size, 2)) MB" -ForegroundColor $PRIMARY_COLOR
                Write-Host "     Từ: $($path.Split('\')[-2..-1] -join '\')" -ForegroundColor $INFO_COLOR
                
                $totalFreed += $size
            }
            catch {
                Write-Host "  ⚠️  Không thể dọn: $($path.Split('\')[-1])" -ForegroundColor $WARNING_COLOR
            }
        }
    }
    
    Write-Host ""
    Write-Host "═" * 80 -ForegroundColor $BORDER_COLOR
    Write-Host "Tổng dung lượng đã giải phóng: " -NoNewline -ForegroundColor $TEXT_COLOR
    Write-Host "$([math]::Round($totalFreed, 2)) MB" -ForegroundColor $SUCCESS_COLOR
    Write-Host ""
    
    Write-Host "Nhấn phím bất kỳ để tiếp tục..." -ForegroundColor $INFO_COLOR
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Disable-UnneededServices {
    Reset-ConsoleStyle
    Show-SystemHeader
    
    Write-Host "╔════════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $ACCENT_COLOR
    Write-Host "║" -NoNewline -ForegroundColor $ACCENT_COLOR
    Write-Host "                            TẮT DỊCH VỤ KHÔNG CẦN THIẾT                           " -ForegroundColor $WARNING_COLOR
    Write-Host "║" -ForegroundColor $ACCENT_COLOR
    Write-Host "╚════════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $ACCENT_COLOR
    Write-Host ""
    
    $services = @(
        @{Name="DiagTrack"; Description="Windows Telemetry"},
        @{Name="dmwappushservice"; Description="Device Management"},
        @{Name="WMPNetworkSvc"; Description="Windows Media Player Sharing"},
        @{Name="RemoteRegistry"; Description="Remote Registry Access"},
        @{Name="XblAuthManager"; Description="Xbox Live Auth Manager"},
        @{Name="XblGameSave"; Description="Xbox Live Game Save"},
        @{Name="XboxNetApiSvc"; Description="Xbox Live Networking"},
        @{Name="MapsBroker"; Description="Downloaded Maps Manager"},
        @{Name="lfsvc"; Description="Geo Location Service"}
    )
    
    $success = 0
    
    foreach ($svc in $services) {
        try {
            if (Get-Service $svc.Name -ErrorAction SilentlyContinue) {
                Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
                Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
                Write-Host "  ✅ Đã tắt: " -NoNewline -ForegroundColor $SUCCESS_COLOR
                Write-Host $svc.Description -ForegroundColor $TEXT_COLOR
                $success++
            }
        }
        catch {
            Write-Host "  ❌ Không thể tắt: " -NoNewline -ForegroundColor $ERROR_COLOR
            Write-Host $svc.Description -ForegroundColor $TEXT_COLOR
        }
    }
    
    Write-Host ""
    Write-Host "═" * 80 -ForegroundColor $BORDER_COLOR
    Write-Host "Đã tắt thành công: " -NoNewline -ForegroundColor $TEXT_COLOR
    Write-Host "$success/$($services.Count) dịch vụ" -ForegroundColor $(if ($success -eq $services.Count) { $SUCCESS_COLOR } else { $WARNING_COLOR })
    Write-Host ""
    
    Write-Host "Nhấn phím bất kỳ để tiếp tục..." -ForegroundColor $INFO_COLOR
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Create-RestorePoint {
    Reset-ConsoleStyle
    Show-SystemHeader
    
    Write-Host "╔════════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $ACCENT_COLOR
    Write-Host "║" -NoNewline -ForegroundColor $ACCENT_COLOR
    Write-Host "                           TẠO ĐIỂM KHÔI PHỤC HỆ THỐNG                            " -ForegroundColor $WARNING_COLOR
    Write-Host "║" -ForegroundColor $ACCENT_COLOR
    Write-Host "╚════════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $ACCENT_COLOR
    Write-Host ""
    
    try {
        $description = "PMK Toolbox - $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
        
        Write-Host "  ⏳ Đang tạo điểm khôi phục..." -ForegroundColor $TEXT_COLOR
        Write-Host "  📝 Mô tả: $description" -ForegroundColor $INFO_COLOR
        
        Checkpoint-Computer -Description $description -RestorePointType MODIFY_SETTINGS
        
        Write-Host ""
        Write-Host "  ✅ Đã tạo điểm khôi phục thành công!" -ForegroundColor $SUCCESS_COLOR
        Write-Host ""
        Write-Host "  💡 Lưu ý: Điểm khôi phục sẽ tự động xóa khi đầy dung lượng" -ForegroundColor $INFO_COLOR
    }
    catch {
        Write-Host ""
        Write-Host "  ❌ Lỗi khi tạo điểm khôi phục: $_" -ForegroundColor $ERROR_COLOR
        Write-Host ""
        Write-Host "  🔧 Khắc phục: Bật System Restore trong Control Panel > System > System Protection" -ForegroundColor $WARNING_COLOR
    }
    
    Write-Host ""
    Write-Host "═" * 80 -ForegroundColor $BORDER_COLOR
    Write-Host ""
    
    Write-Host "Nhấn phím bất kỳ để tiếp tục..." -ForegroundColor $INFO_COLOR
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Menu chính
function Show-MainMenu {
    do {
        Reset-ConsoleStyle
        Show-SystemHeader
        
        # Logo
        $logoLines = $logo -split "`n"
        foreach ($line in $logoLines) {
            Write-Host $line -ForegroundColor $PRIMARY_COLOR
        }
        
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $ACCENT_COLOR
        Write-Host "║" -NoNewline -ForegroundColor $ACCENT_COLOR
        Write-Host "                               MENU CHÍNH - PMK TOOLBOX                               " -ForegroundColor $WARNING_COLOR
        Write-Host "║" -ForegroundColor $ACCENT_COLOR
        Write-Host "╚════════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $ACCENT_COLOR
        Write-Host ""
        
        $menuItems = @(
            @{Number=1; Title="📦 Cài đặt ứng dụng nhanh"; Description="Cài nhiều app từ danh sách Winget"},
            @{Number=2; Title="🚫 Vô hiệu hóa Telemetry"; Description="Tắt thu thập dữ liệu Windows"},
            @{Number=3; Title="🧹 Dọn dẹp file tạm"; Description="Xóa file rác, giải phóng dung lượng"},
            @{Number=4; Title="⚙️ Tắt dịch vụ không cần thiết"; Description="Tối ưu hiệu năng hệ thống"},
            @{Number=5; Title="💾 Tạo điểm khôi phục"; Description="Backup hệ thống trước khi thay đổi"},
            @{Number=6; Title="ℹ️ Thông tin hệ thống"; Description="Xem chi tiết cấu hình PC"},
            @{Number=7; Title="🚪 Thoát"; Description="Đóng PMK Toolbox"}
        )
        
        # Hiển thị menu items
        foreach ($item in $menuItems) {
            Write-Host "  [" -NoNewline -ForegroundColor $ACCENT_COLOR
            Write-Host "$($item.Number)" -NoNewline -ForegroundColor $WARNING_COLOR
            Write-Host "] " -NoNewline -ForegroundColor $ACCENT_COLOR
            Write-Host "$($item.Title.PadRight(30))" -NoNewline -ForegroundColor $TEXT_COLOR
            Write-Host "│ " -NoNewline -ForegroundColor $BORDER_COLOR
            Write-Host $item.Description -ForegroundColor $INFO_COLOR
        }
        
        Write-Host ""
        Write-Host "─" * 80 -ForegroundColor $BORDER_COLOR
        Write-Host "Nhập số lựa chọn (1-7) hoặc ESC để thoát: " -NoNewline -ForegroundColor $PRIMARY_COLOR
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        if ($key.VirtualKeyCode -eq 27) { # ESC
            Write-Host "`n`n👋 Tạm biệt! Cảm ơn đã sử dụng PMK Toolbox!" -ForegroundColor $PRIMARY_COLOR
            Start-Sleep 2
            exit
        }
        
        $choice = [char]$key.Character
        
        switch ($choice) {
            "1" { Install-AppQuick }
            "2" { Disable-TelemetryQuick }
            "3" { Clean-TempFiles }
            "4" { Disable-UnneededServices }
            "5" { Create-RestorePoint }
            "6" { 
                Reset-ConsoleStyle
                Show-SystemHeader
                Write-Host "Nhấn phím bất kỳ để tiếp tục..." -ForegroundColor $INFO_COLOR
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "7" { 
                Write-Host "`n`n👋 Tạm biệt! Cảm ơn đã sử dụng PMK Toolbox!" -ForegroundColor $PRIMARY_COLOR
                Start-Sleep 2
                exit 
            }
            default {
                Write-Host "`n❌ Lựa chọn không hợp lệ! Vui lòng chọn 1-7" -ForegroundColor $ERROR_COLOR
                Start-Sleep 1
            }
        }
        
    } while ($true)
}

# Chạy chương trình
try {
    Show-MainMenu
}
catch {
    Write-Host "`n❌ Đã xảy ra lỗi: $_" -ForegroundColor $ERROR_COLOR
    Write-Host "`nNhấn phím bất kỳ để thoát..." -ForegroundColor $INFO_COLOR
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
