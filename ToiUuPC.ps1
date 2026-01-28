# ToiUuPC.ps1 - Công cụ tối ưu Windows PMK
# Run: irm bit.ly/pmktool | iex
# Author: Thuthuatwiki (PMK)
# Version: 2.3 - Optimized performance, fixed UI lag, added DNS management and WinUtil tweaks

Clear-Host

#region Khởi tạo với hiệu suất cao
# Kiểm tra quyền Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Disable progress bars for better performance
$ProgressPreference = 'SilentlyContinue'

# Logo PMK
$logo = @"
╔══════════════════════════════════════════════════════════════════════════╗
║   ██████╗ ███╗   ███╗██╗  ██╗      ████████╗ ██████╗  ██████╗ ██╗       ║
║   ██╔══██╗████╗ ████║██║ ██╔╝      ╚══██╔══╝██╔═══██╗██╔═══██╗██║       ║
║   ██████╔╝██╔████╔██║█████╔╝          ██║   ██║   ██║██║   ██║██║       ║
║   ██╔═══╝ ██║╚██╔╝██║██╔═██╗          ██║   ██║   ██║██║   ██║██║       ║
║   ██║     ██║ ╚═╝ ██║██║  ██╗         ██║   ╚██████╔╝╚██████╔╝███████╗  ║
║   ╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝         ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝  ║
║                        PMK Toolbox - Tối ưu Windows                      ║
║                    Phiên bản: 2.3 | Windows 10/11                        ║
╚══════════════════════════════════════════════════════════════════════════╝
"@

Write-Host $logo -ForegroundColor Cyan
Write-Host "`nĐang khởi tạo PMK Toolbox... (Tối ưu hiệu năng)" -ForegroundColor Yellow

# Kiểm tra winget
function Test-Winget {
    try {
        $wingetResult = winget --version 2>$null
        return ($LASTEXITCODE -eq 0) -or ($wingetResult -ne $null)
    } catch {
        return $false
    }
}

# Load WPF Assemblies với timeout
try {
    # Sử dụng runspace để tránh block UI
    $loadAssemblyJob = [PowerShell]::Create().AddScript({
        Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
    })
    $loadAssemblyHandle = $loadAssemblyJob.BeginInvoke()
    
    # Timeout 10 giây
    $timeout = 10000
    $startTime = Get-Date
    while (-not $loadAssemblyHandle.IsCompleted) {
        if (((Get-Date) - $startTime).TotalMilliseconds -gt $timeout) {
            Write-Warning "Timeout khi load WPF assemblies"
            $loadAssemblyJob.Stop()
            break
        }
        Start-Sleep -Milliseconds 100
    }
    
    if ($loadAssemblyHandle.IsCompleted) {
        $loadAssemblyJob.EndInvoke($loadAssemblyHandle)
    }
    
    $loadAssemblyJob.Dispose()
} catch {
    Write-Host "⚠️  Lỗi khi load WPF assemblies: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Thử load với phương pháp thay thế..." -ForegroundColor Cyan
    
    # Thử phương pháp backup
    try {
        [System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework') | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName('PresentationCore') | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName('WindowsBase') | Out-Null
    } catch {
        Write-Host "❌ Không thể load WPF. Vui lòng cài đặt .NET Framework 4.8 trở lên." -ForegroundColor Red
        Pause
        exit
    }
}
#endregion

#region Dữ liệu ứng dụng (Optimized for memory)
$Apps = @{
    "🌐 Trình duyệt" = @(
        @{Name="Brave"; Winget="Brave.Brave"; Icon="🚀"}
        @{Name="Google Chrome"; Winget="Google.Chrome"; Icon="🔍"}
        @{Name="Firefox"; Winget="Mozilla.Firefox"; Icon="🦊"}
        @{Name="Microsoft Edge"; Winget="Microsoft.Edge"; Icon="⚡"}
        @{Name="Opera"; Winget="Opera.Opera"; Icon="🎭"}
    )
    "💬 Giao tiếp" = @(
        @{Name="Discord"; Winget="Discord.Discord"; Icon="🎮"}
        @{Name="Telegram"; Winget="Telegram.TelegramDesktop"; Icon="✈️"}
        @{Name="Zoom"; Winget="Zoom.Zoom"; Icon="📹"}
        @{Name="Skype"; Winget="Microsoft.Skype"; Icon="💼"}
    )
    "🛠️ Công cụ phát triển" = @(
        @{Name="Visual Studio Code"; Winget="Microsoft.VisualStudioCode"; Icon="📝"}
        @{Name="Git"; Winget="Git.Git"; Icon="🌿"}
        @{Name="Python 3"; Winget="Python.Python.3.12"; Icon="🐍"}
        @{Name="Node.js"; Winget="OpenJS.NodeJS"; Icon="⬢"}
    )
    "🎨 Đa phương tiện" = @(
        @{Name="VLC"; Winget="VideoLAN.VLC"; Icon="🎬"}
        @{Name="Spotify"; Winget="Spotify.Spotify"; Icon="🎵"}
        @{Name="GIMP"; Winget="GIMP.GIMP"; Icon="🖼️"}
        @{Name="OBS Studio"; Winget="OBSProject.OBSStudio"; Icon="🎥"}
    )
    "📦 Tiện ích hệ thống" = @(
        @{Name="7-Zip"; Winget="7zip.7zip"; Icon="🗜️"}
        @{Name="WinRAR"; Winget="RARLab.WinRAR"; Icon="📦"}
        @{Name="CCleaner"; Winget="Piriform.CCleaner"; Icon="🧹"}
        @{Name="Everything"; Winget="voidtools.Everything"; Icon="🔎"}
    )
}
#endregion

#region DNS Servers Data
$DNSServers = @{
    "Default DHCP" = @{
        "Primary" = ""
        "Secondary" = ""
        "Primary6" = ""
        "Secondary6" = ""
    }
    "Google" = @{
        "Primary" = "8.8.8.8"
        "Secondary" = "8.8.4.4"
        "Primary6" = "2001:4860:4860::8888"
        "Secondary6" = "2001:4860:4860::8844"
    }
    "Cloudflare" = @{
        "Primary" = "1.1.1.1"
        "Secondary" = "1.0.0.1"
        "Primary6" = "2606:4700:4700::1111"
        "Secondary6" = "2606:4700:4700::1001"
    }
    "Cloudflare_Malware" = @{
        "Primary" = "1.1.1.2"
        "Secondary" = "1.0.0.2"
        "Primary6" = "2606:4700:4700::1112"
        "Secondary6" = "2606:4700:4700::1002"
    }
    "Cloudflare_Malware_Adult" = @{
        "Primary" = "1.1.1.3"
        "Secondary" = "1.0.0.3"
        "Primary6" = "2606:4700:4700::1113"
        "Secondary6" = "2606:4700:4700::1003"
    }
    "Open_DNS" = @{
        "Primary" = "208.67.222.222"
        "Secondary" = "208.67.220.220"
        "Primary6" = "2620:119:35::35"
        "Secondary6" = "2620:119:53::53"
    }
    "Quad9" = @{
        "Primary" = "9.9.9.9"
        "Secondary" = "149.112.112.112"
        "Primary6" = "2620:fe::fe"
        "Secondary6" = "2620:fe::9"
    }
    "AdGuard_Ads_Trackers" = @{
        "Primary" = "94.140.14.14"
        "Secondary" = "94.140.15.15"
        "Primary6" = "2a10:50c0::ad1:ff"
        "Secondary6" = "2a10:50c0::ad2:ff"
    }
    "AdGuard_Ads_Trackers_Malware_Adult" = @{
        "Primary" = "94.140.14.15"
        "Secondary" = "94.140.15.16"
        "Primary6" = "2a10:50c0::bad1:ff"
        "Secondary6" = "2a10:50c0::bad2:ff"
    }
}
#endregion

#region Hàm Registry (Optimized)
function Set-RegistryTweak {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord",
        [switch]$CreatePath
    )
    
    try {
        if ($CreatePath) {
            $null = New-Item -Path $Path -Force -ErrorAction SilentlyContinue
        }
        
        if (-not (Test-Path $Path)) {
            return $false
        }
        
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        return $true
    } catch {
        Write-Warning "Lỗi registry: $_"
        return $false
    }
}

function Remove-WindowsApp {
    param([string]$Pattern)
    
    try {
        $removedCount = 0
        Get-AppxPackage -AllUsers | Where-Object {$_.Name -like $Pattern} | ForEach-Object {
            try {
                Remove-AppxPackage -Package $_.PackageFullName -ErrorAction SilentlyContinue
                $removedCount++
            } catch {}
        }
        return $removedCount
    } catch {
        return 0
    }
}
#endregion

#region Danh sách Tweak mở rộng (WinUtil inspired)
$Tweaks = @{
    "🔧 Tối ưu hiệu suất" = @(
        @{Name="Tạo điểm khôi phục hệ thống"; Action={
            try {
                if ((Get-ComputerRestorePoint).Count -eq 0) {
                    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
                }
                Checkpoint-Computer -Description "PMK Toolbox - $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
                return "✅ Đã tạo điểm khôi phục"
            } catch { 
                return "⚠️ Không thể tạo điểm khôi phục"
            }
        }}
        @{Name="Xóa file tạm"; Action={
            try {
                Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
                return "✅ Đã xóa file tạm"
            } catch { 
                return "⚠️ Đã xóa một phần file tạm"
            }
        }}
        @{Name="Vô hiệu hóa Telemetry"; Action={
            $results = @()
            $paths = @(
                @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name="AllowTelemetry"; Value=0}
                @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name="AllowTelemetry"; Value=0}
                @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"; Name="AITEnable"; Value=0}
            )
            foreach ($reg in $paths) {
                if (Set-RegistryTweak -Path $reg.Path -Name $reg.Name -Value $reg.Value -CreatePath) {
                    $results += "✅"
                } else {
                    $results += "⚠️"
                }
            }
            return "Telemetry: $($results -join ' ')"
        }}
        @{Name="Tắt dịch vụ không cần thiết"; Action={
            $services = @("DiagTrack", "dmwappushservice", "WMPNetworkSvc", "RemoteRegistry")
            $results = @()
            foreach ($service in $services) {
                try {
                    Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
                    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                    $results += "✅"
                } catch { 
                    $results += "⚠️"
                }
            }
            return "Dịch vụ: $($results -join ' ')"
        }}
        @{Name="Tối ưu hóa điện năng"; Action={
            try {
                powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
                powercfg -h off 2>$null
                return "✅ Đã áp dụng chế độ hiệu suất cao"
            } catch { 
                return "⚠️ Không thể thay đổi điện năng"
            }
        }}
        @{Name="Tắt Hibernation"; Action={
            try {
                Set-RegistryTweak -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernateEnabled" -Value 0 -CreatePath
                Set-RegistryTweak -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Value 0 -CreatePath
                powercfg.exe /hibernate off 2>$null
                return "✅ Đã tắt Hibernation"
            } catch {
                return "⚠️ Không thể tắt Hibernation"
            }
        }}
    )
    
    "🛡️ Bảo mật & Riêng tư" = @(
        @{Name="Tắt Cortana"; Action={
            $results = @()
            $paths = @(
                @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name="AllowCortana"; Value=0}
                @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name="AllowSearchToUseLocation"; Value=0}
            )
            foreach ($reg in $paths) {
                if (Set-RegistryTweak -Path $reg.Path -Name $reg.Name -Value $reg.Value -CreatePath) {
                    $results += "✅"
                } else {
                    $results += "⚠️"
                }
            }
            return "Cortana: $($results -join ' ')"
        }}
        @{Name="Vô hiệu hóa quảng cáo"; Action={
            $results = @()
            $paths = @(
                @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name="Enabled"; Value=0}
                @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name="DisabledByGroupPolicy"; Value=1}
            )
            foreach ($reg in $paths) {
                if (Set-RegistryTweak -Path $reg.Path -Name $reg.Name -Value $reg.Value -CreatePath) {
                    $results += "✅"
                } else {
                    $results += "⚠️"
                }
            }
            return "Quảng cáo: $($results -join ' ')"
        }}
        @{Name="Tắt theo dõi vị trí"; Action={
            $results = @()
            $paths = @(
                @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"; Name="Value"; Value="Deny"; Type="String"}
                @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"; Name="SensorPermissionState"; Value=0}
            )
            foreach ($reg in $paths) {
                if (Set-RegistryTweak -Path $reg.Path -Name $reg.Name -Value $reg.Value -Type $reg.Type -CreatePath) {
                    $results += "✅"
                } else {
                    $results += "⚠️"
                }
            }
            return "Vị trí: $($results -join ' ')"
        }}
        @{Name="Tắt Windows Defender (Không khuyến khích)"; Action={
            if (Set-RegistryTweak -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -CreatePath) {
                return "✅ Đã tắt Windows Defender"
            } else {
                return "⚠️ Không thể tắt Defender"
            }
        }}
        @{Name="Tắt Activity History"; Action={
            $results = @()
            $paths = @(
                @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name="EnableActivityFeed"; Value=0}
                @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name="PublishUserActivities"; Value=0}
                @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name="UploadUserActivities"; Value=0}
            )
            foreach ($reg in $paths) {
                if (Set-RegistryTweak -Path $reg.Path -Name $reg.Name -Value $reg.Value -CreatePath) {
                    $results += "✅"
                } else {
                    $results += "⚠️"
                }
            }
            return "Activity History: $($results -join ' ')"
        }}
    )
    
    "🎨 Tùy chỉnh giao diện" = @(
        @{Name="Chế độ tối (Dark Mode)"; Action={
            $results = @()
            $paths = @(
                @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name="AppsUseLightTheme"; Value=0}
                @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name="SystemUsesLightTheme"; Value=0}
            )
            foreach ($reg in $paths) {
                if (Set-RegistryTweak -Path $reg.Path -Name $reg.Name -Value $reg.Value) {
                    $results += "✅"
                } else {
                    $results += "⚠️"
                }
            }
            return "Dark Mode: $($results -join ' ')"
        }}
        @{Name="Hiển thị file ẩn và phần mở rộng"; Action={
            $results = @()
            $paths = @(
                @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="Hidden"; Value=1}
                @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="HideFileExt"; Value=0}
                @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="ShowSuperHidden"; Value=1}
            )
            foreach ($reg in $paths) {
                if (Set-RegistryTweak -Path $reg.Path -Name $reg.Name -Value $reg.Value) {
                    $results += "✅"
                } else {
                    $results += "⚠️"
                }
            }
            return "File Explorer: $($results -join ' ')"
        }}
        @{Name="Tắt hiệu ứng trong suốt"; Action={
            if (Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0) {
                return "✅ Đã tắt hiệu ứng trong suốt"
            } else {
                return "⚠️ Không thể tắt hiệu ứng"
            }
        }}
        @{Name="Bật NumLock khi khởi động"; Action={
            $results = @()
            $paths = @(
                @{Path="HKU:\.DEFAULT\Control Panel\Keyboard"; Name="InitialKeyboardIndicators"; Value=2}
                @{Path="HKCU:\Control Panel\Keyboard"; Name="InitialKeyboardIndicators"; Value=2}
            )
            foreach ($reg in $paths) {
                if (Set-RegistryTweak -Path $reg.Path -Name $reg.Name -Value $reg.Value -CreatePath) {
                    $results += "✅"
                } else {
                    $results += "⚠️"
                }
            }
            return "NumLock: $($results -join ' ')"
        }}
    )
    
    "🧹 Dọn dẹp Windows" = @(
        @{Name="Xóa OneDrive"; Action={
            try {
                # Dừng tiến trình OneDrive
                Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                
                # Hủy cài đặt OneDrive
                $setupPaths = @(
                    "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
                    "$env:SystemRoot\System32\OneDriveSetup.exe"
                )
                
                foreach ($path in $setupPaths) {
                    if (Test-Path $path) {
                        Start-Process -FilePath $path -ArgumentList "/uninstall" -Wait -NoNewWindow -ErrorAction SilentlyContinue
                    }
                }
                
                # Xóa thư mục OneDrive
                Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item "$env:ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
                
                return "✅ Đã xóa OneDrive"
            } catch { 
                return "⚠️ Không thể xóa hoàn toàn OneDrive"
            }
        }}
        @{Name="Xóa Windows Bloatware"; Action={
            $bloatApps = @(
                "*3DBuilder*", "*Bing*", "*Clipchamp*", "*Cortana*", 
                "*FeedbackHub*", "*GetHelp*", "*GetStarted*", "*MicrosoftSolitaireCollection*",
                "*MixedReality*", "*OneConnect*", "*People*", "*PowerAutomate*", "*Skype*",
                "*Tips*", "*Wallet*", "*WebExperiences*",
                "*WindowsAlarms*", "*WindowsCamera*", "*WindowsMaps*", "*Xbox*"
            )
            
            $removedCount = 0
            foreach ($app in $bloatApps) {
                $removedCount += (Remove-WindowsApp -Pattern $app)
            }
            
            if ($removedCount -gt 0) {
                return "✅ Đã xóa $removedCount ứng dụng bloatware"
            } else {
                return "ℹ️ Không tìm thấy bloatware để xóa"
            }
        }}
        @{Name="Tắt Windows Tips"; Action={
            if (Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338393Enabled" -Value 0 -CreatePath) {
                return "✅ Đã tắt Windows Tips"
            } else {
                return "⚠️ Không thể tắt Tips"
            }
        }}
        @{Name="Tắt Consumer Features"; Action={
            if (Set-RegistryTweak -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -CreatePath) {
                return "✅ Đã tắt Consumer Features"
            } else {
                return "⚠️ Không thể tắt Consumer Features"
            }
        }}
    )
    
    "⚡ Tweak nâng cao" = @(
        @{Name="Tắt Game Bar & DVR"; Action={
            $results = @()
            $paths = @(
                @{Path="HKCU:\System\GameConfigStore"; Name="GameDVR_Enabled"; Value=0}
                @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"; Name="AppCaptureEnabled"; Value=0}
            )
            foreach ($reg in $paths) {
                if (Set-RegistryTweak -Path $reg.Path -Name $reg.Name -Value $reg.Value -CreatePath) {
                    $results += "✅"
                } else {
                    $results += "⚠️"
                }
            }
            return "Game Bar: $($results -join ' ')"
        }}
        @{Name="Tắt Notifications"; Action={
            if (Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0) {
                return "✅ Đã tắt thông báo"
            } else {
                return "⚠️ Không thể tắt thông báo"
            }
        }}
        @{Name="Prefer IPv4 over IPv6"; Action={
            if (Set-RegistryTweak -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 32) {
                return "✅ Ưu tiên IPv4"
            } else {
                return "⚠️ Không thể thay đổi IPv4/IPv6"
            }
        }}
        @{Name="Tắt Storage Sense"; Action={
            if (Set-RegistryTweak -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0) {
                return "✅ Đã tắt Storage Sense"
            } else {
                return "⚠️ Không thể tắt Storage Sense"
            }
        }}
        @{Name="Set UTC Time (Dual Boot)"; Action={
            if (Set-RegistryTweak -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Value 1 -Type "QWord") {
                return "✅ Đã đặt thời gian UTC (Dual Boot)"
            } else {
                return "⚠️ Không thể đặt UTC"
            }
        }}
    )
}
#endregion

#region Hàm quản lý DNS
function Set-DNSServer {
    param(
        [string]$DNSServerName
    )
    
    try {
        $dnsConfig = $DNSServers[$DNSServerName]
        
        if ($DNSServerName -eq "Default DHCP") {
            # Reset về DHCP
            $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
            foreach ($adapter in $adapters) {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
            }
            return "✅ Đã reset DNS về DHCP"
        }
        
        if ($dnsConfig) {
            $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
            $successCount = 0
            
            foreach ($adapter in $adapters) {
                try {
                    $dnsAddresses = @()
                    if ($dnsConfig.Primary) { $dnsAddresses += $dnsConfig.Primary }
                    if ($dnsConfig.Secondary) { $dnsAddresses += $dnsConfig.Secondary }
                    
                    Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $dnsAddresses -ErrorAction Stop
                    $successCount++
                } catch {
                    Write-Warning "Không thể đặt DNS cho adapter $($adapter.Name): $_"
                }
            }
            
            # Flush DNS cache
            Clear-DnsClientCache -ErrorAction SilentlyContinue
            
            if ($successCount -gt 0) {
                return "✅ Đã đặt DNS $DNSServerName cho $successCount adapter(s)"
            } else {
                return "❌ Không thể đặt DNS cho bất kỳ adapter nào"
            }
        } else {
            return "❌ Cấu hình DNS không tồn tại"
        }
    } catch {
        return "❌ Lỗi khi đặt DNS: $_"
    }
}
#endregion

#region Hàm lấy thông tin hệ thống (Optimized)
function Get-SystemInfoText {
    try {
        # Sử dụng WMI thay vì CIM để nhanh hơn
        $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
        $cpu = Get-WmiObject -Class Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        $cs = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
        $gpu = Get-WmiObject -Class Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        $disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
        
        $osName = if ($os.Caption) { $os.Caption } else { "Không xác định" }
        $osBuild = if ($os.BuildNumber) { $os.BuildNumber } else { "N/A" }
        
        $cpuName = if ($cpu.Name) { $cpu.Name.Trim() } else { "Không xác định" }
        $cpuCores = if ($cpu.NumberOfCores) { $cpu.NumberOfCores } else { "N/A" }
        $cpuSpeed = if ($cpu.MaxClockSpeed) { [math]::Round($cpu.MaxClockSpeed / 1000, 2) } else { "N/A" }
        
        $totalRAM = if ($cs.TotalPhysicalMemory) { [math]::Round($cs.TotalPhysicalMemory / 1GB, 2) } else { "N/A" }
        
        $gpuName = if ($gpu.Name) { $gpu.Name } else { "Không xác định" }
        $gpuRAM = if ($gpu.AdapterRAM) { [math]::Round($gpu.AdapterRAM / 1GB, 2) } else { "N/A" }
        
        $diskInfo = @()
        foreach ($disk in $disks) {
            $drive = $disk.DeviceID
            $size = if ($disk.Size) { [math]::Round($disk.Size / 1GB, 2) } else { "N/A" }
            $free = if ($disk.FreeSpace) { [math]::Round($disk.FreeSpace / 1GB, 2) } else { "N/A" }
            $used = if ($size -ne "N/A" -and $free -ne "N/A") { $size - $free } else { "N/A" }
            $diskInfo += "   • $drive Tổng: $size GB | Đã dùng: $used GB | Trống: $free GB"
        }
        $diskText = if ($diskInfo.Count -gt 0) { $diskInfo -join "`n" } else { "   • Không có ổ đĩa nào được tìm thấy" }
        
        return @"
══════════════════════════════════════════════════════════════════════
                  THÔNG TIN HỆ THỐNG

📊 Hệ điều hành:
   • Tên: $osName
   • Build: $osBuild

⚡ CPU:
   • Model: $cpuName
   • Số nhân: $cpuCores
   • Tốc độ: $cpuSpeed GHz

💾 RAM:
   • Tổng: $totalRAM GB

🎮 GPU:
   • Card màn hình: $gpuName
   • Bộ nhớ: $gpuRAM GB

💿 Ổ đĩa:
$diskText

══════════════════════════════════════════════════════════════════════
"@
    } catch {
        return "Lỗi khi lấy thông tin hệ thống: $($_.Exception.Message)"
    }
}
#endregion

#region Tạo GUI WPF với Virtualization (Performance Optimized)
function Create-MainWindow {
    # Tạo cửa sổ chính với Virtualization
    $Window = New-Object Windows.Window
    $Window.Title = "PMK Toolbox - Tối ưu Windows"
    $Window.Width = 1200
    $Window.Height = 750
    $Window.WindowStartupLocation = "CenterScreen"
    $Window.Background = [System.Windows.Media.Brushes]::WhiteSmoke
    $Window.FontFamily = "Segoe UI"
    
    # Grid chính với VirtualizingStackPanel
    $MainGrid = New-Object Windows.Controls.Grid
    
    # Header đơn giản hóa
    $HeaderText = New-Object Windows.Controls.TextBlock
    $HeaderText.Text = "PMK TOOLBOX - TỐI ƯU WINDOWS"
    $HeaderText.FontSize = 24
    $HeaderText.FontWeight = "Bold"
    $HeaderText.Foreground = [System.Windows.Media.Brushes]::DarkBlue
    $HeaderText.HorizontalAlignment = "Center"
    $HeaderText.Margin = "0,10,0,10"
    
    # Tab Control với Virtualization
    $TabControl = New-Object Windows.Controls.TabControl
    $TabControl.Margin = "10"
    
    # Tab 1: Cài đặt ứng dụng (Optimized với VirtualizingStackPanel)
    $TabInstall = New-Object Windows.Controls.TabItem
    $TabInstall.Header = "📦 CÀI ĐẶT ỨNG DỤNG"
    
    $InstallScroll = New-Object Windows.Controls.ScrollViewer
    $InstallScroll.VerticalScrollBarVisibility = "Auto"
    
    # Sử dụng VirtualizingStackPanel cho hiệu năng
    $VirtualInstallStack = New-Object Windows.Controls.VirtualizingStackPanel
    $VirtualInstallStack.Margin = "10"
    
    $global:SelectedApps = @{}
    
    foreach ($category in $Apps.Keys) {
        $CategoryGroup = New-Object Windows.Controls.Expander
        $CategoryGroup.Header = $category
        $CategoryGroup.IsExpanded = $false
        $CategoryGroup.Margin = "0,0,0,5"
        
        $AppPanel = New-Object Windows.Controls.WrapPanel
        $AppPanel.Margin = "10,5,10,5"
        
        foreach ($app in $Apps[$category]) {
            $AppButton = New-Object Windows.Controls.Button
            $AppButton.Content = "$($app.Icon) $($app.Name)"
            $AppButton.Tag = $app.Winget
            $AppButton.Margin = "5"
            $AppButton.Padding = "10,5"
            $AppButton.Background = [System.Windows.Media.Brushes]::White
            $AppButton.BorderBrush = [System.Windows.Media.Brushes]::LightGray
            
            $AppButton.Add_Click({
                param($sender, $e)
                $button = $sender
                $appId = $button.Tag
                
                if ($global:SelectedApps.ContainsKey($appId)) {
                    $button.Background = [System.Windows.Media.Brushes]::White
                    $global:SelectedApps.Remove($appId) | Out-Null
                } else {
                    $button.Background = [System.Windows.Media.Brushes]::LightGreen
                    $global:SelectedApps[$appId] = $true
                }
            })
            
            $AppPanel.Children.Add($AppButton) | Out-Null
        }
        
        $CategoryGroup.Content = $AppPanel
        $VirtualInstallStack.Children.Add($CategoryGroup) | Out-Null
    }
    
    $InstallButton = New-Object Windows.Controls.Button
    $InstallButton.Content = "🚀 CÀI ĐẶT ỨNG DỤNG ĐÃ CHỌN"
    $InstallButton.FontSize = 14
    $InstallButton.FontWeight = "Bold"
    $InstallButton.Height = 40
    $InstallButton.Margin = "0,20,0,0"
    $InstallButton.Background = [System.Windows.Media.Brushes]::Green
    $InstallButton.Foreground = [System.Windows.Media.Brushes]::White
    
    $hasWinget = Test-Winget
    if (-not $hasWinget) {
        $InstallButton.IsEnabled = $false
        $InstallButton.Content = "⚠️ WINGET CHƯA CÀI ĐẶT"
        $InstallButton.Background = [System.Windows.Media.Brushes]::Gray
    }
    
    $VirtualInstallStack.Children.Add($InstallButton) | Out-Null
    $InstallScroll.Content = $VirtualInstallStack
    $TabInstall.Content = $InstallScroll
    $TabControl.Items.Add($TabInstall) | Out-Null
    
    # Tab 2: Tweak hệ thống
    $TabTweaks = New-Object Windows.Controls.TabItem
    $TabTweaks.Header = "⚙️ TỐI ƯU HỆ THỐNG"
    
    $TweakScroll = New-Object Windows.Controls.ScrollViewer
    $TweakScroll.VerticalScrollBarVisibility = "Auto"
    
    $TweakStack = New-Object Windows.Controls.StackPanel
    $TweakStack.Margin = "10"
    
    $global:SelectedTweaks = @{}
    
    foreach ($category in $Tweaks.Keys) {
        $CategoryGroup = New-Object Windows.Controls.Expander
        $CategoryGroup.Header = $category
        $CategoryGroup.IsExpanded = $false
        $CategoryGroup.Margin = "0,0,0,5"
        
        $TweakPanel = New-Object Windows.Controls.StackPanel
        $TweakPanel.Margin = "10,5,10,5"
        
        foreach ($tweak in $Tweaks[$category]) {
            $CheckBox = New-Object Windows.Controls.CheckBox
            $CheckBox.Content = $tweak.Name
            $CheckBox.FontSize = 13
            $CheckBox.Margin = "5"
            $CheckBox.Tag = $tweak
            
            $CheckBox.Add_Checked({
                $global:SelectedTweaks[$this.Content] = $this.Tag
            })
            
            $CheckBox.Add_Unchecked({
                $global:SelectedTweaks.Remove($this.Content) | Out-Null
            })
            
            $TweakPanel.Children.Add($CheckBox) | Out-Null
        }
        
        $CategoryGroup.Content = $TweakPanel
        $TweakStack.Children.Add($CategoryGroup) | Out-Null
    }
    
    $ExecuteTweaksButton = New-Object Windows.Controls.Button
    $ExecuteTweaksButton.Content = "⚡ ÁP DỤNG TWEAKS ĐÃ CHỌN"
    $ExecuteTweaksButton.FontSize = 14
    $ExecuteTweaksButton.FontWeight = "Bold"
    $ExecuteTweaksButton.Height = 40
    $ExecuteTweaksButton.Margin = "0,20,0,0"
    $ExecuteTweaksButton.Background = [System.Windows.Media.Brushes]::Orange
    $ExecuteTweaksButton.Foreground = [System.Windows.Media.Brushes]::White
    
    $TweakStack.Children.Add($ExecuteTweaksButton) | Out-Null
    $TweakScroll.Content = $TweakStack
    $TabTweaks.Content = $TweakScroll
    $TabControl.Items.Add($TabTweaks) | Out-Null
    
    # Tab 3: Quản lý DNS
    $TabDNS = New-Object Windows.Controls.TabItem
    $TabDNS.Header = "🌐 QUẢN LÝ DNS"
    
    $DNSStack = New-Object Windows.Controls.StackPanel
    $DNSStack.Margin = "20"
    $DNSStack.HorizontalAlignment = "Center"
    
    $DNSText = New-Object Windows.Controls.TextBlock
    $DNSText.Text = "Chọn DNS Server để áp dụng:"
    $DNSText.FontSize = 16
    $DNSText.Margin = "0,0,0,10"
    
    $DNSComboBox = New-Object Windows.Controls.ComboBox
    $DNSComboBox.Width = 300
    $DNSComboBox.FontSize = 14
    $DNSComboBox.ItemsSource = $DNSServers.Keys
    $DNSComboBox.SelectedIndex = 0
    
    $ApplyDNSButton = New-Object Windows.Controls.Button
    $ApplyDNSButton.Content = "ÁP DỤNG DNS"
    $ApplyDNSButton.FontSize = 14
    $ApplyDNSButton.FontWeight = "Bold"
    $ApplyDNSButton.Width = 150
    $ApplyDNSButton.Height = 40
    $ApplyDNSButton.Margin = "0,20,0,0"
    $ApplyDNSButton.Background = [System.Windows.Media.Brushes]::Blue
    $ApplyDNSButton.Foreground = [System.Windows.Media.Brushes]::White
    
    $ApplyDNSButton.Add_Click({
        $selectedDNS = $DNSComboBox.SelectedValue
        if ($selectedDNS) {
            $this.IsEnabled = $false
            $this.Content = "ĐANG ÁP DỤNG..."
            
            # Chạy trong background job
            $job = Start-Job -ScriptBlock {
                param($dnsName)
                . (Get-Command Set-DNSServer).ScriptBlock
                Set-DNSServer -DNSServerName $dnsName
            } -ArgumentList $selectedDNS
            
            while ($job.State -eq "Running") {
                Start-Sleep -Milliseconds 100
            }
            
            $result = Receive-Job -Job $job
            Remove-Job -Job $job
            
            [System.Windows.MessageBox]::Show($result, "Kết quả", "OK", "Information")
            
            $this.Content = "ÁP DỤNG DNS"
            $this.IsEnabled = $true
        }
    })
    
    $DNSStack.Children.Add($DNSText) | Out-Null
    $DNSStack.Children.Add($DNSComboBox) | Out-Null
    $DNSStack.Children.Add($ApplyDNSButton) | Out-Null
    $TabDNS.Content = $DNSStack
    $TabControl.Items.Add($TabDNS) | Out-Null
    
    # Tab 4: Thông tin hệ thống
    $TabInfo = New-Object Windows.Controls.TabItem
    $TabInfo.Header = "💻 THÔNG TIN HỆ THỐNG"
    
    $InfoStack = New-Object Windows.Controls.StackPanel
    $InfoStack.Margin = "20"
    
    $InfoText = New-Object Windows.Controls.TextBox
    $InfoText.Text = Get-SystemInfoText
    $InfoText.FontFamily = "Consolas"
    $InfoText.FontSize = 12
    $InfoText.IsReadOnly = $true
    $InfoText.VerticalScrollBarVisibility = "Auto"
    $InfoText.TextWrapping = "Wrap"
    $InfoText.Width = 700
    $InfoText.Height = 400
    
    $RefreshButton = New-Object Windows.Controls.Button
    $RefreshButton.Content = "🔄 LÀM MỚI THÔNG TIN"
    $RefreshButton.FontSize = 14
    $RefreshButton.Margin = "0,15,0,0"
    $RefreshButton.Width = 200
    $RefreshButton.Height = 40
    
    $RefreshButton.Add_Click({
        $InfoText.Text = "Đang cập nhật thông tin hệ thống..."
        $InfoText.Text = Get-SystemInfoText
    })
    
    $InfoStack.Children.Add($InfoText) | Out-Null
    $InfoStack.Children.Add($RefreshButton) | Out-Null
    $TabInfo.Content = $InfoStack
    $TabControl.Items.Add($TabInfo) | Out-Null
    
    # Footer buttons
    $FooterPanel = New-Object Windows.Controls.StackPanel
    $FooterPanel.Orientation = "Horizontal"
    $FooterPanel.HorizontalAlignment = "Center"
    $FooterPanel.Margin = "0,10,0,10"
    
    $RestartButton = New-Object Windows.Controls.Button
    $RestartButton.Content = "🔄 KHỞI ĐỘNG LẠI"
    $RestartButton.Width = 150
    $RestartButton.Height = 40
    $RestartButton.Margin = "10"
    $RestartButton.Background = [System.Windows.Media.Brushes]::OrangeRed
    
    $ExitButton = New-Object Windows.Controls.Button
    $ExitButton.Content = "❌ THOÁT"
    $ExitButton.Width = 150
    $ExitButton.Height = 40
    $ExitButton.Margin = "10"
    $ExitButton.Background = [System.Windows.Media.Brushes]::Red
    $ExitButton.Foreground = [System.Windows.Media.Brushes]::White
    
    $FooterPanel.Children.Add($RestartButton) | Out-Null
    $FooterPanel.Children.Add($ExitButton) | Out-Null
    
    # Xây dựng layout
    $MainGrid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height = "Auto"}))
    $MainGrid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition))
    $MainGrid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height = "Auto"}))
    
    [Windows.Controls.Grid]::SetRow($HeaderText, 0)
    [Windows.Controls.Grid]::SetRow($TabControl, 1)
    [Windows.Controls.Grid]::SetRow($FooterPanel, 2)
    
    $MainGrid.Children.Add($HeaderText) | Out-Null
    $MainGrid.Children.Add($TabControl) | Out-Null
    $MainGrid.Children.Add($FooterPanel) | Out-Null
    
    # Sự kiện nút
    $InstallButton.Add_Click({
        if ($global:SelectedApps.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Vui lòng chọn ít nhất một ứng dụng!", "Thông báo", "OK", "Information")
            return
        }
        
        $result = [System.Windows.MessageBox]::Show(
            "Bạn muốn cài đặt $($global:SelectedApps.Count) ứng dụng?",
            "Xác nhận cài đặt",
            "YesNo",
            "Question"
        )
        
        if ($result -eq "Yes") {
            $this.IsEnabled = $false
            $this.Content = "⏳ ĐANG CÀI ĐẶT..."
            
            $progress = 0
            $total = $global:SelectedApps.Count
            
            foreach ($appId in $global:SelectedApps.Keys) {
                $progress++
                $percentage = [math]::Round(($progress / $total) * 100)
                $this.Content = "⏳ ĐANG CÀI ĐẶT... ${percentage}%"
                
                try {
                    Write-Host "Cài đặt: $appId ..." -ForegroundColor Yellow
                    Start-Process -FilePath "winget" -ArgumentList "install --id $appId --accept-package-agreements --accept-source-agreements --silent" -Wait -NoNewWindow
                    Write-Host "✅ Đã cài đặt: $appId" -ForegroundColor Green
                } catch {
                    Write-Host "❌ Lỗi khi cài $appId" -ForegroundColor Red
                }
            }
            
            $this.Content = "✅ HOÀN TẤT!"
            [System.Windows.MessageBox]::Show("Đã cài đặt xong $total ứng dụng!", "Thành công", "OK", "Information")
            
            # Reset button
            $timer = New-Object System.Windows.Threading.DispatcherTimer
            $timer.Interval = [TimeSpan]::FromSeconds(2)
            $timer.Add_Tick({
                $InstallButton.Content = "🚀 CÀI ĐẶT ỨNG DỤNG ĐÃ CHỌN"
                $InstallButton.IsEnabled = $true
                $this.Stop()
            })
            $timer.Start()
        }
    })
    
    $ExecuteTweaksButton.Add_Click({
        if ($global:SelectedTweaks.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Vui lòng chọn ít nhất một tweak!", "Thông báo", "OK", "Information")
            return
        }
        
        $result = [System.Windows.MessageBox]::Show(
            "Bạn có chắc muốn áp dụng $($global:SelectedTweaks.Count) tweak?",
            "Xác nhận áp dụng tweak",
            "YesNo",
            "Warning"
        )
        
        if ($result -eq "Yes") {
            $this.IsEnabled = $false
            $this.Content = "⏳ ĐANG ÁP DỤNG..."
            
            $results = @()
            $progress = 0
            $total = $global:SelectedTweaks.Count
            
            foreach ($tweakName in $global:SelectedTweaks.Keys) {
                $tweak = $global:SelectedTweaks[$tweakName]
                $progress++
                $percentage = [math]::Round(($progress / $total) * 100)
                $this.Content = "⏳ ĐANG ÁP DỤNG... ${percentage}%"
                
                Write-Host "`n[${progress}/${total}] $tweakName ..." -ForegroundColor Yellow
                
                try {
                    $result = & $tweak.Action
                    $results += "✅ $tweakName : $result"
                    Write-Host "   $result" -ForegroundColor Green
                } catch {
                    $results += "❌ $tweakName : Lỗi - $($_.Exception.Message)"
                    Write-Host "   ❌ Lỗi: $($_.Exception.Message)" -ForegroundColor Red
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
            
            $resultWindow.Content = $resultTextBox
            $resultWindow.ShowDialog() | Out-Null
            
            $this.Content = "✅ HOÀN TẤT!"
            
            # Reset button
            $timer = New-Object System.Windows.Threading.DispatcherTimer
            $timer.Interval = [TimeSpan]::FromSeconds(2)
            $timer.Add_Tick({
                $ExecuteTweaksButton.Content = "⚡ ÁP DỤNG TWEAKS ĐÃ CHỌN"
                $ExecuteTweaksButton.IsEnabled = $true
                $this.Stop()
            })
            $timer.Start()
        }
    })
    
    $RestartButton.Add_Click({
        $result = [System.Windows.MessageBox]::Show("Bạn có muốn khởi động lại máy tính ngay bây giờ?", "Xác nhận", "YesNo", "Question")
        if ($result -eq "Yes") {
            Restart-Computer -Force
        }
    })
    
    $ExitButton.Add_Click({
        $Window.Close()
    })
    
    $Window.Content = $MainGrid
    return $Window
}
#endregion

#region Main Execution
# Kiểm tra winget
$hasWinget = Test-Winget
if (-not $hasWinget) {
    Write-Host "⚠️  Winget không được cài đặt. Tính năng cài đặt ứng dụng bị vô hiệu hóa." -ForegroundColor Yellow
    Write-Host "   Cài đặt Winget từ Microsoft Store hoặc chạy lệnh sau:" -ForegroundColor Yellow
    Write-Host "   winget install --id Microsoft.Winget.CLI" -ForegroundColor Cyan
}

# Hiển thị GUI
try {
    $mainWindow = Create-MainWindow
    
    # Tối ưu hóa hiệu năng GUI
    [System.Windows.Forms.Application]::EnableVisualStyles()
    
    # Sử dụng Dispatcher để tránh block UI
    $mainWindow.Add_Loaded({
        # Đảm bảo GUI được render xong
        $this.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::ApplicationIdle)
    })
    
    $null = $mainWindow.ShowDialog()
} catch {
    Write-Host "❌ Lỗi khi tạo giao diện: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor DarkYellow
    
    # Fallback to simple console menu
    Write-Host "`nChuyển sang chế độ dòng lệnh..." -ForegroundColor Yellow
    Show-ConsoleMenu
}

function Show-ConsoleMenu {
    do {
        Clear-Host
        Write-Host $logo -ForegroundColor Cyan
        Write-Host "`n=== MENU DÒNG LỆNH ===" -ForegroundColor Green
        Write-Host "1. Hiển thị thông tin hệ thống"
        Write-Host "2. Xóa file tạm"
        Write-Host "3. Tạo điểm khôi phục"
        Write-Host "4. Tắt dịch vụ không cần thiết"
        Write-Host "5. Thoát"
        Write-Host "`nChọn chức năng (1-5): " -ForegroundColor Yellow -NoNewline
        
        $choice = Read-Host
        
        switch ($choice) {
            "1" {
                Write-Host "`n" (Get-SystemInfoText) -ForegroundColor Cyan
                Pause
            }
            "2" {
                Write-Host "Đang xóa file tạm..." -ForegroundColor Yellow
                Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "✅ Đã xóa file tạm" -ForegroundColor Green
                Pause
            }
            "3" {
                Write-Host "Đang tạo điểm khôi phục..." -ForegroundColor Yellow
                try {
                    Checkpoint-Computer -Description "PMK Toolbox Console - $(Get-Date)" -RestorePointType MODIFY_SETTINGS
                    Write-Host "✅ Đã tạo điểm khôi phục" -ForegroundColor Green
                } catch {
                    Write-Host "❌ Lỗi: $($_.Exception.Message)" -ForegroundColor Red
                }
                Pause
            }
            "4" {
                Write-Host "Đang tắt dịch vụ không cần thiết..." -ForegroundColor Yellow
                $services = @("DiagTrack", "dmwappushservice", "WMPNetworkSvc", "RemoteRegistry")
                foreach ($service in $services) {
                    try {
                        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
                        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                        Write-Host "✅ Đã tắt $service" -ForegroundColor Green
                    } catch {
                        Write-Host "⚠️ Không thể tắt $service" -ForegroundColor Yellow
                    }
                }
                Pause
            }
            "5" {
                Write-Host "Thoát..." -ForegroundColor Cyan
                exit
            }
            default {
                Write-Host "Lựa chọn không hợp lệ!" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($choice -ne "5")
}
#endregion
