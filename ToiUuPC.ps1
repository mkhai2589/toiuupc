# ToiUuPC.ps1 - PMK Toolbox v3.0 (Modular & Remote Compatible)
# Run: irm bit.ly/pmktool | iex
# Author: Thuthuatwiki (PMK) - Enhanced by Grok with global repos
# Version: 3.0 - Full tweaks, debloat, updates control, OOBE

Clear-Host

# Kiểm tra & relaunch admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# Kiểm tra mode: Local hay Remote
$scriptRoot = $PSScriptRoot
if ($scriptRoot) {
    # Local: dot-source functions
    . "$scriptRoot\functions\show-pmklogo.ps1"
    . "$scriptRoot\functions\utils.ps1"
    . "$scriptRoot\functions\install-apps.ps1"
    . "$scriptRoot\functions\dns-management.ps1"
    . "$scriptRoot\functions\tweaks.ps1"
} else {
    # Remote fallback: Hardcode essential functions
    function Show-PMKLogo {
        $logo = @"
╔══════════════════════════════════════════════════════════════════════════╗
║ ██████╗ ███╗ ███╗██╗ ██╗ ████████╗ ██████╗ ██████╗ ██╗ ║
║ ██╔══██╗████╗ ████║██║ ██╔╝ ╚══██╔══╝██╔═══██╗██╔═══██╗██║ ║
║ ██████╔╝██╔████╔██║█████╔╝ ██║ ██║ ██║██║ ██║██║ ║
║ ██╔═══╝ ██║╚██╔╝██║██╔═██╗ ██║ ██║ ██║██║ ██║██║ ║
║ ██║ ██║ ╚═╝ ██║██║ ██╗ ██║ ╚██████╔╝╚██████╔╝███████╗ ║
║ ╚═╝ ╚═╝ ╚═╝╚═╝ ╚═╝ ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝ ║
║ PMK Toolbox - Tối ưu Windows ║
║ Phiên bản: 3.0 | Windows 10/11 ║
╚══════════════════════════════════════════════════════════════════════════╝
"@
        Write-Host $logo -ForegroundColor Cyan
    }
    Write-Host "`nChế độ Remote: Giới hạn. Tải repo để dùng đầy đủ." -ForegroundColor Yellow
    # Hardcode basic utils/tweaks if needed (minimal)
}

Show-PMKLogo

Write-Host "`nPMK Toolbox v3.0 - Modular Edition" -ForegroundColor Cyan
Write-Host "Đang tải cấu hình..." -ForegroundColor Yellow

# Load WPF với timeout (từ code cũ tối ưu)
try {
    $loadJob = [PowerShell]::Create().AddScript({
        Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
    })
    $handle = $loadJob.BeginInvoke()
    $timeout = 10000; $start = Get-Date
    while (-not $handle.IsCompleted) {
        if (((Get-Date) - $start).TotalMilliseconds -gt $timeout) { $loadJob.Stop(); throw "Timeout load WPF" }
        Start-Sleep 100
    }
    $loadJob.EndInvoke($handle); $loadJob.Dispose()
} catch {
    Write-Host "⚠️ WPF load error: $_. Fallback: " -ForegroundColor Yellow
    try { [Reflection.Assembly]::LoadWithPartialName('PresentationFramework') | Out-Null } catch { throw "No WPF" }
}

# Tạo GUI (từ code cũ + virtualizing, background jobs)
function Create-MainWindow {
    $Window = New-Object Windows.Window
    $Window.Title = "PMK Toolbox - Tối ưu Windows"
    $Window.Width = 1200
    $Window.Height = 750
    $Window.WindowStartupLocation = "CenterScreen"
    $Window.Background = [Windows.Media.Brushes]::WhiteSmoke
    $Window.FontFamily = "Segoe UI"

    $MainGrid = New-Object Windows.Controls.Grid

    # Header
    $HeaderText = New-Object Windows.Controls.TextBlock
    $HeaderText.Text = "PMK TOOLBOX - TỐI ƯU WINDOWS"
    $HeaderText.FontSize = 24
    $HeaderText.FontWeight = "Bold"
    $HeaderText.Foreground = [Windows.Media.Brushes]::DarkBlue
    $HeaderText.HorizontalAlignment = "Center"
    $HeaderText.Margin = "0,10,0,10"

    # Tab Control
    $TabControl = New-Object Windows.Controls.TabControl
    $TabControl.Margin = "10"

    # Tab Install (virtualizing)
    $TabInstall = New-Object Windows.Controls.TabItem
    $TabInstall.Header = "📦 CÀI ĐẶT ỨNG DỤNG"

    $InstallScroll = New-Object Windows.Controls.ScrollViewer
    $InstallScroll.VerticalScrollBarVisibility = "Auto"

    $VirtualInstallStack = New-Object Windows.Controls.VirtualizingStackPanel
    $VirtualInstallStack.Margin = "10"

    $global:SelectedApps = @{}

    $appsJson = Get-Content "$scriptRoot\config\applications.json" -Raw | ConvertFrom-Json
    foreach ($category in $appsJson.PSObject.Properties.Name) {
        $CategoryGroup = New-Object Windows.Controls.Expander
        $CategoryGroup.Header = $category
        $CategoryGroup.IsExpanded = $false
        $CategoryGroup.Margin = "0,0,0,5"

        $AppPanel = New-Object Windows.Controls.WrapPanel
        $AppPanel.Margin = "10,5,10,5"

        foreach ($app in $appsJson.$category) {
            $AppButton = New-Object Windows.Controls.Button
            $AppButton.Content = "$($app.Icon) $($app.Name)"
            $AppButton.Tag = $app.Winget
            $AppButton.Margin = "5"
            $AppButton.Padding = "10,5"
            $AppButton.Background = [Windows.Media.Brushes]::White
            $AppButton.BorderBrush = [Windows.Media.Brushes]::LightGray

            $AppButton.Add_Click({
                $button = $sender
                $appId = $button.Tag
                if ($global:SelectedApps.ContainsKey($appId)) {
                    $button.Background = [Windows.Media.Brushes]::White
                    $global:SelectedApps.Remove($appId)
                } else {
                    $button.Background = [Windows.Media.Brushes]::LightGreen
                    $global:SelectedApps[$appId] = $true
                }
            })

            $AppPanel.Children.Add($AppButton)
        }

        $CategoryGroup.Content = $AppPanel
        $VirtualInstallStack.Children.Add($CategoryGroup)
    }

    $InstallButton = New-Object Windows.Controls.Button
    $InstallButton.Content = "🚀 CÀI ĐẶT ỨNG DỤNG ĐÃ CHỌN"
    $InstallButton.FontSize = 14
    $InstallButton.FontWeight = "Bold"
    $InstallButton.Height = 40
    $InstallButton.Margin = "0,20,0,0"
    $InstallButton.Background = [Windows.Media.Brushes]::Green
    $InstallButton.Foreground = [Windows.Media.Brushes]::White

    if (-not (Test-Winget)) {
        $InstallButton.IsEnabled = $false
        $InstallButton.Content = "⚠️ WINGET CHƯA CÀI ĐẶT"
        $InstallButton.Background = [Windows.Media.Brushes]::Gray
    }

    $InstallButton.Add_Click({
        if ($global:SelectedApps.Count -eq 0) { [Windows.MessageBox]::Show("Chọn ít nhất một app!", "Thông báo"); return }
        $result = [Windows.MessageBox]::Show("Cài $($global:SelectedApps.Count) app?", "Xác nhận", "YesNo", "Question")
        if ($result -eq "Yes") {
            $this.IsEnabled = $false
            $this.Content = "⏳ ĐANG CÀI..."
            $job = Start-Job -ScriptBlock {
                foreach ($appId in $using:global:SelectedApps.Keys) {
                    winget install --id $appId --silent --accept-package-agreements --accept-source-agreements
                }
            }
            Wait-Job $job
            Receive-Job $job
            [Windows.MessageBox]::Show("Cài xong!", "Thành công")
            $this.Content = "🚀 CÀI ĐẶT ỨNG DỤNG ĐÃ CHỌN"
            $this.IsEnabled = $true
        }
    })

    $VirtualInstallStack.Children.Add($InstallButton)
    $InstallScroll.Content = $VirtualInstallStack
    $TabInstall.Content = $InstallScroll
    $TabControl.Items.Add($TabInstall)

    # Tab Tweaks (tương tự, thêm từ tweaks.ps1)
    $TabTweaks = New-Object Windows.Controls.TabItem
    $TabTweaks.Header = "⚙️ TỐI ƯU HỆ THỐNG"

    $TweakScroll = New-Object Windows.Controls.ScrollViewer
    $TweakScroll.VerticalScrollBarVisibility = "Auto"

    $TweakStack = New-Object Windows.Controls.StackPanel
    $TweakStack.Margin = "10"

    $global:SelectedTweaks = @{}

    $tweaksJson = Get-Content "$scriptRoot\config\tweaks.json" -Raw | ConvertFrom-Json
    foreach ($category in $tweaksJson.PSObject.Properties.Name) {
        $CategoryGroup = New-Object Windows.Controls.Expander
        $CategoryGroup.Header = $category
        $CategoryGroup.IsExpanded = $false
        $CategoryGroup.Margin = "0,0,0,5"

        $TweakPanel = New-Object Windows.Controls.StackPanel
        $TweakPanel.Margin = "10,5,10,5"

        foreach ($tweak in $tweaksJson.$category) {
            $CheckBox = New-Object Windows.Controls.CheckBox
            $CheckBox.Content = $tweak.Name
            $CheckBox.FontSize = 13
            $CheckBox.Margin = "5"
            $CheckBox.Tag = $tweak

            $CheckBox.Add_Checked({ $global:SelectedTweaks[$this.Content] = $this.Tag })
            $CheckBox.Add_Unchecked({ $global:SelectedTweaks.Remove($this.Content) })

            $TweakPanel.Children.Add($CheckBox)
        }

        $CategoryGroup.Content = $TweakPanel
        $TweakStack.Children.Add($CategoryGroup)
    }

    $ExecuteTweaksButton = New-Object Windows.Controls.Button
    $ExecuteTweaksButton.Content = "⚡ ÁP DỤNG TWEAKS ĐÃ CHỌN"
    $ExecuteTweaksButton.FontSize = 14
    $ExecuteTweaksButton.FontWeight = "Bold"
    $ExecuteTweaksButton.Height = 40
    $ExecuteTweaksButton.Margin = "0,20,0,0"
    $ExecuteTweaksButton.Background = [Windows.Media.Brushes]::Orange
    $ExecuteTweaksButton.Foreground = [Windows.Media.Brushes]::White

    $ExecuteTweaksButton.Add_Click({
        if ($global:SelectedTweaks.Count -eq 0) { [Windows.MessageBox]::Show("Chọn ít nhất một tweak!", "Thông báo"); return }
        $result = [Windows.MessageBox]::Show("Áp dụng $($global:SelectedTweaks.Count) tweak?", "Xác nhận", "YesNo", "Warning")
        if ($result -eq "Yes") {
            $this.IsEnabled = $false
            $this.Content = "⏳ ĐANG ÁP DỤNG..."
            Invoke-Tweaks -SelectedTweaks $global:SelectedTweaks
            [Windows.MessageBox]::Show("Áp dụng xong!", "Thành công")
            $this.Content = "⚡ ÁP DỤNG TWEAKS ĐÃ CHỌN"
            $this.IsEnabled = $true
        }
    })

    $TweakStack.Children.Add($ExecuteTweaksButton)
    $TweakScroll.Content = $TweakStack
    $TabTweaks.Content = $TweakScroll
    $TabControl.Items.Add($TabTweaks)

    # Tab DNS (tương tự code cũ)
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
    $dnsJson = Get-Content "$scriptRoot\config\dns.json" -Raw | ConvertFrom-Json
    $DNSComboBox.ItemsSource = $dnsJson.PSObject.Properties.Name
    $DNSComboBox.SelectedIndex = 0

    $ApplyDNSButton = New-Object Windows.Controls.Button
    $ApplyDNSButton.Content = "ÁP DỤNG DNS"
    $ApplyDNSButton.FontSize = 14
    $ApplyDNSButton.FontWeight = "Bold"
    $ApplyDNSButton.Width = 150
    $ApplyDNSButton.Height = 40
    $ApplyDNSButton.Margin = "0,20,0,0"
    $ApplyDNSButton.Background = [Windows.Media.Brushes]::Blue
    $ApplyDNSButton.Foreground = [Windows.Media.Brushes]::White

    $ApplyDNSButton.Add_Click({
        $selected = $DNSComboBox.SelectedValue
        if ($selected) {
            $this.IsEnabled = $false
            $this.Content = "ĐANG ÁP DỤNG..."
            $job = Start-Job -ScriptBlock { Set-DNSServer -DNSServerName $using:selected }
            Wait-Job $job
            $result = Receive-Job $job
            [Windows.MessageBox]::Show($result, "Kết quả")
            $this.Content = "ÁP DỤNG DNS"
            $this.IsEnabled = $true
        }
    })

    $DNSStack.Children.Add($DNSText)
    $DNSStack.Children.Add($DNSComboBox)
    $DNSStack.Children.Add($ApplyDNSButton)
    $TabDNS.Content = $DNSStack
    $TabControl.Items.Add($TabDNS)

    # Tab Info (từ code cũ)
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
        $InfoText.Text = Get-SystemInfoText
    })

    $InfoStack.Children.Add($InfoText)
    $InfoStack.Children.Add($RefreshButton)
    $TabInfo.Content = $InfoStack
    $TabControl.Items.Add($TabInfo)

    # Footer
    $FooterPanel = New-Object Windows.Controls.StackPanel
    $FooterPanel.Orientation = "Horizontal"
    $FooterPanel.HorizontalAlignment = "Center"
    $FooterPanel.Margin = "0,10,0,10"

    $RestartButton = New-Object Windows.Controls.Button
    $RestartButton.Content = "🔄 KHỞI ĐỘNG LẠI"
    $RestartButton.Width = 150
    $RestartButton.Height = 40
    $RestartButton.Margin = "10"
    $RestartButton.Background = [Windows.Media.Brushes]::OrangeRed

    $RestartButton.Add_Click({
        $result = [Windows.MessageBox]::Show("Khởi động lại?", "Xác nhận", "YesNo", "Question")
        if ($result -eq "Yes") { Restart-Computer -Force }
    })

    $ExitButton = New-Object Windows.Controls.Button
    $ExitButton.Content = "❌ THOÁT"
    $ExitButton.Width = 150
    $ExitButton.Height = 40
    $ExitButton.Margin = "10"
    $ExitButton.Background = [Windows.Media.Brushes]::Red
    $ExitButton.Foreground = [Windows.Media.Brushes]::White

    $ExitButton.Add_Click({
        $Window.Close()
    })

    $FooterPanel.Children.Add($RestartButton)
    $FooterPanel.Children.Add($ExitButton)

    # Layout
    $MainGrid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height = "Auto"}))
    $MainGrid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition))
    $MainGrid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height = "Auto"}))

    [Windows.Controls.Grid]::SetRow($HeaderText, 0)
    [Windows.Controls.Grid]::SetRow($TabControl, 1)
    [Windows.Controls.Grid]::SetRow($FooterPanel, 2)

    $MainGrid.Children.Add($HeaderText)
    $MainGrid.Children.Add($TabControl)
    $MainGrid.Children.Add($FooterPanel)

    $Window.Content = $MainGrid
    return $Window
}

# Main execution
try {
    $mainWindow = Create-MainWindow
    $mainWindow.ShowDialog() | Out-Null
} catch {
    Write-Host "❌ GUI error: $_. Fallback console." -ForegroundColor Red
    Show-ConsoleMenu
}

function Show-ConsoleMenu {
    do {
        Clear-Host
        Show-PMKLogo
        Write-Host "`n=== MENU DÒNG LỆNH ===" -ForegroundColor Green
        Write-Host "1. Thông tin hệ thống"
        Write-Host "2. Cài ứng dụng"
        Write-Host "3. Áp dụng tweaks"
        Write-Host "4. Quản lý DNS"
        Write-Host "5. Thoát"
        $choice = Read-Host "Chọn (1-5)"
        switch ($choice) {
            "1" { Get-SystemInfoText | Write-Host -ForegroundColor Cyan; Pause }
            "2" { Install-SelectedApps; Pause }
            "3" { Invoke-TweaksMenu; Pause }
            "4" { Set-DNSServerMenu; Pause }
            "5" { exit }
            default { Write-Host "Sai!"; Start-Sleep 1 }
        }
    } while ($choice -ne "5")
}
