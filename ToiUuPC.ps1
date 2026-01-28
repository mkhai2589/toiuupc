# ToiUuPC.ps1 - Công cụ tối ưu Windows (Tổng hợp WinUtil + Win11Debloat + Sophia)
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Thuthuatwiki (PMK)

# Giữ console mở logo trước khi load GUI
Clear-Host

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

# Danh sách ứng dụng (giữ nguyên)
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

# Tweaks mở rộng đầy đủ từ WinUtil + yêu cầu của bạn
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
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "AllowTelemetry" -Value 0 -Type DWord -Force
            Write-Host "Telemetry disabled!" -ForegroundColor Green
        }}
        @{Name="Disable Consumer Features"; Action={
            Write-Host "Disabling Consumer Features..." -ForegroundColor Yellow
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Bing Search in Start Menu"; Action={
            Write-Host "Disabling Bing Search..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "BingSearchEnabled" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Activity History"; Action={
            Write-Host "Disabling Activity History..." -ForegroundColor Yellow
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "EnableActivityFeed" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Hibernation"; Action={
            Write-Host "Disabling Hibernation..." -ForegroundColor Yellow
            powercfg -h off
            Write-Host "Hibernation disabled! Restart to delete hiberfil.sys" -ForegroundColor Green
        }}
        @{Name="Disable Location Tracking"; Action={
            Write-Host "Disabling Location Tracking..." -ForegroundColor Yellow
            $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "Value" -Value "Deny" -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable GameDVR"; Action={
            Write-Host "Disabling GameDVR..." -ForegroundColor Yellow
            $path = "HKCU:\System\GameConfigStore"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Cortana"; Action={
            Write-Host "Disabling Cortana..." -ForegroundColor Yellow
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "AllowCortana" -Value 0 -Type DWord -Force
            Write-Host "Cortana disabled!" -ForegroundColor Green
        }}
        @{Name="Disable Advertising ID"; Action={
            Write-Host "Disabling Advertising ID..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "Enabled" -Value 0 -Type DWord -Force
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
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "GlobalUserDisabled" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable IPv6"; Action={
            Write-Host "Disabling IPv6..." -ForegroundColor Yellow
            Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
            Write-Host "IPv6 disabled!" -ForegroundColor Green
        }}
        @{Name="Disable Microsoft Copilot"; Action={
            Write-Host "Disabling Copilot..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Fullscreen Optimizations"; Action={
            Write-Host "Disabling Fullscreen Optimizations..." -ForegroundColor Yellow
            $path = "HKCU:\System\GameConfigStore"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Teredo"; Action={
            Write-Host "Disabling Teredo..." -ForegroundColor Yellow
            netsh interface teredo set state disabled
            Write-Host "Teredo disabled!" -ForegroundColor Green
        }}
        @{Name="Disable Storage Sense"; Action={
            Write-Host "Disabling Storage Sense..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "01" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Remove OneDrive"; Action={
            Write-Host "Removing OneDrive..." -ForegroundColor Yellow
            Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
            & "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall -ErrorAction SilentlyContinue
            Write-Host "OneDrive removed!" -ForegroundColor Green
        }}
        @{Name="Disable Windows Update Delivery Optimization"; Action={
            Write-Host "Disabling Delivery Optimization..." -ForegroundColor Yellow
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "DODownloadMode" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable News and Interests"; Action={
            Write-Host "Disabling News and Interests..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds\ShellFeedsTaskbarViewMode"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Widgets (Win11)"; Action={
            Write-Host "Disabling Widgets (Win11)..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "TaskbarDa" -Value 0 -Type DWord -Force
            Write-Host "Widgets disabled!" -ForegroundColor Green
        }}
        @{Name="Disable Clipboard History"; Action={
            Write-Host "Disabling Clipboard History..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Clipboard"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "EnableClipboardHistory" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Windows Ink Workspace"; Action={
            Write-Host "Disabling Windows Ink..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PenWorkspace"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "PenWorkspaceButtonDesiredVisibility" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Set Verbose Messages During Logon"; Action={
            Write-Host "Enabling Verbose Messages..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "VerboseStatus" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Hide Recommended Section in Start"; Action={
            Write-Host "Hiding Recommended Section..." -ForegroundColor Yellow
            $path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "HideRecommendedSection" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Enable New Outlook Migration"; Action={
            Write-Host "Enabling New Outlook..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Preferences"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "UseNewOutlook" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Detailed BSoD"; Action={
            Write-Host "Enabling Detailed BSoD..." -ForegroundColor Yellow
            $path = "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "DisplayParameters" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="S3 Sleep"; Action={
            Write-Host "Enabling S3 Sleep..." -ForegroundColor Yellow
            powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0
            powercfg /setactive SCHEME_CURRENT
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Cross-Device Resume"; Action={
            Write-Host "Enabling Cross-Device Resume..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "IsResumeAllowed" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
    )
    "Customize Preferences" = @(
        @{Name="Dark Theme for Windows"; Action={
            Write-Host "Enabling Dark Theme..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $path -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force
            Write-Host "Dark Theme enabled!" -ForegroundColor Green
        }}
        @{Name="Show Hidden Files"; Action={
            Write-Host "Showing Hidden Files..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "Hidden" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Show File Extensions"; Action={
            Write-Host "Showing File Extensions..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "HideFileExt" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Center Taskbar Items"; Action={
            Write-Host "Centering Taskbar Items..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "TaskbarAl" -Value 1 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Snap Assist Flyout"; Action={
            Write-Host "Disabling Snap Assist Flyout..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "EnableSnapAssistFlyout" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Disable Snap Suggestions"; Action={
            Write-Host "Disabling Snap Suggestions..." -ForegroundColor Yellow
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "SnapAssist" -Value 0 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="NumLock on Startup"; Action={
            Write-Host "Enabling NumLock on Startup..." -ForegroundColor Yellow
            Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Value 2 -Type DWord -Force
            Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Value 2 -Type DWord -Force
            Write-Host "Done!" -ForegroundColor Green
        }}
        @{Name="Verbose Messages During Logon"; Action={
            Write-Host "Enabling Verbose Messages..." -ForegroundColor Yellow
            $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "VerboseStatus" -Value 1 -Type DWord -Force
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
