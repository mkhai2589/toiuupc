# ToiUuPC.ps1 - Tổng hợp WinUtil + Win11Debloat + Sophia + Debloater
# Run: irm https://raw.githubusercontent.com/yourusername/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Thuthuatwiki (inspired by ChrisTitusTech, Raphire, Sophia, Sycnex)

# Self-elevate to Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
    exit;
}

# Dependencies check (winget auto on Win11, fallback choco)
if (!(Get-Command winget -ErrorAction SilentlyContinue)) { Write-Warning "Winget not found - install from MS Store"; }

# Embed apps list from winutil applications.json (excerpt - expand full from raw)
$Apps = @{
    "Browsers" = @(
        @{Name="Brave"; Winget="Brave.Brave"; Choco="brave"},
        @{Name="Chrome"; Winget="Google.Chrome"; Choco="googlechrome"},
        @{Name="Firefox"; Winget="Mozilla.Firefox"; Choco="firefox"},
        @{Name="LibreWolf"; Winget="LibreWolf.LibreWolf"},
        @{Name="Vivaldi"; Winget="Vivaldi.Vivaldi"},
        @{Name="Ungoogled Chromium"; Winget="eloston.ungoogled-chromium"}
        # Add full from https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/config/applications.json
    )
    "Communications" = @(
        @{Name="Discord"; Winget="Discord.Discord"},
        @{Name="Signal"; Winget="OpenWhisperSystems.Signal"},
        @{Name="Telegram"; Winget="Telegram.TelegramDesktop"},
        @{Name="Teams"; Winget="Microsoft.Teams"},
        @{Name="Thunderbird"; Winget="Mozilla.Thunderbird"}
    )
    "Development" = @(
        @{Name="VS Code"; Winget="Microsoft.VisualStudioCode"},
        @{Name="Git"; Winget="Git.Git"},
        @{Name="Docker Desktop"; Winget="Docker.DockerDesktop"},
        @{Name="Python 3"; Winget="Python.Python.3"}
        # Add more
    )
    # Add other categories: Multimedia, Games, Utilities...
}

# Tweaks list (từ winutil tweaks.json + Win11Debloat + Debloater + Sophia)
$Tweaks = @{
    "Privacy" = @(
        @{Name="Disable Telemetry"; Action={Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord}}
        @{Name="Disable Location"; Action={Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny"}}
        @{Name="Disable Cortana"; Action={Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0}}
        @{Name="Disable Ads"; Action={Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0}}
    )
    "Debloat" = @(
        @{Name="Remove Bloat Apps"; Action={
            $Bloat = @("Microsoft.BingNews", "Microsoft.GetHelp", "Microsoft.Getstarted", "Clipchamp.Clipchamp", "Microsoft.Copilot", "Microsoft.YourPhone", "Microsoft.ZuneMusic")
            foreach ($app in $Bloat) {
                Get-AppxPackage *$app* | Remove-AppxPackage
                Get-AppxProvisionedPackage -Online | Where DisplayName -like *$app* | Remove-AppxProvisionedPackage -Online
            }
        }}
    )
    "Performance" = @(
        @{Name="Disable Hibernation"; Action={powercfg -h off}}
        @{Name="Services Manual"; Action={
            $Services = @("DiagTrack", "dmwappushservice", "SysMain")
            foreach ($svc in $Services) { Set-Service $svc -StartupType Manual -ErrorAction SilentlyContinue }
        }}
    )
    # Add more: UI (taskbar left, classic menu), OneDrive uninstall, etc.
}

# WPF GUI (giống winutil)
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$Window = New-Object Windows.Window
$Window.Title = "ToiUuPC - Tổng hợp WinUtil/Debloat/Sophia"
$Window.Width = 1200
$Window.Height = 800
$Window.WindowStartupLocation = "CenterScreen"

$TabControl = New-Object Windows.Controls.TabControl
$TabControl.HorizontalAlignment = "Stretch"
$TabControl.VerticalAlignment = "Stretch"

# Tab Install
$InstallTab = New-Object Windows.Controls.TabItem
$InstallTab.Header = "Install"
$InstallGrid = New-Object Windows.Controls.Grid
$ScrollViewer = New-Object Windows.Controls.ScrollViewer
$StackPanel = New-Object Windows.Controls.StackPanel

foreach ($cat in $Apps.Keys) {
    $Label = New-Object Windows.Controls.Label
    $Label.Content = $cat
    $Label.FontSize = 16
    $Label.FontWeight = "Bold"
    $StackPanel.Children.Add($Label)

    foreach ($app in $Apps[$cat]) {
        $Check = New-Object Windows.Controls.CheckBox
        $Check.Content = $app.Name
        $Check.Tag = $app.Winget
        $StackPanel.Children.Add($Check)
    }
}

$InstallButton = New-Object Windows.Controls.Button
$InstallButton.Content = "Install Selected"
$InstallButton.Add_Click({
    $Selected = $StackPanel.Children | Where-Object {$_ -is [Windows.Controls.CheckBox] -and $_.IsChecked}
    foreach ($cb in $Selected) {
        winget install --id $cb.Tag --silent --accept-package-agreements --accept-source-agreements
    }
    [Windows.MessageBox]::Show("Install hoàn tất!")
})
$StackPanel.Children.Add($InstallButton)

$ScrollViewer.Content = $StackPanel
$InstallGrid.Children.Add($ScrollViewer)
$InstallTab.Content = $InstallGrid
$TabControl.Items.Add($InstallTab)

# Tab Tweaks (tương tự, checkboxes cho $Tweaks)
$TweaksTab = New-Object Windows.Controls.TabItem
$TweaksTab.Header = "Tweaks"
$TweaksPanel = New-Object Windows.Controls.StackPanel
foreach ($cat in $Tweaks.Keys) {
    $Label = New-Object Windows.Controls.Label
    $Label.Content = $cat
    $TweaksPanel.Children.Add($Label)
    foreach ($tweak in $Tweaks[$cat]) {
        $Check = New-Object Windows.Controls.CheckBox
        $Check.Content = $tweak.Name
        $Check.Tag = $tweak.Action
        $TweaksPanel.Children.Add($Check)
    }
}
$ApplyTweaks = New-Object Windows.Controls.Button
$ApplyTweaks.Content = "Apply Selected Tweaks"
$ApplyTweaks.Add_Click({
    $SelectedTweaks = $TweaksPanel.Children | Where {$_ -is [Windows.Controls.CheckBox] -and $_.IsChecked}
    foreach ($cb in $SelectedTweaks) { & $cb.Tag }
    [Windows.MessageBox]::Show("Tweaks áp dụng!")
})
$TweaksPanel.Children.Add($ApplyTweaks)
$TweaksTab.Content = $TweaksPanel
$TabControl.Items.Add($TweaksTab)

# Tab Config (save/load preset JSON)
$ConfigTab = New-Object Windows.Controls.TabItem
$ConfigTab.Header = "Config"
# Add buttons Save Preset, Load Preset (use ConvertTo-Json for selected)

$Window.Content = $TabControl
$Window.ShowDialog() | Out-Null
