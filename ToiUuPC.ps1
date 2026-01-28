# ToiUuPC.ps1 - PMK Toolbox v3.0 (Modular & Remote Compatible)
# Run: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex
# Author: Thuthuatwiki (PMK) - Enhanced with WinUtil style tabs
# Version: 3.0 - Full install tab, tweaks, debloat ready

Clear-Host

# Kiểm tra & relaunch admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ProgressPreference = 'SilentlyContinue'

# Logo function (hardcode cho remote)
function Show-PMKLogo {
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
}

# Kiểm tra mode: Local hay Remote
$scriptRoot = $PSScriptRoot
if ($scriptRoot) {
    # Local mode: dot-source functions nếu tồn tại
    $functionsPath = "$scriptRoot\functions"
    if (Test-Path $functionsPath) {
        Get-ChildItem $functionsPath -Filter "*.ps1" | ForEach-Object {
            . $_.FullName -ErrorAction SilentlyContinue
        }
        Write-Host "Local mode: Đã load functions" -ForegroundColor Green
    } else {
        Write-Host "Local mode: Thiếu folder functions/" -ForegroundColor Yellow
    }
} else {
    # Remote mode: Hardcode minimum functions + console fallback
    Write-Host "`nChế độ Remote: Giới hạn console cơ bản (GUI đầy đủ chỉ khi chạy local)" -ForegroundColor Yellow

    function Test-Winget { try { winget --version | Out-Null; $true } catch { $false } }
    function Get-SystemInfoText { "Remote mode: Không lấy info đầy đủ. Tải repo để dùng GUI." }

    # Menu console remote
    do {
        Clear-Host
        Show-PMKLogo
        Write-Host "`n=== MENU REMOTE CƠ BẢN ===" -ForegroundColor Green
        Write-Host "1. Kiểm tra Winget"
        Write-Host "2. Thông tin hệ thống (cơ bản)"
        Write-Host "3. Thoát"
        $choice = Read-Host "Chọn (1-3)"

        switch ($choice) {
            "1" { if (Test-Winget) { Write-Host "Winget OK" -ForegroundColor Green } else { Write-Host "Winget chưa cài" -ForegroundColor Red }; Pause }
            "2" { Write-Host (Get-SystemInfoText) -ForegroundColor Cyan; Pause }
            "3" { exit }
            default { Write-Host "Lựa chọn sai!" -ForegroundColor Red; Start-Sleep 1 }
        }
    } while ($choice -ne "3")
    exit  # Thoát ngay ở remote để tránh crash GUI
}

Show-PMKLogo
Write-Host "`nPMK Toolbox v3.0 - Modular Edition" -ForegroundColor Cyan
Write-Host "Đang khởi tạo..." -ForegroundColor Yellow

# Load WPF với fallback
try {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms -ErrorAction Stop
} catch {
    Write-Host "⚠️ Không load được WPF: $_. Chuyển sang console." -ForegroundColor Yellow
    Show-ConsoleMenu
    exit
}

# Hàm tạo GUI chính (tab Cài App Nhanh hoàn chỉnh)
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

    # Tab 1: Cài App Nhanh (hoàn chỉnh với categories)
    $TabInstall = New-Object Windows.Controls.TabItem
    $TabInstall.Header = "📦 Cài App Nhanh"

    $InstallScroll = New-Object Windows.Controls.ScrollViewer
    $InstallScroll.VerticalScrollBarVisibility = "Auto"

    $VirtualInstallStack = New-Object Windows.Controls.VirtualizingStackPanel
    $VirtualInstallStack.Margin = "10"

    $global:SelectedApps = @{}

    # Load apps từ config (fallback nếu không có)
    $appsPath = "$scriptRoot\config\applications.json"
    if (Test-Path $appsPath) {
        $appsJson = Get-Content $appsPath -Raw | ConvertFrom-Json
    } else {
        # Fallback data nếu config thiếu
        $appsJson = [PSCustomObject]@{
            "Browsers" = @(
                [PSCustomObject]@{Name="Brave"; Winget="Brave.Brave"; Icon="🚀"},
                [PSCustomObject]@{Name="Chrome"; Winget="Google.Chrome"; Icon="🔍"},
                [PSCustomObject]@{Name="Firefox"; Winget="Mozilla.Firefox"; Icon="🦊"}
            )
            "Communications" = @(
                [PSCustomObject]@{Name="Discord"; Winget="Discord.Discord"; Icon="🎮"},
                [PSCustomObject]@{Name="Telegram"; Winget="Telegram.TelegramDesktop"; Icon="✈️"}
            )
            "Development" = @(
                [PSCustomObject]@{Name="VS Code"; Winget="Microsoft.VisualStudioCode"; Icon="📝"},
                [PSCustomObject]@{Name="Git"; Winget="Git.Git"; Icon="🌿"}
            )
            "Document" = @(
                [PSCustomObject]@{Name="LibreOffice"; Winget="TheDocumentFoundation.LibreOffice"; Icon="📑"}
            )
            "Microsoft Tools" = @(
                [PSCustomObject]@{Name="PowerToys"; Winget="Microsoft.PowerToys"; Icon="🛠️"},
                [PSCustomObject]@{Name="Windows Terminal"; Winget="Microsoft.WindowsTerminal"; Icon="⌨️"}
            )
            "Utilities" = @(
                [PSCustomObject]@{Name="7-Zip"; Winget="7zip.7zip"; Icon="🗜️"},
                [PSCustomObject]@{Name="Everything"; Winget="voidtools.Everything"; Icon="🔎"}
            )
        }
    }

    foreach ($category in $appsJson.PSObject.Properties.Name) {
        $CategoryGroup = New-Object Windows.Controls.Expander
        $CategoryGroup.Header = $category
        $CategoryGroup.IsExpanded = $false
        $CategoryGroup.Margin = "0,0,0,5"

        $AppPanel = New-Object Windows.Controls.WrapPanel
        $AppPanel.Margin = "10,5,10,5"

        foreach ($app in $appsJson.$category) {
            $AppCheckBox = New-Object Windows.Controls.CheckBox
            $AppCheckBox.Content = "$($app.Icon) $($app.Name)"
            $AppCheckBox.Tag = $app.Winget
            $AppCheckBox.Margin = "5"
            $AppCheckBox.FontSize = 14

            $AppCheckBox.Add_Checked({ $global:SelectedApps[$this.Tag] = $true })
            $AppCheckBox.Add_Unchecked({ $global:SelectedApps.Remove($this.Tag) })

            $AppPanel.Children.Add($AppCheckBox)
        }

        $CategoryGroup.Content = $AppPanel
        $VirtualInstallStack.Children.Add($CategoryGroup)
    }

    $InstallButton = New-Object Windows.Controls.Button
    $InstallButton.Content = "🚀 Cài Đặt Ứng Dụng Đã Chọn"
    $InstallButton.FontSize = 16
    $InstallButton.FontWeight = "Bold"
    $InstallButton.Height = 50
    $InstallButton.Margin = "0,20,0,0"
    $InstallButton.Background = [Windows.Media.Brushes]::ForestGreen
    $InstallButton.Foreground = [Windows.Media.Brushes]::White

    if (-not (Test-Winget)) {
        $InstallButton.IsEnabled = $false
        $InstallButton.Content = "⚠️ Winget Chưa Cài Đặt"
        $InstallButton.Background = [Windows.Media.Brushes]::Gray
    }

    $InstallButton.Add_Click({
        if ($global:SelectedApps.Count -eq 0) {
            [Windows.MessageBox]::Show("Vui lòng chọn ít nhất một ứng dụng!", "Thông báo", "OK", "Information")
            return
        }

        $result = [Windows.MessageBox]::Show("Cài đặt $($global:SelectedApps.Count) ứng dụng?", "Xác nhận", "YesNo", "Question")
        if ($result -eq "Yes") {
            $this.IsEnabled = $false
            $this.Content = "⏳ Đang cài đặt..."

            $progress = 0
            $total = $global:SelectedApps.Count

            foreach ($appId in $global:SelectedApps.Keys) {
                $progress++
                $percent = [math]::Round(($progress / $total) * 100)
                $this.Content = "⏳ $progress/$total ($percent%)"

                try {
                    winget install --id $appId --silent --accept-package-agreements --accept-source-agreements
                } catch {
                    [Windows.MessageBox]::Show("Lỗi cài $appId : $_", "Lỗi")
                }
            }

            $this.Content = "✅ Hoàn tất cài đặt!"
            Start-Sleep -Seconds 2
            $this.Content = "🚀 Cài Đặt Ứng Dụng Đã Chọn"
            $this.IsEnabled = $true
        }
    })

    $VirtualInstallStack.Children.Add($InstallButton)
    $InstallScroll.Content = $VirtualInstallStack
    $TabInstall.Content = $InstallScroll
    $TabControl.Items.Add($TabInstall)

    # ... (các tab khác giữ nguyên như code bạn)

    # Footer (giữ nguyên)
    $FooterPanel = New-Object Windows.Controls.StackPanel
    $FooterPanel.Orientation = "Horizontal"
    $FooterPanel.HorizontalAlignment = "Center"
    $FooterPanel.Margin = "0,10,0,10"

    $RestartButton = New-Object Windows.Controls.Button
    $RestartButton.Content = "🔄 Khởi Động Lại"
    $RestartButton.Width = 150
    $RestartButton.Height = 40
    $RestartButton.Margin = "10"
    $RestartButton.Background = [Windows.Media.Brushes]::OrangeRed
    $RestartButton.Add_Click({ Restart-Computer -Force })

    $ExitButton = New-Object Windows.Controls.Button
    $ExitButton.Content = "❌ Thoát"
    $ExitButton.Width = 150
    $ExitButton.Height = 40
    $ExitButton.Margin = "10"
    $ExitButton.Background = [Windows.Media.Brushes]::Red
    $ExitButton.Foreground = [Windows.Media.Brushes]::White
    $ExitButton.Add_Click({ $Window.Close() })

    $FooterPanel.Children.Add($RestartButton)
    $FooterPanel.Children.Add($ExitButton)

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
    $null = $mainWindow.ShowDialog()
} catch {
    Write-Host "❌ GUI error: $_. Fallback to console." -ForegroundColor Red
    # Console fallback (hardcode minimum)
    Show-PMKLogo
    Write-Host "`nGUI không load được. Chạy local để dùng đầy đủ." -ForegroundColor Yellow
    Pause
}
