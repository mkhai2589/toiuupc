# ToiUuPC.ps1 - Công cụ tối ưu Windows (Tổng hợp WinUtil + Win11Debloat + Sophia)
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Thuthuatwiki (PMK)

# Giữ console mở logo trước khi load GUI
Clear-Host  # Clear màn hình đầu tiên để logo sạch sẽ

# Logo PMK kiểu figlet to, rộng, padding đẹp
$logo = @"

    ╔════════════════════════════════════════════════════════════╗
    ║                                                            ║
    ║   ██████╗ ███╗   ███╗██╗  ██╗                             ║
    ║   ██╔══██╗████╗ ████║██║ ██╔╝                             ║
    ║   ██████╔╝██╔████╔██║█████╔╝                              ║
    ║   ██╔═══╝ ██║╚██╔╝██║██╔═██╗                              ║
    ║   ██║     ██║ ╚═╝ ██║██║  ██╗                             ║
    ║   ╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝                             ║
    ║                                                            ║
    ║               PMK - Thuthuatwiki                           ║
    ║     Tối ưu Windows - PMK Toolbox                           ║
    ╚════════════════════════════════════════════════════════════╝

"@

Write-Host $logo -ForegroundColor Cyan
Write-Host "===== PMK Toolbox - Tối ưu Windows =====" -ForegroundColor Green
Write-Host "Tổng hợp từ WinUtil + Win11Debloat + Sophia" -ForegroundColor Cyan
Write-Host ""

# Yêu cầu quyền Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Load WPF (bỏ output thừa)
[void][System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
[void][System.Reflection.Assembly]::LoadWithPartialName('PresentationCore')
[void][System.Reflection.Assembly]::LoadWithPartialName('WindowsBase')

# Danh sách ứng dụng
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

# Tweaks mở rộng từ WinUtil (Essential + Advanced + Privacy + UI + Services)
$Tweaks = @{
    "Essential Tweaks" = @(
        @{Name="Create Restore Point"; Action={
            Write-Host "Creating System Restore Point..." -ForegroundColor Yellow
            Checkpoint-Computer -Description "PMK Backup - $(Get-Date -Format yyyyMMdd)" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
            Write-Host "Restore Point created!" -ForegroundColor Green
        }}
        @{Name="Delete Temporary Files"; Action={
            Write-Host "Deleting TEMP files..." -ForegroundColor Yellow
            Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "TEMP files deleted!" -ForegroundColor Green
        }}
        @{Name="Disable Telemetry"; Action={
            Write-Host "Disabling Telemetry..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force
            Write-Host "Telemetry disabled!" -ForegroundColor Green
        }}
        @{Name="Disable Consumer Features"; Action={
            Write-Host "Disabling Consumer Features..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Bing Search in Start Menu"; Action={
            Write-Host "Disabling Bing Search..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Activity History"; Action={
            Write-Host "Disabling Activity History..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Hibernation"; Action={
            Write-Host "Disabling Hibernation..." -ForegroundColor Yellow
            powercfg -h off
            Write-Host "Hibernation disabled! Restart to delete hiberfil.sys" -ForegroundColor Green
        }}
        @{Name="Disable Location Tracking"; Action={
            Write-Host "Disabling Location Tracking..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable GameDVR"; Action={
            Write-Host "Disabling GameDVR..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Cortana"; Action={
            Write-Host "Disabling Cortana..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord -Force
            Write-Host "Cortana disabled!" -ForegroundColor Green
        }}
        @{Name="Disable Advertising ID"; Action={
            Write-Host "Disabling Advertising ID..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
    )
    "Advanced Tweaks - CAUTION" = @(
        @{Name="Debloat Edge"; Action={
            Write-Host "Debloat Edge..." -ForegroundColor Yellow
            Get-AppxPackage *edge* | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like *edge* | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
            Write-Host "Edge debloated!" -ForegroundColor Green
        }}
        @{Name="Disable Background Apps"; Action={
            Write-Host "Disabling Background Apps..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable IPv6"; Action={
            Write-Host "Disabling IPv6..." -ForegroundColor Yellow
            Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
            Write-Host "IPv6 disabled!" -ForegroundColor Green
        }}
        @{Name="Disable Microsoft Copilot"; Action={
            Write-Host "Disabling Copilot..." -ForegroundColor Yellow
            New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Fullscreen Optimizations"; Action={
            Write-Host "Disabling Fullscreen Optimizations..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Teredo"; Action={
            Write-Host "Disabling Teredo..." -ForegroundColor Yellow
            netsh interface teredo set state disabled
            Write-Host "Teredo disabled!" -ForegroundColor Green
        }}
        @{Name="Disable Storage Sense"; Action={
            Write-Host "Disabling Storage Sense..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Remove OneDrive"; Action={
            Write-Host "Removing OneDrive..." -ForegroundColor Yellow
            taskkill /f /im OneDrive.exe -ErrorAction SilentlyContinue
            & "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall -ErrorAction SilentlyContinue
            Write-Host "OneDrive removed!" -ForegroundColor Green
        }}
        @{Name="Disable Windows Update Delivery Optimization"; Action={
            Write-Host "Disabling Delivery Optimization..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Windows Defender Real-time Protection (Caution)"; Action={
            Write-Host "Disabling Defender Real-time (Caution)..." -ForegroundColor Red
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
            Write-Host "Done! (Restart required)" -ForegroundColor Red
        }}
    )
    "Customize Preferences" = @(
        @{Name="Dark Theme for Windows"; Action={
            Write-Host "Enabling Dark Theme..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force
            Write-Host "Dark Theme enabled!" -ForegroundColor Green
        }}
        @{Name="Show Hidden Files"; Action={
            Write-Host "Showing Hidden Files..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Show File Extensions"; Action={
            Write-Host "Showing File Extensions..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Center Taskbar Items"; Action={
            Write-Host "Centering Taskbar Items..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Snap Assist Flyout"; Action={
            Write-Host "Disabling Snap Assist Flyout..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "EnableSnapAssistFlyout" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Snap Suggestions"; Action={
            Write-Host "Disabling Snap Suggestions..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SnapAssist" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Task View Button"; Action={
            Write-Host "Disabling Task View Button..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Search Button in Taskbar"; Action={
            Write-Host "Disabling Search Button..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
    )
}

# WPF GUI
$Window = New-Object Windows.Window
$Window.Title = "PMK Toolbox - ToiUuPC"
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
    [void]$InstallPanel.Children.Add($Label)

    foreach ($app in $Apps[$cat]) {
        $Check = New-Object Windows.Controls.CheckBox
        $Check.Content = $app.Name
        $Check.Tag = $app.Winget
        [void]$InstallPanel.Children.Add($Check)
    }
}

$InstallBtn = New-Object Windows.Controls.Button
$InstallBtn.Content = "Install Selected"
$InstallBtn.Add_Click({
    $selected = $InstallPanel.Children | Where-Object {$_ -is [Windows.Controls.CheckBox] -and $_.IsChecked}
    foreach ($cb in $selected) {
        Write-Host "Installing $($cb.Content)..." -ForegroundColor Yellow
        winget install --id $cb.Tag --accept-package-agreements --accept-source-agreements
        Write-Host "$($cb.Content) installation finished!" -ForegroundColor Green
    }
    [Windows.MessageBox]::Show("Install hoàn tất!")
})
[void]$InstallPanel.Children.Add($InstallBtn)

$InstallScroll.Content = $InstallPanel
$InstallTab.Content = $InstallScroll
[void]$TabControl.Items.Add($InstallTab)

# Tab Tweaks
$TweaksTab = New-Object Windows.Controls.TabItem
$TweaksTab.Header = "Tweaks"
$TweaksScroll = New-Object Windows.Controls.ScrollViewer
$TweaksGrid = New-Object Windows.Controls.Grid
$TweaksGrid.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition))
$TweaksGrid.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition))

$LeftPanel = New-Object Windows.Controls.StackPanel
foreach ($cat in @("Essential Tweaks", "Advanced Tweaks - CAUTION")) {
    $Label = New-Object Windows.Controls.Label
    $Label.Content = $cat
    $Label.FontSize = 16
    $Label.FontWeight = "Bold"
    [void]$LeftPanel.Children.Add($Label)

    foreach ($tweak in $Tweaks[$cat]) {
        $Check = New-Object Windows.Controls.CheckBox
        $Check.Content = $tweak.Name
        $Check.Tag = $tweak.Action
        [void]$LeftPanel.Children.Add($Check)
    }
}
[Windows.Controls.Grid]::SetColumn($LeftPanel, 0)
[void]$TweaksGrid.Children.Add($LeftPanel)

$RightPanel = New-Object Windows.Controls.StackPanel
foreach ($cat in @("Customize Preferences")) {
    $Label = New-Object Windows.Controls.Label
    $Label.Content = $cat
    $Label.FontSize = 16
    $Label.FontWeight = "Bold"
    [void]$RightPanel.Children.Add($Label)

    foreach ($tweak in $Tweaks[$cat]) {
        $Check = New-Object Windows.Controls.CheckBox
        $Check.Content = $tweak.Name
        $Check.Tag = $tweak.Action
        [void]$RightPanel.Children.Add($Check)
    }
}

$RunBtn = New-Object Windows.Controls.Button
$RunBtn.Content = "Run Tweaks"
$RunBtn.Add_Click({
    Write-Host "`n=== START APPLYING TWEAKS ===" -ForegroundColor Cyan
    $selected = $TweaksGrid.Children | ForEach-Object { $_.Children } | Where-Object {$_ -is [Windows.Controls.CheckBox] -and $_.IsChecked}
    
    if ($selected.Count -eq 0) {
        [Windows.MessageBox]::Show("No tweaks selected!")
        return
    }

    $count = 1
    foreach ($cb in $selected) {
        Write-Host "[$count/$($selected.Count)] Applying: $($cb.Content)" -ForegroundColor Yellow
        try {
            & $cb.Tag
            Write-Host "Success!" -ForegroundColor Green
        } catch {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
        $count++
    }

    Write-Host "`n=== ALL TWEAKS FINISHED! ===" -ForegroundColor Cyan
    [Windows.MessageBox]::Show("Tweaks applied!")
})
[void]$RightPanel.Children.Add($RunBtn)

[void]$TweaksGrid.Children.Add($RightPanel)
[Windows.Controls.Grid]::SetColumn($RightPanel, 1)

$TweaksScroll.Content = $TweaksGrid
$TweaksTab.Content = $TweaksScroll
[void]$TabControl.Items.Add($TweaksTab)

$Window.Content = $TabControl
[void]$Window.ShowDialog()
