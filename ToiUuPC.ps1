# ToiUuPC.ps1 - Công cụ tối ưu Windows PMK
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Thuthuatwiki (PMK)

#region Khởi tạo và kiểm tra
Clear-Host

# Kiểm tra và yêu cầu quyền Admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Logo PMK
$logo = @"
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║   ██████╗ ███╗   ███╗██╗  ██╗      ████████╗ ██████╗  ██████╗ ██╗       ║
║   ██╔══██╗████╗ ████║██║ ██╔╝      ╚══██╔══╝██╔═══██╗██╔═══██╗██║       ║
║   ██████╔╝██╔████╔██║█████╔╝ █████╗   ██║   ██║   ██║██║   ██║██║       ║
║   ██╔═══╝ ██║╚██╔╝██║██╔═██╗ ╚════╝   ██║   ██║   ██║██║   ██║██║       ║
║   ██║     ██║ ╚═╝ ██║██║  ██╗         ██║   ╚██████╔╝╚██████╔╝███████╗  ║
║   ╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝         ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝  ║
║                                                                          ║
║                        PMK Toolbox - Tối ưu Windows                      ║
║                    Phiên bản: 2.0 | Hỗ trợ: Windows 10/11                ║
╚══════════════════════════════════════════════════════════════════════════╝
"@

Write-Host $logo -ForegroundColor Cyan
Write-Host "`nĐang tải PMK Toolbox..." -ForegroundColor Yellow

# Kiểm tra và cài đặt các module cần thiết
function Install-RequiredModules {
    $modules = @("BurntToast")
    foreach ($module in $modules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Host "Cài đặt module $module..." -ForegroundColor Yellow
            Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
        }
    }
}

# Kiểm tra winget
function Test-Winget {
    try {
        $wingetCheck = winget --version
        return $true
    } catch {
        Write-Host "Winget không được cài đặt. Đang cố gắng cài đặt..." -ForegroundColor Red
        
        # Tự động cài winget từ Microsoft Store
        $wingetUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $installerPath = "$env:TEMP\winget.msixbundle"
        
        try {
            Invoke-WebRequest -Uri $wingetUrl -OutFile $installerPath
            Add-AppxPackage -Path $installerPath
            Remove-Item $installerPath
            Write-Host "Đã cài đặt Winget thành công!" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "Không thể tự động cài Winget. Vui lòng cài đặt thủ công từ Microsoft Store." -ForegroundColor Red
            return $false
        }
    }
}

#region Load WPF Assemblies
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
#endregion

#region Dữ liệu ứng dụng
$Apps = @{
    "🌐 Trình duyệt" = @(
        @{Name="Brave"; Winget="Brave.Brave"; Icon="🚀"}
        @{Name="Google Chrome"; Winget="Google.Chrome"; Icon="🔍"}
        @{Name="Firefox"; Winget="Mozilla.Firefox"; Icon="🦊"}
        @{Name="Microsoft Edge"; Winget="Microsoft.Edge"; Icon="⚡"}
        @{Name="Opera"; Winget="Opera.Opera"; Icon="🎭"}
        @{Name="Vivaldi"; Winget="Vivaldi.Vivaldi"; Icon="🎵"}
    )
    "💬 Giao tiếp" = @(
        @{Name="Discord"; Winget="Discord.Discord"; Icon="🎮"}
        @{Name="Telegram"; Winget="Telegram.TelegramDesktop"; Icon="✈️"}
        @{Name="Zoom"; Winget="Zoom.Zoom"; Icon="📹"}
        @{Name="Skype"; Winget="Microsoft.Skype"; Icon="💼"}
        @{Name="WhatsApp"; Winget="WhatsApp.WhatsApp"; Icon="💚"}
    )
    "🛠️ Công cụ phát triển" = @(
        @{Name="Visual Studio Code"; Winget="Microsoft.VisualStudioCode"; Icon="📝"}
        @{Name="Git"; Winget="Git.Git"; Icon="🌿"}
        @{Name="Python 3"; Winget="Python.Python.3.12"; Icon="🐍"}
        @{Name="Node.js"; Winget="OpenJS.NodeJS"; Icon="⬢"}
        @{Name="Docker Desktop"; Winget="Docker.DockerDesktop"; Icon="🐳"}
        @{Name="Postman"; Winget="Postman.Postman"; Icon="📮"}
    )
    "🎨 Đa phương tiện" = @(
        @{Name="VLC"; Winget="VideoLAN.VLC"; Icon="🎬"}
        @{Name="Spotify"; Winget="Spotify.Spotify"; Icon="🎵"}
        @{Name="GIMP"; Winget="GIMP.GIMP"; Icon="🖼️"}
        @{Name="OBS Studio"; Winget="OBSProject.OBSStudio"; Icon="🎥"}
        @{Name="Audacity"; Winget="Audacity.Audacity"; Icon="🎤"}
    )
    "📦 Tiện ích hệ thống" = @(
        @{Name="7-Zip"; Winget="7zip.7zip"; Icon="🗜️"}
        @{Name="WinRAR"; Winget="RARLab.WinRAR"; Icon="📦"}
        @{Name="CCleaner"; Winget="Piriform.CCleaner"; Icon="🧹"}
        @{Name="Everything"; Winget="voidtools.Everything"; Icon="🔎"}
        @{Name="Notepad++"; Winget="Notepad++.Notepad++"; Icon="📄"}
    )
}

#region Tweak Registry Functions
function Set-RegistryTweak {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord",
        [switch]$CreatePath
    )
    
    try {
        if ($CreatePath -and -not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        
        if (Test-Path $Path) {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
            return $true
        }
        return $false
    } catch {
        Write-Warning "Lỗi khi thiết lập registry: $_"
        return $false
    }
}

function Remove-WindowsApp {
    param([string]$Pattern)
    
    try {
        Get-AppxPackage -AllUsers | Where-Object {$_.Name -like $Pattern} | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like $Pattern} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        return $true
    } catch {
        Write-Warning "Lỗi khi xóa app: $_"
        return $false
    }
}
#endregion

#region Danh sách Tweak
$Tweaks = @{
    "🔧 Tối ưu hiệu suất" = @(
        @{Name="Tạo điểm khôi phục hệ thống"; Action={
            try {
                if ((Get-ComputerRestorePoint).Count -eq 0) {
                    Enable-ComputerRestore -Drive "C:\"
                }
                Checkpoint-Computer -Description "PMK Toolbox - $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -RestorePointType MODIFY_SETTINGS
                return "✅ Đã tạo điểm khôi phục"
            } catch { return "❌ Lỗi: $_" }
        }}
        @{Name="Xóa file tạm"; Action={
            try {
                Get-ChildItem -Path "$env:TEMP", "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                Cleanmgr /sagerun:1 | Out-Null
                return "✅ Đã xóa file tạm"
            } catch { return "❌ Lỗi: $_" }
        }}
        @{Name="Vô hiệu hóa Telemetry"; Action={
            $results = @()
            $results += if (Set-RegistryTweak -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -CreatePath) {"✅"} else {"❌"}
            $results += if (Set-RegistryTweak -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "AITEnable" -Value 0 -CreatePath) {"✅"} else {"❌"}
            $results += if (Set-RegistryTweak -Path "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Value 0 -CreatePath) {"✅"} else {"❌"}
            return "Telemetry: $($results -join ' | ')"
        }}
        @{Name="Tắt dịch vụ không cần thiết"; Action={
            $services = @("DiagTrack", "dmwappushservice", "WMPNetworkSvc", "RemoteRegistry", "Fax")
            $results = @()
            foreach ($service in $services) {
                try {
                    Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
                    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                    $results += "✅"
                } catch { $results += "❌" }
            }
            return "Dịch vụ: $($results -join ' | ')"
        }}
        @{Name="Tối ưu hóa điện năng"; Action={
            try {
                powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
                powercfg -h off
                return "✅ Đã áp dụng chế độ hiệu suất cao"
            } catch { return "❌ Lỗi: $_" }
        }}
    )
    
    "🛡️ Bảo mật & Riêng tư" = @(
        @{Name="Tắt Cortana"; Action={
            $results = @()
            $results += if (Set-RegistryTweak -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -CreatePath) {"✅"} else {"❌"}
            $results += if (Set-RegistryTweak -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowSearchToUseLocation" -Value 0 -CreatePath) {"✅"} else {"❌"}
            return "Cortana: $($results -join ' | ')"
        }}
        @{Name="Vô hiệu hóa quảng cáo"; Action={
            $results = @()
            $results += if (Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -CreatePath) {"✅"} else {"❌"}
            $results += if (Set-RegistryTweak -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Value 1 -CreatePath) {"✅"} else {"❌"}
            return "Quảng cáo: $($results -join ' | ')"
        }}
        @{Name="Tắt theo dõi vị trí"; Action={
            $results = @()
            $results += if (Set-RegistryTweak -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -CreatePath) {"✅"} else {"❌"}
            $results += if (Set-RegistryTweak -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Value 0 -CreatePath) {"✅"} else {"❌"}
            return "Vị trí: $($results -join ' | ')"
        }}
        @{Name="Tắt Windows Defender (Không khuyến khích)"; Action={
            $results = @()
            $results += if (Set-RegistryTweak -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -CreatePath) {"✅"} else {"❌"}
            return "Defender: $($results -join ' | ')"
        }}
    )
    
    "🎨 Tùy chỉnh giao diện" = @(
        @{Name="Chế độ tối (Dark Mode)"; Action={
            $results = @()
            $results += if (Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0) {"✅"} else {"❌"}
            $results += if (Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0) {"✅"} else {"❌"}
            return "Dark Mode: $($results -join ' | ')"
        }}
        @{Name="Hiển thị file ẩn và phần mở rộng"; Action={
            $results = @()
            $results += if (Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1) {"✅"} else {"❌"}
            $results += if (Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0) {"✅"} else {"❌"}
            $results += if (Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Value 1) {"✅"} else {"❌"}
            return "File Explorer: $($results -join ' | ')"
        }}
        @{Name="Tắt hiệu ứng trong suốt"; Action={
            return if (Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0) {
                "✅ Đã tắt hiệu ứng trong suốt"
            } else {
                "❌ Lỗi khi tắt hiệu ứng"
            }
        }}
        @{Name="Thay đổi hình nền (Màu đen)"; Action={
            try {
                $code = @'
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    public static void SetWallpaper(string path) {
        SystemParametersInfo(20, 0, path, 0x01 | 0x02);
    }
}
'@
                Add-Type -TypeDefinition $code
                $blackWallpaper = "$env:TEMP\black.bmp"
                [byte[]]$blackBmp = @(0x42,0x4D,0x36,0x00,0x0C,0x00,0x00,0x00,0x00,0x00,0x36,0x00,0x00,0x00,0x28,0x00,
                                      0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x18,0x00,0x00,0x00,
                                      0x00,0x00,0x00,0x00,0x0C,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                      0x00,0x00,0x00,0x00,0x00,0x00)
                [System.IO.File]::WriteAllBytes($blackWallpaper, $blackBmp)
                [Wallpaper]::SetWallpaper($blackWallpaper)
                return "✅ Đã đổi hình nền màu đen"
            } catch { return "❌ Lỗi: $_" }
        }}
    )
    
    "🧹 Dọn dẹp Windows" = @(
        @{Name="Xóa OneDrive"; Action={
            try {
                if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
                    Start-Process -FilePath "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
                }
                if (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") {
                    Start-Process -FilePath "$env:SystemRoot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
                }
                Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force
                return "✅ Đã xóa OneDrive"
            } catch { return "❌ Lỗi: $_" }
        }}
        @{Name="Xóa Windows Bloatware"; Action={
            $bloatApps = @(
                "*3DBuilder*", "*Bing*", "*Clipchamp*", "*CommunicationsApps*",
                "*Cortana*", "*FeedbackHub*", "*GetHelp*", "*GetStarted*",
                "*MicrosoftSolitaireCollection*", "*MixedReality*", "*Office*",
                "*OneConnect*", "*People*", "*PowerAutomate*", "*Skype*",
                "*SoundRecorder*", "*StickyNotes*", "*Tips*", "*Wallet*",
                "*WebExperiences*", "*WindowsAlarms*", "*WindowsCamera*",
                "*WindowsMaps*", "*WindowsSoundRecorder*", "*Xbox*"
            )
            $results = @()
            foreach ($app in $bloatApps) {
                $results += if (Remove-WindowsApp -Pattern $app) {"✅"} else {"➖"}
            }
            return "Bloatware: $($results -join '')"
        }}
        @{Name="Tắt Windows Tips"; Action={
            return if (Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338393Enabled" -Value 0) {
                "✅ Đã tắt Windows Tips"
            } else {
                "❌ Lỗi khi tắt Tips"
            }
        }}
    )
    
    "⚡ Tweak nâng cao" = @(
        @{Name="Tắt Game Bar & DVR"; Action={
            $results = @()
            $results += if (Set-RegistryTweak -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0) {"✅"} else {"❌"}
            $results += if (Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0) {"✅"} else {"❌"}
            return "Game Bar: $($results -join ' | ')"
        }}
        @{Name="Tối ưu hóa mạng"; Action={
            try {
                Set-NetTCPSetting -CongestionProvider DCTCP -ErrorAction SilentlyContinue
                Set-NetTCPSetting -AutoTuningLevelLocal Normal -ErrorAction SilentlyContinue
                return "✅ Đã tối ưu cài đặt TCP"
            } catch { return "❌ Lỗi: $_" }
        }}
        @{Name="Tắt Notifications"; Action={
            return if (Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0) {
                "✅ Đã tắt thông báo"
            } else {
                "❌ Lỗi khi tắt thông báo"
            }
        }}
        @{Name="Bật NumLock khi khởi động"; Action={
            $results = @()
            $results += if (Set-RegistryTweak -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Value 2) {"✅"} else {"❌"}
            $results += if (Set-RegistryTweak -Path "HKCU:\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Value 2) {"✅"} else {"❌"}
            return "NumLock: $($results -join ' | ')"
        }}
    )
}
#endregion

#region Tạo GUI WPF
function Create-MainWindow {
    # Tạo cửa sổ chính
    $Window = New-Object Windows.Window
    $Window.Title = "PMK Toolbox - Tối ưu Windows"
    $Window.Width = 1200
    $Window.Height = 750
    $Window.WindowStartupLocation = "CenterScreen"
    $Window.Background = [System.Windows.Media.Brushes]::White
    $Window.FontFamily = "Segoe UI"
    
    # Grid chính
    $MainGrid = New-Object Windows.Controls.Grid
    $MainGrid.Background = [System.Windows.Media.LinearGradientBrush]::new(
        [System.Windows.Media.Color]::FromRgb(240, 244, 255),
        [System.Windows.Media.Color]::FromRgb(220, 230, 255),
        0
    )
    
    # Header
    $HeaderGrid = New-Object Windows.Controls.Grid
    $HeaderGrid.Height = 80
    $HeaderGrid.Background = [System.Windows.Media.LinearGradientBrush]::new(
        [System.Windows.Media.Color]::FromRgb(70, 130, 180),
        [System.Windows.Media.Color]::FromRgb(30, 144, 255),
        90
    )
    
    $HeaderText = New-Object Windows.Controls.TextBlock
    $HeaderText.Text = "PMK TOOLBOX - TỐI ƯU WINDOWS"
    $HeaderText.FontSize = 28
    $HeaderText.FontWeight = "Bold"
    $HeaderText.Foreground = [System.Windows.Media.Brushes]::White
    $HeaderText.VerticalAlignment = "Center"
    $HeaderText.HorizontalAlignment = "Center"
    $HeaderText.Margin = "0,0,0,10"
    
    $VersionText = New-Object Windows.Controls.TextBlock
    $VersionText.Text = "v2.0 | Windows 10/11 | By PMK"
    $VersionText.FontSize = 12
    $VersionText.Foreground = [System.Windows.Media.Brushes]::LightGray
    $VersionText.VerticalAlignment = "Bottom"
    $VersionText.HorizontalAlignment = "Center"
    $VersionText.Margin = "0,0,0,10"
    
    $HeaderGrid.Children.Add($HeaderText) | Out-Null
    $HeaderGrid.Children.Add($VersionText) | Out-Null
    
    # Tab Control
    $TabControl = New-Object Windows.Controls.TabControl
    $TabControl.Margin = "10"
    $TabControl.BorderThickness = "1"
    $TabControl.BorderBrush = [System.Windows.Media.Brushes]::LightGray
    
    # Tab 1: Cài đặt ứng dụng
    $TabInstall = New-Object Windows.Controls.TabItem
    $TabInstall.Header = "📦 CÀI ĐẶT ỨNG DỤNG"
    $TabInstall.FontWeight = "Bold"
    
    $InstallScroll = New-Object Windows.Controls.ScrollViewer
    $InstallScroll.VerticalScrollBarVisibility = "Auto"
    
    $InstallStack = New-Object Windows.Controls.StackPanel
    $InstallStack.Margin = "10"
    
    # Thêm từng danh mục ứng dụng
    foreach ($category in $Apps.Keys) {
        $CategoryBorder = New-Object Windows.Controls.Border
        $CategoryBorder.BorderThickness = "1"
        $CategoryBorder.BorderBrush = [System.Windows.Media.Brushes]::LightGray
        $CategoryBorder.CornerRadius = "5"
        $CategoryBorder.Margin = "0,0,0,10"
        $CategoryBorder.Background = [System.Windows.Media.Brushes]::White
        
        $CategoryStack = New-Object Windows.Controls.StackPanel
        
        # Tiêu đề danh mục
        $CategoryHeader = New-Object Windows.Controls.TextBlock
        $CategoryHeader.Text = $category
        $CategoryHeader.FontSize = 18
        $CategoryHeader.FontWeight = "Bold"
        $CategoryHeader.Margin = "10,10,10,5"
        $CategoryHeader.Foreground = [System.Windows.Media.Brushes]::DarkSlateBlue
        
        $CategoryStack.Children.Add($CategoryHeader) | Out-Null
        
        # Grid cho các ứng dụng
        $AppGrid = New-Object Windows.Controls.WrapPanel
        $AppGrid.Margin = "10"
        $AppGrid.HorizontalAlignment = "Left"
        
        foreach ($app in $Apps[$category]) {
            $AppBorder = New-Object Windows.Controls.Border
            $AppBorder.Width = 180
            $AppBorder.Height = 60
            $AppBorder.Margin = "5"
            $AppBorder.BorderThickness = "1"
            $AppBorder.BorderBrush = [System.Windows.Media.Brushes]::LightGray
            $AppBorder.CornerRadius = "5"
            $AppBorder.Background = [System.Windows.Media.Brushes]::WhiteSmoke
            $AppBorder.Tag = $app.Winget
            
            $AppStack = New-Object Windows.Controls.StackPanel
            $AppStack.Orientation = "Horizontal"
            $AppStack.Margin = "10"
            
            $AppIcon = New-Object Windows.Controls.TextBlock
            $AppIcon.Text = $app.Icon
            $AppIcon.FontSize = 20
            $AppIcon.Margin = "0,0,10,0"
            
            $AppText = New-Object Windows.Controls.TextBlock
            $AppText.Text = $app.Name
            $AppText.FontSize = 14
            $AppText.VerticalAlignment = "Center"
            $AppText.TextWrapping = "Wrap"
            
            $AppStack.Children.Add($AppIcon) | Out-Null
            $AppStack.Children.Add($AppText) | Out-Null
            $AppBorder.Child = $AppStack
            
            # Thêm sự kiện click
            $AppBorder.Add_MouseLeftButtonDown({
                $border = $_.Source
                if ($border.Background -eq [System.Windows.Media.Brushes]::WhiteSmoke) {
                    $border.Background = [System.Windows.Media.Brushes]::LightGreen
                } else {
                    $border.Background = [System.Windows.Media.Brushes]::WhiteSmoke
                }
            })
            
            $AppGrid.Children.Add($AppBorder) | Out-Null
        }
        
        $CategoryStack.Children.Add($AppGrid) | Out-Null
        $CategoryBorder.Child = $CategoryStack
        $InstallStack.Children.Add($CategoryBorder) | Out-Null
    }
    
    # Nút cài đặt
    $InstallButton = New-Object Windows.Controls.Button
    $InstallButton.Content = "🚀 CÀI ĐẶT ỨNG DỤNG ĐÃ CHỌN"
    $InstallButton.FontSize = 16
    $InstallButton.FontWeight = "Bold"
    $InstallButton.Height = 50
    $InstallButton.Margin = "10"
    $InstallButton.Background = [System.Windows.Media.LinearGradientBrush]::new(
        [System.Windows.Media.Color]::FromRgb(46, 204, 113),
        [System.Windows.Media.Color]::FromRgb(39, 174, 96),
        90
    )
    $InstallButton.Foreground = [System.Windows.Media.Brushes]::White
    $InstallButton.Cursor = "Hand"
    
    $InstallButton.Add_Click({
        $selectedApps = @()
        foreach ($border in $InstallStack.Children | Where-Object {$_ -is [Windows.Controls.Border]}) {
            foreach ($child in (($border.Child as [Windows.Controls.StackPanel]).Children[1] as [Windows.Controls.WrapPanel]).Children) {
                if (($child.Background -eq [System.Windows.Media.Brushes]::LightGreen) -or 
                    ($child.Background.ToString() -eq "#FF90EE90")) {
                    $selectedApps += $child.Tag
                }
            }
        }
        
        if ($selectedApps.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Vui lòng chọn ít nhất một ứng dụng!", "Thông báo", "OK", "Information")
            return
        }
        
        $result = [System.Windows.MessageBox]::Show(
            "Bạn muốn cài đặt $($selectedApps.Count) ứng dụng?`n`n$($selectedApps -join "`n")",
            "Xác nhận cài đặt",
            "YesNo",
            "Question"
        )
        
        if ($result -eq "Yes") {
            $InstallButton.IsEnabled = $false
            $InstallButton.Content = "⏳ ĐANG CÀI ĐẶT..."
            
            $progress = 0
            $total = $selectedApps.Count
            
            foreach ($appId in $selectedApps) {
                $progress++
                $percentage = [math]::Round(($progress / $total) * 100)
                $InstallButton.Content = "⏳ ĐANG CÀI ĐẶT... $percentage%"
                
                try {
                    winget install --id $appId --accept-package-agreements --accept-source-agreements --silent
                    Write-Host "✅ Đã cài đặt: $appId" -ForegroundColor Green
                } catch {
                    Write-Host "❌ Lỗi khi cài $appId: $_" -ForegroundColor Red
                }
            }
            
            $InstallButton.Content = "✅ HOÀN TẤT CÀI ĐẶT!"
            $InstallButton.Background = [System.Windows.Media.Brushes]::Green
            [System.Windows.MessageBox]::Show("Đã cài đặt xong $total ứng dụng!", "Thành công", "OK", "Information")
            
            # Reset button sau 3 giây
            Start-Sleep -Seconds 3
            $InstallButton.Content = "🚀 CÀI ĐẶT ỨNG DỤNG ĐÃ CHỌN"
            $InstallButton.Background = [System.Windows.Media.LinearGradientBrush]::new(
                [System.Windows.Media.Color]::FromRgb(46, 204, 113),
                [System.Windows.Media.Color]::FromRgb(39, 174, 96),
                90
            )
            $InstallButton.IsEnabled = $true
        }
    })
    
    $InstallStack.Children.Add($InstallButton) | Out-Null
    $InstallScroll.Content = $InstallStack
    $TabInstall.Content = $InstallScroll
    $TabControl.Items.Add($TabInstall) | Out-Null
    
    # Tab 2: Tweak hệ thống
    $TabTweaks = New-Object Windows.Controls.TabItem
    $TabTweaks.Header = "⚙️ TỐI ƯU HỆ THỐNG"
    $TabTweaks.FontWeight = "Bold"
    
    $TweakScroll = New-Object Windows.Controls.ScrollViewer
    $TweakScroll.VerticalScrollBarVisibility = "Auto"
    
    $TweakStack = New-Object Windows.Controls.StackPanel
    $TweakStack.Margin = "10"
    
    # Tạo các nhóm tweak
    foreach ($category in $Tweaks.Keys) {
        $CategoryBorder = New-Object Windows.Controls.Border
        $CategoryBorder.BorderThickness = "1"
        $CategoryBorder.BorderBrush = [System.Windows.Media.Brushes]::LightGray
        $CategoryBorder.CornerRadius = "5"
        $CategoryBorder.Margin = "0,0,0,15"
        $CategoryBorder.Background = [System.Windows.Media.Brushes]::White
        
        $CategoryStack = New-Object Windows.Controls.StackPanel
        
        # Tiêu đề danh mục tweak
        $CategoryHeader = New-Object Windows.Controls.TextBlock
        $CategoryHeader.Text = $category
        $CategoryHeader.FontSize = 18
        $CategoryHeader.FontWeight = "Bold"
        $CategoryHeader.Margin = "10,10,10,5"
        $CategoryHeader.Foreground = [System.Windows.Media.Brushes]::DarkSlateBlue
        
        $CategoryStack.Children.Add($CategoryHeader) | Out-Null
        
        # Tạo checkbox cho từng tweak
        foreach ($tweak in $Tweaks[$category]) {
            $CheckBox = New-Object Windows.Controls.CheckBox
            $CheckBox.Content = $tweak.Name
            $CheckBox.FontSize = 14
            $CheckBox.Margin = "20,5,10,5"
            $CheckBox.Tag = $tweak.Action
            $CheckBox.IsChecked = $false
            
            $CategoryStack.Children.Add($CheckBox) | Out-Null
        }
        
        $CategoryBorder.Child = $CategoryStack
        $TweakStack.Children.Add($CategoryBorder) | Out-Null
    }
    
    # Nút thực thi tweaks
    $ExecuteTweaksButton = New-Object Windows.Controls.Button
    $ExecuteTweaksButton.Content = "⚡ ÁP DỤNG TWEAKS ĐÃ CHỌN"
    $ExecuteTweaksButton.FontSize = 16
    $ExecuteTweaksButton.FontWeight = "Bold"
    $ExecuteTweaksButton.Height = 50
    $ExecuteTweaksButton.Margin = "10"
    $ExecuteTweaksButton.Background = [System.Windows.Media.LinearGradientBrush]::new(
        [System.Windows.Media.Color]::FromRgb(52, 152, 219),
        [System.Windows.Media.Color]::FromRgb(41, 128, 185),
        90
    )
    $ExecuteTweaksButton.Foreground = [System.Windows.Media.Brushes]::White
    $ExecuteTweaksButton.Cursor = "Hand"
    
    $ExecuteTweaksButton.Add_Click({
        $selectedTweaks = @()
        foreach ($border in $TweakStack.Children | Where-Object {$_ -is [Windows.Controls.Border]}) {
            foreach ($checkbox in (($border.Child as [Windows.Controls.StackPanel]).Children | Where-Object {$_ -is [Windows.Controls.CheckBox]})) {
                if ($checkbox.IsChecked -eq $true) {
                    $selectedTweaks += @{
                        Name = $checkbox.Content
                        Action = $checkbox.Tag
                    }
                }
            }
        }
        
        if ($selectedTweaks.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Vui lòng chọn ít nhất một tweak!", "Thông báo", "OK", "Information")
            return
        }
        
        $result = [System.Windows.MessageBox]::Show(
            "Bạn có chắc muốn áp dụng $($selectedTweaks.Count) tweak?`n`nHệ thống sẽ được tối ưu theo lựa chọn của bạn.",
            "Xác nhận áp dụng tweak",
            "YesNo",
            "Warning"
        )
        
        if ($result -eq "Yes") {
            $ExecuteTweaksButton.IsEnabled = $false
            $ExecuteTweaksButton.Content = "⏳ ĐANG ÁP DỤNG..."
            
            $results = @()
            $progress = 0
            $total = $selectedTweaks.Count
            
            foreach ($tweak in $selectedTweaks) {
                $progress++
                $percentage = [math]::Round(($progress / $total) * 100)
                $ExecuteTweaksButton.Content = "⏳ ĐANG ÁP DỤNG... $percentage%"
                
                Write-Host "`n[$progress/$total] $($tweak.Name)..." -ForegroundColor Yellow
                
                try {
                    $result = & $tweak.Action
                    $results += "✅ $($tweak.Name): $result"
                    Write-Host "   $result" -ForegroundColor Green
                } catch {
                    $results += "❌ $($tweak.Name): Lỗi - $_"
                    Write-Host "   ❌ Lỗi: $_" -ForegroundColor Red
                }
            }
            
            # Hiển thị kết quả
            $resultWindow = New-Object Windows.Window
            $resultWindow.Title = "Kết quả áp dụng tweak"
            $resultWindow.Width = 600
            $resultWindow.Height = 400
            $resultWindow.WindowStartupLocation = "CenterScreen"
            
            $resultTextBox = New-Object Windows.Controls.TextBox
            $resultTextBox.Text = "KẾT QUẢ ÁP DỤNG TWEAK:`n`n" + ($results -join "`n")
            $resultTextBox.FontFamily = "Consolas"
            $resultTextBox.FontSize = 12
            $resultTextBox.IsReadOnly = $true
            $resultTextBox.VerticalScrollBarVisibility = "Auto"
            $resultTextBox.HorizontalScrollBarVisibility = "Auto"
            $resultTextBox.TextWrapping = "Wrap"
            
            $resultWindow.Content = $resultTextBox
            $resultWindow.ShowDialog() | Out-Null
            
            $ExecuteTweaksButton.Content = "✅ HOÀN TẤT!"
            $ExecuteTweaksButton.Background = [System.Windows.Media.Brushes]::Green
            
            # Reset button sau 3 giây
            Start-Sleep -Seconds 3
            $ExecuteTweaksButton.Content = "⚡ ÁP DỤNG TWEAKS ĐÃ CHỌN"
            $ExecuteTweaksButton.Background = [System.Windows.Media.LinearGradientBrush]::new(
                [System.Windows.Media.Color]::FromRgb(52, 152, 219),
                [System.Windows.Media.Color]::FromRgb(41, 128, 185),
                90
            )
            $ExecuteTweaksButton.IsEnabled = $true
        }
    })
    
    $TweakStack.Children.Add($ExecuteTweaksButton) | Out-Null
    $TweakScroll.Content = $TweakStack
    $TabTweaks.Content = $TweakScroll
    $TabControl.Items.Add($TabTweaks) | Out-Null
    
    # Tab 3: Thông tin hệ thống
    $TabInfo = New-Object Windows.Controls.TabItem
    $TabInfo.Header = "💻 THÔNG TIN HỆ THỐNG"
    $TabInfo.FontWeight = "Bold"
    
    $InfoStack = New-Object Windows.Controls.StackPanel
    $InfoStack.Margin = "20"
    
    # Lấy thông tin hệ thống
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor
    $ram = Get-CimInstance -ClassName Win32_ComputerSystem
    $gpu = Get-CimInstance -ClassName Win32_VideoController
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    
    $systemInfo = @"
══════════════════════════════════════════════════════════════════════
                  THÔNG TIN HỆ THỐNG

📊 Hệ điều hành:
   • Tên: $($os.Caption)
   • Phiên bản: $($os.Version)
   • Build: $($os.BuildNumber)
   • Architecture: $($os.OSArchitecture)

⚡ CPU:
   • Model: $($cpu.Name)
   • Số nhân: $($cpu.NumberOfCores)
   • Luồng: $($cpu.NumberOfLogicalProcessors)
   • Tốc độ: $([math]::Round($cpu.MaxClockSpeed / 1000, 2)) GHz

💾 RAM:
   • Tổng: $([math]::Round($ram.TotalPhysicalMemory / 1GB, 2)) GB
   • Sử dụng: $([math]::Round(($ram.TotalPhysicalMemory - $os.FreePhysicalMemory) / 1GB, 2)) GB
   • Còn trống: $([math]::Round($os.FreePhysicalMemory / 1GB, 2)) GB

🎮 GPU:
   • Card màn hình: $($gpu.Name)
   • Bộ nhớ: $([math]::Round($gpu.AdapterRAM / 1GB, 2)) GB
   • Độ phân giải: $($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)

💿 Ổ đĩa (C:):
   • Tổng dung lượng: $([math]::Round($disk.Size / 1GB, 2)) GB
   • Đã sử dụng: $([math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)) GB
   • Còn trống: $([math]::Round($disk.FreeSpace / 1GB, 2)) GB

══════════════════════════════════════════════════════════════════════
"@
    
    $InfoText = New-Object Windows.Controls.TextBox
    $InfoText.Text = $systemInfo
    $InfoText.FontFamily = "Consolas"
    $InfoText.FontSize = 12
    $InfoText.IsReadOnly = $true
    $InfoText.VerticalScrollBarVisibility = "Auto"
    $InfoText.TextWrapping = "Wrap"
    $InfoText.Height = 500
    
    # Nút refresh thông tin
    $RefreshButton = New-Object Windows.Controls.Button
    $RefreshButton.Content = "🔄 LÀM MỚI THÔNG TIN"
    $RefreshButton.FontSize = 14
    $RefreshButton.FontWeight = "Bold"
    $RefreshButton.Margin = "0,10,0,0"
    $RefreshButton.Width = 200
    $RefreshButton.Height = 40
    $RefreshButton.Background = [System.Windows.Media.Brushes]::LightBlue
    
    $RefreshButton.Add_Click({
        $InfoText.Text = "Đang cập nhật thông tin hệ thống..."
        Start-Sleep -Seconds 1
        # Tái tạo thông tin hệ thống
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $cpu = Get-CimInstance -ClassName Win32_Processor
        $ram = Get-CimInstance -ClassName Win32_ComputerSystem
        $gpu = Get-CimInstance -ClassName Win32_VideoController
        $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
        
        $systemInfo = @"
══════════════════════════════════════════════════════════════════════
                  THÔNG TIN HỆ THỐNG (Cập nhật: $(Get-Date -Format 'HH:mm:ss'))

📊 Hệ điều hành:
   • Tên: $($os.Caption)
   • Phiên bản: $($os.Version)
   • Build: $($os.BuildNumber)
   • Architecture: $($os.OSArchitecture)

⚡ CPU:
   • Model: $($cpu.Name)
   • Số nhân: $($cpu.NumberOfCores)
   • Luồng: $($cpu.NumberOfLogicalProcessors)
   • Tốc độ: $([math]::Round($cpu.MaxClockSpeed / 1000, 2)) GHz

💾 RAM:
   • Tổng: $([math]::Round($ram.TotalPhysicalMemory / 1GB, 2)) GB
   • Sử dụng: $([math]::Round(($ram.TotalPhysicalMemory - $os.FreePhysicalMemory) / 1GB, 2)) GB
   • Còn trống: $([math]::Round($os.FreePhysicalMemory / 1GB, 2)) GB

🎮 GPU:
   • Card màn hình: $($gpu.Name)
   • Bộ nhớ: $([math]::Round($gpu.AdapterRAM / 1GB, 2)) GB
   • Độ phân giải: $($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)

💿 Ổ đĩa (C:):
   • Tổng dung lượng: $([math]::Round($disk.Size / 1GB, 2)) GB
   • Đã sử dụng: $([math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)) GB
   • Còn trống: $([math]::Round($disk.FreeSpace / 1GB, 2)) GB

══════════════════════════════════════════════════════════════════════
"@
        $InfoText.Text = $systemInfo
    })
    
    $InfoStack.Children.Add($InfoText) | Out-Null
    $InfoStack.Children.Add($RefreshButton) | Out-Null
    $TabInfo.Content = $InfoStack
    $TabControl.Items.Add($TabInfo) | Out-Null
    
    # Footer với các nút chức năng
    $FooterGrid = New-Object Windows.Controls.Grid
    $FooterGrid.Height = 60
    $FooterGrid.Background = [System.Windows.Media.Brushes]::LightGray
    
    $ButtonPanel = New-Object Windows.Controls.StackPanel
    $ButtonPanel.Orientation = "Horizontal"
    $ButtonPanel.HorizontalAlignment = "Center"
    $ButtonPanel.VerticalAlignment = "Center"
    
    # Nút khởi động lại
    $RestartButton = New-Object Windows.Controls.Button
    $RestartButton.Content = "🔄 KHỞI ĐỘNG LẠI"
    $RestartButton.Width = 150
    $RestartButton.Height = 40
    $RestartButton.Margin = "10"
    $RestartButton.Background = [System.Windows.Media.Brushes]::Orange
    $RestartButton.Foreground = [System.Windows.Media.Brushes]::White
    $RestartButton.FontWeight = "Bold"
    
    $RestartButton.Add_Click({
        $result = [System.Windows.MessageBox]::Show("Bạn có muốn khởi động lại máy tính ngay bây giờ?", "Xác nhận", "YesNo", "Question")
        if ($result -eq "Yes") {
            Restart-Computer -Force
        }
    })
    
    # Nút thoát
    $ExitButton = New-Object Windows.Controls.Button
    $ExitButton.Content = "❌ THOÁT"
    $ExitButton.Width = 150
    $ExitButton.Height = 40
    $ExitButton.Margin = "10"
    $ExitButton.Background = [System.Windows.Media.Brushes]::Red
    $ExitButton.Foreground = [System.Windows.Media.Brushes]::White
    $ExitButton.FontWeight = "Bold"
    
    $ExitButton.Add_Click({
        $Window.Close()
    })
    
    $ButtonPanel.Children.Add($RestartButton) | Out-Null
    $ButtonPanel.Children.Add($ExitButton) | Out-Null
    $FooterGrid.Children.Add($ButtonPanel) | Out-Null
    
    # Xây dựng layout chính
    $MainGrid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height = "Auto"}))
    $MainGrid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition))
    $MainGrid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height = "Auto"}))
    
    [Windows.Controls.Grid]::SetRow($HeaderGrid, 0)
    [Windows.Controls.Grid]::SetRow($TabControl, 1)
    [Windows.Controls.Grid]::SetRow($FooterGrid, 2)
    
    $MainGrid.Children.Add($HeaderGrid) | Out-Null
    $MainGrid.Children.Add($TabControl) | Out-Null
    $MainGrid.Children.Add($FooterGrid) | Out-Null
    
    $Window.Content = $MainGrid
    return $Window
}
#endregion

#region Main Execution
Write-Host "`nĐang khởi tạo PMK Toolbox..." -ForegroundColor Yellow

# Kiểm tra winget
if (-not (Test-Winget)) {
    Write-Host "Cảnh báo: Winget không được cài đặt. Tính năng cài đặt ứng dụng có thể không hoạt động." -ForegroundColor Yellow
}

# Cài đặt module cần thiết
try {
    Install-RequiredModules
} catch {
    Write-Host "Lỗi khi cài đặt module: $_" -ForegroundColor Red
}

# Hiển thị GUI
try {
    $mainWindow = Create-MainWindow
    $null = $mainWindow.ShowDialog()
} catch {
    Write-Host "Lỗi khi tạo giao diện: $_" -ForegroundColor Red
    Write-Host "Vui lòng kiểm tra và chạy lại script." -ForegroundColor Yellow
    Pause
}
#endregion
