# =========================================
# TOIUUPC BUNDLED - ALL IN ONE (GUI + EMBEDDED)
# WPF GUI + Embedded JSON + No External Files
# =========================================

# UTF-8 Encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# Load WPF assemblies
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# =========================================
# ADMIN CHECK
# =========================================
function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    [System.Windows.MessageBox]::Show(
        "Vui lòng chạy PowerShell bằng quyền Administrator",
        "ToiUuPC",
        "OK",
        "Error"
    ) | Out-Null
    exit 1
}

# =========================================
# EMBEDDED CONFIGURATIONS
# =========================================

# EMBEDDED APPLICATIONS JSON
$EMBEDDED_APPS_JSON = @'
{
  "applications": [
    {
      "id": "chrome",
      "name": "Google Chrome",
      "packageId": "Google.Chrome",
      "source": "winget",
      "category": "Browser",
      "preset": ["Office", "Gaming"],
      "silent": true
    },
    {
      "id": "firefox",
      "name": "Mozilla Firefox",
      "packageId": "Mozilla.Firefox",
      "source": "winget",
      "category": "Browser",
      "preset": ["Office"],
      "silent": true
    },
    {
      "id": "edge",
      "name": "Microsoft Edge",
      "packageId": "Microsoft.Edge",
      "source": "winget",
      "category": "Browser",
      "preset": ["Office"],
      "silent": true
    },
    {
      "id": "brave",
      "name": "Brave Browser",
      "packageId": "Brave.Brave",
      "source": "winget",
      "category": "Browser",
      "preset": ["Office", "Gaming"],
      "silent": true
    },
    {
      "id": "vivaldi",
      "name": "Vivaldi",
      "packageId": "Vivaldi.Vivaldi",
      "source": "winget",
      "category": "Browser",
      "preset": ["Office"],
      "silent": true
    },
    {
      "id": "opera",
      "name": "Opera",
      "packageId": "Opera.Opera",
      "source": "winget",
      "category": "Browser",
      "preset": ["Office"],
      "silent": true
    },
    {
      "id": "coccoc",
      "name": "Cốc Cốc",
      "packageId": "CocCoc.CocCoc",
      "source": "winget",
      "category": "Browser",
      "preset": ["Office"],
      "silent": true
    },
    {
      "id": "tor",
      "name": "Tor Browser",
      "packageId": "TorProject.TorBrowser",
      "source": "winget",
      "category": "Browser",
      "preset": ["Privacy"],
      "silent": true
    },
    {
      "id": "zalo",
      "name": "Zalo",
      "packageId": "VNGCorp.Zalo",
      "source": "winget",
      "category": "Communication",
      "preset": ["Office"],
      "silent": true
    },
    {
      "id": "telegram",
      "name": "Telegram Desktop",
      "packageId": "Telegram.TelegramDesktop",
      "source": "winget",
      "category": "Communication",
      "preset": ["Office", "Gaming"],
      "silent": true
    },
    {
      "id": "whatsapp",
      "name": "WhatsApp",
      "packageId": "WhatsApp.WhatsApp",
      "source": "msstore",
      "category": "Communication",
      "preset": ["Office"],
      "silent": true
    },
    {
      "id": "discord",
      "name": "Discord",
      "packageId": "Discord.Discord",
      "source": "winget",
      "category": "Communication",
      "preset": ["Gaming"],
      "silent": true
    },
    {
      "id": "vscode",
      "name": "Visual Studio Code",
      "packageId": "Microsoft.VisualStudioCode",
      "source": "winget",
      "category": "Development",
      "preset": ["Office"],
      "silent": true
    },
    {
      "id": "git",
      "name": "Git",
      "packageId": "Git.Git",
      "source": "winget",
      "category": "Development",
      "preset": ["Office"],
      "silent": true
    },
    {
      "id": "7zip",
      "name": "7-Zip",
      "packageId": "7zip.7zip",
      "source": "winget",
      "category": "Utility",
      "preset": ["Office", "Gaming"],
      "silent": true
    },
    {
      "id": "vlc",
      "name": "VLC Media Player",
      "packageId": "VideoLAN.VLC",
      "source": "winget",
      "category": "Media",
      "preset": ["Office", "Gaming"],
      "silent": true
    },
    {
      "id": "spotify",
      "name": "Spotify",
      "packageId": "Spotify.Spotify",
      "source": "msstore",
      "category": "Media",
      "preset": ["Office", "Gaming"],
      "silent": true
    },
    {
      "id": "notepadpp",
      "name": "Notepad++",
      "packageId": "Notepad++.Notepad++",
      "source": "winget",
      "category": "Utility",
      "preset": ["Office"],
      "silent": true
    }
  ]
}
'@

# EMBEDDED TWEAKS JSON (Simplified)
$EMBEDDED_TWEAKS_JSON = @'
{
  "tweaks": [
    {
      "id": "telemetry-set-level-security",
      "name": "Đặt mức thu thập dữ liệu xuống Security",
      "type": "registry",
      "path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection",
      "nameReg": "AllowTelemetry",
      "value": 0,
      "regType": "DWORD"
    },
    {
      "id": "explorer-show-file-extensions",
      "name": "Luôn hiển thị phần mở rộng file",
      "type": "registry",
      "path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "nameReg": "HideFileExt",
      "value": 0,
      "regType": "DWORD"
    },
    {
      "id": "explorer-launch-to-this-pc",
      "name": "File Explorer mở tại 'This PC'",
      "type": "registry",
      "path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "nameReg": "LaunchTo",
      "value": 1,
      "regType": "DWORD"
    },
    {
      "id": "disable-web-search-in-start",
      "name": "Tắt tìm kiếm web trong Start Menu",
      "type": "registry",
      "path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Search",
      "nameReg": "BingSearchEnabled",
      "value": 0,
      "regType": "DWORD"
    },
    {
      "id": "disable-wsearch-service",
      "name": "Tắt dịch vụ Windows Search (WSearch)",
      "type": "service",
      "serviceName": "WSearch",
      "startup": "Disabled"
    },
    {
      "id": "disable-sysmain-superfetch",
      "name": "Tắt dịch vụ SysMain (Superfetch)",
      "type": "service",
      "serviceName": "SysMain",
      "startup": "Disabled"
    }
  ]
}
'@

# EMBEDDED DNS JSON
$EMBEDDED_DNS_JSON = @'
{
  "Default DHCP": {
    "Primary": "",
    "Secondary": "",
    "Primary6": "",
    "Secondary6": ""
  },
  "Google": {
    "Primary": "8.8.8.8",
    "Secondary": "8.8.4.4",
    "Primary6": "2001:4860:4860::8888",
    "Secondary6": "2001:4860:4860::8844"
  },
  "Cloudflare": {
    "Primary": "1.1.1.1",
    "Secondary": "1.0.0.1",
    "Primary6": "2606:4700:4700::1111",
    "Secondary6": "2606:4700:4700::1001"
  }
}
'@

# =========================================
# CORE FUNCTIONS (Embedded, không cần file ngoài)
# =========================================

# Parse embedded JSON
$appConfig = $EMBEDDED_APPS_JSON | ConvertFrom-Json
$tweakConfig = $EMBEDDED_TWEAKS_JSON | ConvertFrom-Json
$dnsConfig = $EMBEDDED_DNS_JSON | ConvertFrom-Json

# Restore Point Function
function New-RestorePoint {
    param([bool]$Enable = $true)
    
    if (-not $Enable) { return }
    
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "ToiUuPC Restore Point" -RestorePointType "MODIFY_SETTINGS"
        return $true
    } catch {
        return $false
    }
}

# Tweaks Engine
function Invoke-SystemTweaks {
    param(
        [array]$SelectedIds,
        [string]$BackupPath = "$env:TEMP\ToiUuPC-Backup"
    )
    
    $applyList = $tweakConfig.tweaks | Where-Object { $_.id -in $SelectedIds }
    
    foreach ($t in $applyList) {
        Write-Host "  Applying: $($t.name)" -ForegroundColor Cyan
        
        switch ($t.type) {
            "registry" {
                if (-not (Test-Path $t.path)) {
                    New-Item -Path $t.path -Force | Out-Null
                }
                Set-ItemProperty -Path $t.path -Name $t.nameReg -Value $t.value -Type $t.regType
            }
            "service" {
                $svc = Get-Service -Name $t.serviceName -ErrorAction SilentlyContinue
                if ($svc) {
                    Set-Service -Name $t.serviceName -StartupType $t.startup
                    Stop-Service -Name $t.serviceName -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
    
    Write-Host "  Tweaks applied successfully!" -ForegroundColor Green
}

# Apps Install Engine
function Invoke-AppInstaller {
    param([array]$SelectedIds)
    
    # Check winget
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        [System.Windows.MessageBox]::Show(
            "Winget không tìm thấy. Cần Windows 10 1809+ hoặc Windows 11.",
            "ToiUuPC",
            "OK",
            "Warning"
        ) | Out-Null
        return
    }
    
    $apps = $appConfig.applications | Where-Object { $_.id -in $SelectedIds }
    
    foreach ($app in $apps) {
        Write-Host "  Installing: $($app.name)" -ForegroundColor Cyan
        
        $args = @(
            "install",
            "--id", $app.packageId,
            "-e",
            "--source", $app.source
        )
        
        if ($app.silent) {
            $args += "--silent"
            $args += "--accept-package-agreements"
            $args += "--accept-source-agreements"
        }
        
        try {
            Start-Process winget -ArgumentList $args -Wait -NoNewWindow -ErrorAction Stop
            Write-Host "    ✓ Success" -ForegroundColor Green
        } catch {
            Write-Host "    ✗ Failed: $_" -ForegroundColor Red
        }
    }
}

# DNS Engine
function Invoke-DnsManager {
    param([string]$DnsName)
    
    $dns = $dnsConfig.$DnsName
    
    if (-not $dns) {
        Write-Host "DNS config not found" -ForegroundColor Red
        return
    }
    
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    foreach ($adapter in $adapters) {
        if ([string]::IsNullOrWhiteSpace($dns.Primary)) {
            # Reset to DHCP
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ResetServerAddresses
            Write-Host "  Reset DNS for $($adapter.Name)" -ForegroundColor Yellow
        } else {
            # Set custom DNS
            $addresses = @()
            if (-not [string]::IsNullOrWhiteSpace($dns.Primary)) { $addresses += $dns.Primary }
            if (-not [string]::IsNullOrWhiteSpace($dns.Secondary)) { $addresses += $dns.Secondary }
            
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $addresses
            Write-Host "  Set $DnsName DNS for $($adapter.Name)" -ForegroundColor Cyan
        }
    }
}

# Clean Engine
function Invoke-CleanSystem {
    Write-Host "  Cleaning temporary files..." -ForegroundColor Cyan
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "  Cleaning browser cache..." -ForegroundColor Cyan
    Remove-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "  Clearing recycle bin..." -ForegroundColor Cyan
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    
    Write-Host "  Cleanup completed!" -ForegroundColor Green
}

# =========================================
# WPF GUI WITH CHECKBOXES
# =========================================

# XAML for main window
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ToiUuPC - All in One" 
        Width="850" 
        Height="650"
        WindowStartupLocation="CenterScreen"
        Background="#FF2D2D30">
    
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        
        <!-- LEFT PANEL: TWEAKS -->
        <GroupBox Header="Windows Tweaks" Margin="10" Foreground="White">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <StackPanel Name="TweaksPanel" Margin="5"/>
            </ScrollViewer>
        </GroupBox>
        
        <!-- RIGHT PANEL: APPLICATIONS -->
        <GroupBox Header="Applications" Margin="10" Grid.Column="1" Foreground="White">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <StackPanel Name="AppsPanel" Margin="5"/>
            </ScrollViewer>
        </GroupBox>
        
        <!-- BOTTOM CONTROLS -->
        <StackPanel Grid.ColumnSpan="2" VerticalAlignment="Bottom" Margin="10">
            <GroupBox Header="Options" Foreground="White" Margin="0,0,0,10">
                <StackPanel>
                    <CheckBox Name="ChkRestore" Content="Create system restore point before changes" 
                             Margin="5" Foreground="White" IsChecked="True"/>
                    <CheckBox Name="ChkSelectAllTweaks" Content="Select All Tweaks" 
                             Margin="5" Foreground="White"/>
                    <CheckBox Name="ChkSelectAllApps" Content="Select All Applications" 
                             Margin="5" Foreground="White"/>
                </StackPanel>
            </GroupBox>
            
            <GroupBox Header="DNS" Foreground="White" Margin="0,0,0,10">
                <StackPanel Orientation="Horizontal">
                    <Button Name="BtnDNSGoogle" Content="Google DNS" Width="100" Margin="5"/>
                    <Button Name="BtnDNSCloudflare" Content="Cloudflare DNS" Width="100" Margin="5"/>
                    <Button Name="BtnDNSReset" Content="Reset to DHCP" Width="100" Margin="5"/>
                </StackPanel>
            </GroupBox>
            
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <Button Name="BtnApply" Content="Apply Selected" Width="120" Height="35" 
                       Margin="5" Background="#FF0E639C" Foreground="White" FontWeight="Bold"/>
                <Button Name="BtnClean" Content="Clean System" Width="120" Height="35" 
                       Margin="5" Background="#FFCA5100" Foreground="White"/>
                <Button Name="BtnExit" Content="Exit" Width="80" Height="35" 
                       Margin="5" Background="#FF555555" Foreground="White"/>
            </StackPanel>
            
            <ProgressBar Name="ProgressBar" Height="10" Margin="5,15,5,5" Visibility="Collapsed"/>
            <TextBlock Name="StatusText" Foreground="White" HorizontalAlignment="Center" 
                      Margin="5" TextWrapping="Wrap"/>
        </StackPanel>
    </Grid>
</Window>
'@

# Load XAML
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$tweaksPanel = $window.FindName("TweaksPanel")
$appsPanel = $window.FindName("AppsPanel")
$chkRestore = $window.FindName("ChkRestore")
$chkSelectAllTweaks = $window.FindName("ChkSelectAllTweaks")
$chkSelectAllApps = $window.FindName("ChkSelectAllApps")
$btnApply = $window.FindName("BtnApply")
$btnClean = $window.FindName("BtnClean")
$btnExit = $window.FindName("BtnExit")
$btnDNSGoogle = $window.FindName("BtnDNSGoogle")
$btnDNSCloudflare = $window.FindName("BtnDNSCloudflare")
$btnDNSReset = $window.FindName("BtnDNSReset")
$progressBar = $window.FindName("ProgressBar")
$statusText = $window.FindName("StatusText")

# =========================================
# POPULATE CHECKBOXES FROM EMBEDDED JSON
# =========================================

# Populate tweaks checkboxes
foreach ($tweak in $tweakConfig.tweaks) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $tweak.name
    $cb.Tag = $tweak.id
    $cb.Margin = "0,2,0,2"
    $cb.Foreground = "White"
    $tweaksPanel.Children.Add($cb) | Out-Null
}

# Populate apps checkboxes
foreach ($app in $appConfig.applications) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $app.name
    $cb.Tag = $app.id
    $cb.Margin = "0,2,0,2"
    $cb.Foreground = "White"
    $appsPanel.Children.Add($cb) | Out-Null
}

# =========================================
# EVENT HANDLERS
# =========================================

# Select All Tweaks
$chkSelectAllTweaks.Add_Checked({
    foreach ($child in $tweaksPanel.Children) {
        if ($child -is [System.Windows.Controls.CheckBox]) {
            $child.IsChecked = $true
        }
    }
})

$chkSelectAllTweaks.Add_Unchecked({
    foreach ($child in $tweaksPanel.Children) {
        if ($child -is [System.Windows.Controls.CheckBox]) {
            $child.IsChecked = $false
        }
    }
})

# Select All Apps
$chkSelectAllApps.Add_Checked({
    foreach ($child in $appsPanel.Children) {
        if ($child -is [System.Windows.Controls.CheckBox]) {
            $child.IsChecked = $true
        }
    }
})

$chkSelectAllApps.Add_Unchecked({
    foreach ($child in $appsPanel.Children) {
        if ($child -is [System.Windows.Controls.CheckBox]) {
            $child.IsChecked = $false
        }
    }
})

# Apply Button
$btnApply.Add_Click({
    $statusText.Text = "Processing..."
    $progressBar.Visibility = "Visible"
    $progressBar.Value = 0
    $window.IsEnabled = $false
    
    # Get selected tweaks
    $selectedTweaks = @()
    foreach ($child in $tweaksPanel.Children) {
        if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsChecked -eq $true) {
            $selectedTweaks += $child.Tag
        }
    }
    
    # Get selected apps
    $selectedApps = @()
    foreach ($child in $appsPanel.Children) {
        if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsChecked -eq $true) {
            $selectedApps += $child.Tag
        }
    }
    
    # Create restore point if checked
    if ($chkRestore.IsChecked -eq $true) {
        $statusText.Text = "Creating restore point..."
        $restoreCreated = New-RestorePoint
        if ($restoreCreated) {
            $statusText.Text = "Restore point created successfully"
        } else {
            $statusText.Text = "Could not create restore point (service may be disabled)"
        }
    }
    
    # Apply tweaks
    if ($selectedTweaks.Count -gt 0) {
        $statusText.Text = "Applying tweaks..."
        Invoke-SystemTweaks -SelectedIds $selectedTweaks
        $progressBar.Value = 50
    }
    
    # Install apps
    if ($selectedApps.Count -gt 0) {
        $statusText.Text = "Installing applications..."
        Invoke-AppInstaller -SelectedIds $selectedApps
        $progressBar.Value = 100
    }
    
    # Complete
    $statusText.Text = "Operation completed successfully!"
    $progressBar.Visibility = "Collapsed"
    $window.IsEnabled = $true
    
    [System.Windows.MessageBox]::Show(
        "Đã hoàn thành tất cả thao tác!`n`nTweaks: $($selectedTweaks.Count)`nỨng dụng: $($selectedApps.Count)",
        "ToiUuPC",
        "OK",
        "Information"
    ) | Out-Null
})

# Clean System Button
$btnClean.Add_Click({
    $window.IsEnabled = $false
    $statusText.Text = "Cleaning system..."
    Invoke-CleanSystem
    $statusText.Text = "System cleaned successfully!"
    $window.IsEnabled = $true
})

# DNS Buttons
$btnDNSGoogle.Add_Click({
    $statusText.Text = "Setting Google DNS..."
    Invoke-DnsManager -DnsName "Google"
    $statusText.Text = "Google DNS applied!"
})

$btnDNSCloudflare.Add_Click({
    $statusText.Text = "Setting Cloudflare DNS..."
    Invoke-DnsManager -DnsName "Cloudflare"
    $statusText.Text = "Cloudflare DNS applied!"
})

$btnDNSReset.Add_Click({
    $statusText.Text = "Resetting DNS to DHCP..."
    Invoke-DnsManager -DnsName "Default DHCP"
    $statusText.Text = "DNS reset to DHCP!"
})

# Exit Button
$btnExit.Add_Click({
    $window.Close()
})

# =========================================
# SHOW WINDOW
# =========================================

# Initial status
$statusText.Text = "Ready. Select options and click Apply."

# Show window
$window.ShowDialog() | Out-Null

Write-Host "ToiUuPC has exited." -ForegroundColor Cyan
