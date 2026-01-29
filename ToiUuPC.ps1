# ToiUuPC.ps1 - PMK Toolbox v3.3.3 (Full Refactor - JSON + Modular - 2026)
# Tác giả: Minh Khải (PMK)
# Chạy local: .\ToiUuPC.ps1
# Chạy remote: irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex

[CmdletBinding()]
param([switch]$Silent)

Clear-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Kiểm tra quyền Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Đường dẫn gốc (hỗ trợ bundled/remote)
$RootPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

# Màu sắc mặc định (sẽ được override bởi utils.ps1 nếu load được)
$global:TEXT_COLOR     = "White"
$global:HEADER_COLOR   = "Cyan"
$global:SUCCESS_COLOR  = "Green"
$global:ERROR_COLOR    = "Red"
$global:BORDER_COLOR   = "DarkGray"
$global:WARNING_COLOR  = "Yellow"

# Load tất cả functions từ thư mục functions/
$functionsPath = "$RootPath\functions"
if (Test-Path $functionsPath) {
    Get-ChildItem "$functionsPath\*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
        . $_.FullName
        Write-Verbose "Đã load function: $($_.Name)"
    }
} else {
    # Fallback remote nếu chạy từ irm
    $baseUrl = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main/functions"
    $functionFiles = @(
        "Show-PMKLogo.ps1",
        "utils.ps1",
        "install-apps.ps1",
        "tweaks.ps1",
        "dns-management.ps1",
        "clean-system.ps1"
    )
    foreach ($file in $functionFiles) {
        try {
            $url = "$baseUrl/$file"
            $content = Invoke-RestMethod -Uri $url -UseBasicParsing -ErrorAction Stop
            Invoke-Expression $content
            Write-Verbose "Đã load remote function: $file"
        } catch {
            Write-Warning "Không tải được remote function $file: $($_.Exception.Message)"
        }
    }
}

# Fallback nếu không load được function nào
if (-not (Get-Command Show-PMKLogo -ErrorAction SilentlyContinue)) {
    function Show-PMKLogo {
        Write-Host "PMK TOOLBOX" -ForegroundColor Cyan
    }
}
if (-not (Get-Command Reset-ConsoleStyle -ErrorAction SilentlyContinue)) {
    function Reset-ConsoleStyle { Clear-Host }
}
if (-not (Get-Command Set-RegistryTweak -ErrorAction SilentlyContinue)) {
    function Set-RegistryTweak {
        param($Path, $Name, $Value, $Type = "DWord", [switch]$CreatePath)
        if ($CreatePath -and -not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
    }
}
if (-not (Get-Command Create-RestorePoint -ErrorAction SilentlyContinue)) {
    function Create-RestorePoint {
        Checkpoint-Computer -Description "PMK Toolbox Restore" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
    }
}

# Hiển thị logo đầu tiên
Show-PMKLogo

Write-Host "`nĐang khởi tạo PMK Toolbox..." -ForegroundColor Yellow

# Load config JSON
$appsPath   = "$RootPath\config\applications.json"
$dnsPath    = "$RootPath\config\dns.json"
$tweaksPath = "$RootPath\config\tweaks.json"

if (-not (Test-Path $appsPath) -or -not (Test-Path $dnsPath) -or -not (Test-Path $tweaksPath)) {
    Write-Host "Thiếu file config! Kiểm tra thư mục config/ có đủ applications.json, dns.json, tweaks.json" -ForegroundColor Red
    Pause
    exit
}

try {
    $AppsJson   = Get-Content $appsPath   -Raw -ErrorAction Stop | ConvertFrom-Json
    $DnsJson    = Get-Content $dnsPath    -Raw -ErrorAction Stop | ConvertFrom-Json
    $TweaksJson = Get-Content $tweaksPath -Raw -ErrorAction Stop | ConvertFrom-Json
} catch {
    Write-Host "Lỗi parse JSON: $($_.Exception.Message)" -ForegroundColor Red
    Pause
    exit
}

# Kiểm tra winget
$hasWinget = $false
try {
    $null = winget --version
    $hasWinget = $true
} catch {
    Write-Host "Winget chưa được cài đặt. Tính năng cài ứng dụng sẽ bị tắt." -ForegroundColor Yellow
}

# Load WPF
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Tạo cửa sổ chính
$Window = New-Object Windows.Window
$Window.Title = "PMK Toolbox - Tối ưu Windows v3.3.3"
$Window.Width = 1200
$Window.Height = 750
$Window.WindowStartupLocation = "CenterScreen"
$Window.Background = [System.Windows.Media.Brushes]::AliceBlue
$Window.ResizeMode = "CanResize"

# Grid chính
$Grid = New-Object Windows.Controls.Grid
$Grid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height="Auto"}))  # Header
$Grid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height="*"}))     # Nội dung
$Grid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height="Auto"}))  # Footer
$Window.Content = $Grid

# Header
$Header = New-Object Windows.Controls.TextBlock
$Header.Text = "PMK TOOLBOX - Tối ưu Windows"
$Header.FontSize = 24
$Header.FontWeight = "Bold"
$Header.HorizontalAlignment = "Center"
$Header.Margin = "0,20,0,10"
$Header.Foreground = [System.Windows.Media.Brushes]::DarkBlue
$Grid.Children.Add($Header)
[Windows.Controls.Grid]::SetRow($Header, 0)

# TabControl
$TabControl = New-Object Windows.Controls.TabControl
$TabControl.Margin = "10"
$Grid.Children.Add($TabControl)
[Windows.Controls.Grid]::SetRow($TabControl, 1)

# Tab 1: Cài đặt ứng dụng
$TabApps = New-Object Windows.Controls.TabItem
$TabApps.Header = "📦 CÀI ĐẶT ỨNG DỤNG"
$TabControl.Items.Add($TabApps)

$AppsScroll = New-Object Windows.Controls.ScrollViewer
$AppsScroll.VerticalScrollBarVisibility = "Auto"
$AppsStack = New-Object Windows.Controls.StackPanel
$AppsStack.Margin = "15"
$AppsScroll.Content = $AppsStack
$TabApps.Content = $AppsScroll

$global:SelectedApps = @{}

foreach ($category in $AppsJson.PSObject.Properties.Name) {
    $CatBorder = New-Object Windows.Controls.Border
    $CatBorder.BorderBrush = [System.Windows.Media.Brushes]::Gray
    $CatBorder.BorderThickness = "1"
    $CatBorder.CornerRadius = "5"
    $CatBorder.Margin = "0,0,0,15"
    $CatBorder.Padding = "10"

    $CatHeader = New-Object Windows.Controls.TextBlock
    $CatHeader.Text = $category
    $CatHeader.FontSize = 18
    $CatHeader.FontWeight = "Bold"
    $CatHeader.Margin = "0,0,0,10"
    $CatBorder.Child = $CatHeader

    $CatWrap = New-Object Windows.Controls.WrapPanel
    $CatBorder.Child = $CatWrap

    $apps = $AppsJson.$category
    foreach ($app in $apps) {
        $AppBorder = New-Object Windows.Controls.Border
        $AppBorder.Width = 220
        $AppBorder.Height = 100
        $AppBorder.Margin = "10"
        $AppBorder.CornerRadius = "8"
        $AppBorder.Background = [System.Windows.Media.Brushes]::WhiteSmoke
        $AppBorder.BorderBrush = [System.Windows.Media.Brushes]::LightGray
        $AppBorder.BorderThickness = "1"
        $AppBorder.Tag = $app.Winget
        $AppBorder.Cursor = "Hand"

        $AppStack = New-Object Windows.Controls.StackPanel
        $AppStack.Orientation = "Horizontal"
        $AppStack.VerticalAlignment = "Center"
        $AppStack.HorizontalAlignment = "Center"

        $Icon = New-Object Windows.Controls.TextBlock
        $Icon.Text = $app.Icon
        $Icon.FontSize = 36
        $Icon.Margin = "10,0,10,0"
        $AppStack.Children.Add($Icon)

        $Name = New-Object Windows.Controls.TextBlock
        $Name.Text = $app.Name
        $Name.FontSize = 14
        $Name.VerticalAlignment = "Center"
        $AppStack.Children.Add($Name)

        $AppBorder.Child = $AppStack

        $AppBorder.Add_MouseLeftButtonDown({
            $id = $this.Tag
            if ($global:SelectedApps.ContainsKey($id)) {
                $this.Background = [System.Windows.Media.Brushes]::WhiteSmoke
                $global:SelectedApps.Remove($id)
            } else {
                $this.Background = [System.Windows.Media.Brushes]::LightGreen
                $global:SelectedApps[$id] = $true
            }
        })

        $CatWrap.Children.Add($AppBorder)
    }

    $AppsStack.Children.Add($CatBorder)
}

$InstallButton = New-Object Windows.Controls.Button
$InstallButton.Content = "Cài đặt các ứng dụng đã chọn"
$InstallButton.Width = 300
$InstallButton.Height = 50
$InstallButton.FontSize = 16
$InstallButton.Margin = "0,20,0,0"
$InstallButton.Background = [System.Windows.Media.Brushes]::DodgerBlue
$InstallButton.Foreground = [System.Windows.Media.Brushes]::White
$InstallButton.Add_Click({
    if ($global:SelectedApps.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Bạn chưa chọn ứng dụng nào!", "Thông báo")
        return
    }

    $total = $global:SelectedApps.Count
    $progress = 0

    foreach ($id in $global:SelectedApps.Keys) {
        $progress++
        $percent = [math]::Round($progress / $total * 100)
        $InstallButton.Content = "Đang cài... $progress/$total ($percent%)"
        $InstallButton.IsEnabled = $false

        try {
            if ($hasWinget) {
                winget install --id $id --silent --accept-package-agreements --accept-source-agreements
            } else {
                Write-Host "Winget không khả dụng, bỏ qua $id" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Lỗi cài $id : $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    $InstallButton.Content = "Cài đặt hoàn tất!"
    $InstallButton.IsEnabled = $true
    [System.Windows.MessageBox]::Show("Đã hoàn tất cài đặt!", "Thông báo")
})
$AppsStack.Children.Add($InstallButton)

# Tab 2: Tối ưu hệ thống (Tweaks)
$TabTweaks = New-Object Windows.Controls.TabItem
$TabTweaks.Header = "⚙️ TỐI ƯU HỆ THỐNG"
$TabControl.Items.Add($TabTweaks)

$TweaksScroll = New-Object Windows.Controls.ScrollViewer
$TweaksScroll.VerticalScrollBarVisibility = "Auto"
$TweaksStack = New-Object Windows.Controls.StackPanel
$TweaksStack.Margin = "15"
$TweaksScroll.Content = $TweaksStack
$TabTweaks.Content = $TweaksScroll

$global:SelectedTweaks = @{}

foreach ($category in $TweaksJson.PSObject.Properties.Name) {
    $CatBorder = New-Object Windows.Controls.Border
    $CatBorder.BorderBrush = [System.Windows.Media.Brushes]::Gray
    $CatBorder.BorderThickness = "1"
    $CatBorder.CornerRadius = "5"
    $CatBorder.Margin = "0,0,0,15"
    $CatBorder.Padding = "10"

    $CatHeader = New-Object Windows.Controls.TextBlock
    $CatHeader.Text = $category
    $CatHeader.FontSize = 18
    $CatHeader.FontWeight = "Bold"
    $CatHeader.Margin = "0,0,0,10"
    $CatBorder.Child = $CatHeader

    $CatStack = New-Object Windows.Controls.StackPanel
    $CatBorder.Child = $CatStack

    $tweaks = $TweaksJson.$category
    foreach ($tweak in $tweaks) {
        $Check = New-Object Windows.Controls.CheckBox
        $Check.Content = $tweak.Name
        $Check.Margin = "0,5,0,5"
        $Check.Tag = $tweak

        $Check.Add_Checked({
            $global:SelectedTweaks[$this.Content] = $this.Tag
        })
        $Check.Add_Unchecked({
            $global:SelectedTweaks.Remove($this.Content)
        })

        $CatStack.Children.Add($Check)
    }

    $TweaksStack.Children.Add($CatBorder)
}

$ApplyTweaksButton = New-Object Windows.Controls.Button
$ApplyTweaksButton.Content = "Áp dụng các Tweaks đã chọn"
$ApplyTweaksButton.Width = 300
$ApplyTweaksButton.Height = 50
$ApplyTweaksButton.FontSize = 16
$ApplyTweaksButton.Margin = "0,20,0,0"
$ApplyTweaksButton.Background = [System.Windows.Media.Brushes]::ForestGreen
$ApplyTweaksButton.Foreground = [System.Windows.Media.Brushes]::White
$ApplyTweaksButton.Add_Click({
    if ($global:SelectedTweaks.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Bạn chưa chọn tweak nào!", "Thông báo")
        return
    }

    Create-RestorePoint  # Tạo điểm khôi phục trước

    $total = $global:SelectedTweaks.Count
    $progress = 0

    foreach ($tweak in $global:SelectedTweaks.Values) {
        $progress++
        $percent = [math]::Round($progress / $total * 100)
        $ApplyTweaksButton.Content = "Đang áp dụng... $progress/$total ($percent%)"
        $ApplyTweaksButton.IsEnabled = $false

        Write-Host "Áp dụng: $($tweak.Name)" -ForegroundColor Yellow

        try {
            if ($tweak.Action -and (Get-Command $tweak.Action -ErrorAction SilentlyContinue)) {
                & $tweak.Action
            } elseif ($tweak.Action -is [string]) {
                Invoke-Expression $tweak.Action
            } else {
                Write-Host "Không có action hợp lệ cho $($tweak.Name)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Lỗi khi áp dụng $($tweak.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    $ApplyTweaksButton.Content = "Áp dụng hoàn tất!"
    $ApplyTweaksButton.IsEnabled = $true
    [System.Windows.MessageBox]::Show("Đã áp dụng xong các tweaks!", "Thông báo")
})
$TweaksStack.Children.Add($ApplyTweaksButton)

# Tab 3: Quản lý DNS
$TabDNS = New-Object Windows.Controls.TabItem
$TabDNS.Header = "🌐 DNS & Mạng"
$TabControl.Items.Add($TabDNS)

$DnsGrid = New-Object Windows.Controls.Grid
$DnsGrid.Margin = "20"
$TabDNS.Content = $DnsGrid

$DnsCombo = New-Object Windows.Controls.ComboBox
$DnsCombo.Width = 400
$DnsCombo.Height = 40
$DnsCombo.FontSize = 14
$DnsCombo.HorizontalAlignment = "Center"
$DnsCombo.Margin = "0,20,0,20"

$DnsJson.PSObject.Properties.Name | ForEach-Object { $DnsCombo.Items.Add($_) | Out-Null }
$DnsCombo.SelectedIndex = 0

$DnsGrid.Children.Add($DnsCombo)

$ApplyDnsButton = New-Object Windows.Controls.Button
$ApplyDnsButton.Content = "Áp dụng DNS đã chọn"
$ApplyDnsButton.Width = 300
$ApplyDnsButton.Height = 50
$ApplyDnsButton.FontSize = 16
$ApplyDnsButton.Background = [System.Windows.Media.Brushes]::DodgerBlue
$ApplyDnsButton.Foreground = [System.Windows.Media.Brushes]::White
$ApplyDnsButton.HorizontalAlignment = "Center"
$ApplyDnsButton.Margin = "0,0,0,20"
$ApplyDnsButton.Add_Click({
    $selected = $DnsCombo.SelectedItem
    if (-not $selected) {
        [System.Windows.MessageBox]::Show("Vui lòng chọn DNS!", "Thông báo")
        return
    }

    $result = Set-DNSServer -DNSServerName $selected
    [System.Windows.MessageBox]::Show($result, "Kết quả")
})
$DnsGrid.Children.Add($ApplyDnsButton)

# Footer
$Footer = New-Object Windows.Controls.TextBlock
$Footer.Text = "PMK Toolbox v3.3.3 | Tác giả: Minh Khải (PMK) | https://facebook.com/khaiitcntt"
$Footer.HorizontalAlignment = "Center"
$Footer.Margin = "0,10,0,10"
$Footer.FontSize = 12
$Grid.Children.Add($Footer)
[Windows.Controls.Grid]::SetRow($Footer, 2)

# Hiển thị cửa sổ
$Window.ShowDialog() | Out-Null