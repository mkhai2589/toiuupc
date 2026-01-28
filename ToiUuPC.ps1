# ToiUuPC.ps1 - Công cụ tối ưu Windows (Tổng hợp WinUtil + Win11Debloat + Sophia)
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Thuthuatwiki

# Yêu cầu quyền Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Load WPF
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# Danh sách ứng dụng (từ winutil + mở rộng)
$Apps = @{
    "Browsers" = @(
        @{Name="Brave";          Winget="Brave.Brave"}
        @{Name="Chrome";         Winget="Google.Chrome"}
        @{Name="Firefox";        Winget="Mozilla.Firefox"}
        @{Name="LibreWolf";      Winget="LibreWolf.LibreWolf"}
        @{Name="Vivaldi";        Winget="Vivaldi.Vivaldi"}
        @{Name="Ungoogled Chromium"; Winget="eloston.ungoogled-chromium"}
    )
    "Communications" = @(
        @{Name="Discord";        Winget="Discord.Discord"}
        @{Name="Signal";         Winget="OpenWhisperSystems.Signal"}
        @{Name="Telegram";       Winget="Telegram.TelegramDesktop"}
        @{Name="Teams";          Winget="Microsoft.Teams"}
        @{Name="Thunderbird";    Winget="Mozilla.Thunderbird"}
    )
    "Development" = @(
        @{Name="VS Code";        Winget="Microsoft.VisualStudioCode"}
        @{Name="Git";            Winget="Git.Git"}
        @{Name="Docker Desktop"; Winget="Docker.DockerDesktop"}
        @{Name="Python 3";       Winget="Python.Python.3"}
    )
}

# Danh sách Tweaks (từ WinUtil + Win11Debloat + Sophia + Debloater)
$Tweaks = @{
    "Essential Tweaks" = @(
        @{Name="Create Restore Point"; Action={
            Checkpoint-Computer -Description "ToiUuPC Backup - $(Get-Date -Format yyyyMMdd)" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
            Write-Host "Đã tạo Restore Point!" -ForegroundColor Green
        }}
        @{Name="Delete Temporary Files"; Action={
            Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Đã xóa file tạm!" -ForegroundColor Green
        }}
        @{Name="Disable Consumer Features"; Action={Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force}}
        @{Name="Disable Bing Search in Start Menu"; Action={Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Type DWord -Force}}
        @{Name="Disable Telemetry"; Action={Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force}}
        @{Name="Disable Activity History"; Action={Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type DWord -Force}}
        @{Name="Disable Hibernation"; Action={powercfg -h off; Write-Host "Đã tắt Hibernation!" -ForegroundColor Green}}
        @{Name="Disable Location Tracking"; Action={Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Force}}
        @{Name="Disable GameDVR"; Action={Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force}}
    )
    "Advanced Tweaks - CAUTION" = @(
        @{Name="Debloat Edge"; Action={
            Get-AppxPackage *edge* | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like *edge* | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        }}
        @{Name="Disable Background Apps"; Action={Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -Force}}
        @{Name="Disable IPv6"; Action={Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue}}
        @{Name="Disable Microsoft Copilot"; Action={Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force}}
        @{Name="Disable Storage Sense"; Action={Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type DWord -Force}}
    )
    "Customize Preferences" = @(
        @{Name="Dark Theme for Windows"; Action={Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force}}
        @{Name="Show Hidden Files"; Action={Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord -Force}}
        @{Name="Show File Extensions"; Action={Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -Force}}
        @{Name="Center Taskbar Items"; Action={Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 1 -Type DWord -Force}}
    )
}

# WPF GUI
$Window = New-Object Windows.Window
$Window.Title = "ToiUuPC - Tổng hợp WinUtil/Debloat/Sophia"
$Window.Width = 1200
$Window.Height = 800
$Window.WindowStartupLocation = "CenterScreen"

$TabControl = New-Object Windows.Controls.TabControl

# Tab Install
$InstallTab = New-Object Windows.Controls.TabItem
$InstallTab.Header = "Install"
$InstallScroll = New-Object Windows.Controls.ScrollViewer
$InstallPanel = New-Object Windows.Controls.StackPanel

foreach ($cat in $Apps.Keys) {
    $Label = New-Object Windows.Controls.Label
    $Label.Content = $cat
    $Label.FontSize = 16
    $Label.FontWeight = "Bold"
    $InstallPanel.Children.Add($Label)

    foreach ($app in $Apps[$cat]) {
        $Check = New-Object Windows.Controls.CheckBox
        $Check.Content = $app.Name
        $Check.Tag = $app.Winget
        $InstallPanel.Children.Add($Check)
    }
}

$InstallBtn = New-Object Windows.Controls.Button
$InstallBtn.Content = "Install Selected"
$InstallBtn.Add_Click({
    $selected = $InstallPanel.Children | Where-Object {$_ -is [Windows.Controls.CheckBox] -and $_.IsChecked}
    foreach ($cb in $selected) {
        Write-Host "Đang cài $($cb.Content)..." -ForegroundColor Green
        winget install --id $cb.Tag --accept-package-agreements --accept-source-agreements
    }
    [Windows.MessageBox]::Show("Cài đặt hoàn tất!")
})
$InstallPanel.Children.Add($InstallBtn)

$InstallScroll.Content = $InstallPanel
$InstallTab.Content = $InstallScroll
$TabControl.Items.Add($InstallTab)

# Tab Tweaks
$TweaksTab = New-Object Windows.Controls.TabItem
$TweaksTab.Header = "Tweaks"
$TweaksScroll = New-Object Windows.Controls.ScrollViewer
$TweaksGrid = New-Object Windows.Controls.Grid
$TweaksGrid.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition))
$TweaksGrid.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition))

# Cột trái: Essential & Advanced Tweaks
$LeftPanel = New-Object Windows.Controls.StackPanel
foreach ($cat in @("Essential Tweaks", "Advanced Tweaks - CAUTION")) {
    $Label = New-Object Windows.Controls.Label
    $Label.Content = $cat
    $Label.FontSize = 16
    $Label.FontWeight = "Bold"
    $LeftPanel.Children.Add($Label)

    foreach ($tweak in $Tweaks[$cat]) {
        $Check = New-Object Windows.Controls.CheckBox
        $Check.Content = $tweak.Name
        $Check.Tag = $tweak.Action
        $LeftPanel.Children.Add($Check)
    }
}
[Windows.Controls.Grid]::SetColumn($LeftPanel, 0)
$TweaksGrid.Children.Add($LeftPanel)

# Cột phải: Customize & Performance
$RightPanel = New-Object Windows.Controls.StackPanel
foreach ($cat in @("Customize Preferences")) {
    $Label = New-Object Windows.Controls.Label
    $Label.Content = $cat
    $Label.FontSize = 16
    $Label.FontWeight = "Bold"
    $RightPanel.Children.Add($Label)

    foreach ($tweak in $Tweaks[$cat]) {
        $Check = New-Object Windows.Controls.CheckBox
        $Check.Content = $tweak.Name
        $Check.Tag = $tweak.Action
        $RightPanel.Children.Add($Check)
    }
}

# Nút Run Tweaks & Undo
$RunBtn = New-Object Windows.Controls.Button
$RunBtn.Content = "Run Tweaks"
$RunBtn.Add_Click({
    Checkpoint-Computer -Description "ToiUuPC Tweaks Backup" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
    $selected = $TweaksGrid.Children | ForEach-Object { $_.Children } | Where-Object {$_ -is [Windows.Controls.CheckBox] -and $_.IsChecked}
    foreach ($cb in $selected) { & $cb.Tag }
    [Windows.MessageBox]::Show("Đã áp dụng Tweaks!")
})
$RightPanel.Children.Add($RunBtn)

$TweaksGrid.Children.Add($RightPanel)
[Windows.Controls.Grid]::SetColumn($RightPanel, 1)

$TweaksScroll.Content = $TweaksGrid
$TweaksTab.Content = $TweaksScroll
$TabControl.Items.Add($TweaksTab)

$Window.Content = $TabControl
$Window.ShowDialog() | Out-Null
