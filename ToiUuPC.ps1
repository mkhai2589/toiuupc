# PMK TOOLBOX v2.6 – Refactor + Log realtime + Win11 Style
# Author: Phạm Minh Khải
# Windows 10 / 11

Clear-Host

#region ADMIN CHECK
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent())
    .IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
#endregion

Add-Type -AssemblyName PresentationFramework
$ProgressPreference = 'SilentlyContinue'

#region SYSTEM INFO
function Get-SystemInfoText {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $ram = Get-CimInstance Win32_PhysicalMemory | Select-Object -First 1
    $disk = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.Size }

    $text = @"
🖥 HỆ THỐNG
• OS:  $($os.Caption)
• CPU: $($cpu.Name)
• RAM: $([math]::Round($os.TotalVisibleMemorySize/1MB,2)) GB
• RAM Bus: $($ram.Speed) MHz

💽 Ổ ĐĨA
"@

    foreach ($d in $disk) {
        $text += "• $($d.DeviceID)  $([math]::Round($d.FreeSpace/1GB,2)) GB trống / $([math]::Round($d.Size/1GB,2)) GB tổng`n"
    }

    return $text
}
#endregion

#region REGISTRY
function Set-RegistryTweak {
    param($Path,$Name,$Value,[string]$Type="DWord",[switch]$CreatePath)
    try {
        if ($CreatePath) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
        return $true
    } catch { return $false }
}
#endregion

#region TWEAKS
$global:Tweaks = @{
    "Tắt Telemetry" = { Set-RegistryTweak "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0 -CreatePath }
    "Tắt Game DVR"  = { Set-RegistryTweak "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 }
    "Tắt App nền"   = { Set-RegistryTweak "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1 }
    "Bật Dark Mode" = {
        Set-RegistryTweak "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0
        Set-RegistryTweak "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0
    }
    "Tắt Transparency" = {
        Set-RegistryTweak "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
    }
}
#endregion

#region UI
function Create-MainWindow {

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="PMK Toolbox v2.6"
        Height="700" Width="1100"
        WindowStartupLocation="CenterScreen"
        Background="#F3F4F6"
        FontFamily="Segoe UI Variable">

<Grid Margin="10">
<TabControl>

<TabItem Header="⚙ Tối Ưu">
<ScrollViewer>
<StackPanel Margin="15">
<TextBlock Text="PMK TOOLBOX – WINDOWS OPTIMIZER"
           FontSize="22" FontWeight="SemiBold" Margin="0,0,0,10"/>
<ItemsControl x:Name="TweakList"/>
<Button x:Name="ApplyBtn"
        Content="⚡ ÁP DỤNG TWEAK"
        Height="42" Margin="0,15,0,0"
        Background="#2563EB" Foreground="White" BorderThickness="0"/>
</StackPanel>
</ScrollViewer>
</TabItem>

<TabItem Header="💻 Hệ Thống">
<Grid Margin="10">
<TextBox x:Name="SysInfoBox"
         IsReadOnly="True"
         FontFamily="Consolas"
         FontSize="13"
         TextWrapping="Wrap"
         VerticalScrollBarVisibility="Auto"/>
</Grid>
</TabItem>

<TabItem Header="📜 Log Realtime">
<Grid Margin="10">
<TextBox x:Name="LogBox"
         IsReadOnly="True"
         FontFamily="Consolas"
         FontSize="12"
         Background="#0F172A"
         Foreground="#E5E7EB"
         VerticalScrollBarVisibility="Auto"/>
</Grid>
</TabItem>

</TabControl>
</Grid>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $win = [Windows.Markup.XamlReader]::Load($reader)

    $TweakList = $win.FindName("TweakList")
    $ApplyBtn  = $win.FindName("ApplyBtn")
    $SysInfoBox= $win.FindName("SysInfoBox")
    $LogBox    = $win.FindName("LogBox")

    function Write-Log($msg) {
        $win.Dispatcher.Invoke([action]{
            $LogBox.AppendText("[$(Get-Date -Format HH:mm:ss)] $msg`r`n")
            $LogBox.ScrollToEnd()
        })
    }

    # Load tweaks
    $panel = New-Object Windows.Controls.StackPanel
    $global:SelectedTweaks = @{}

    foreach ($t in $global:Tweaks.Keys) {
        $cb = New-Object Windows.Controls.CheckBox
        $cb.Content = $t
        $cb.Margin = "5"
        $cb.Add_Checked({ $global:SelectedTweaks[$this.Content] = $global:Tweaks[$this.Content] })
        $cb.Add_Unchecked({ $global:SelectedTweaks.Remove($this.Content) | Out-Null })
        $panel.Children.Add($cb) | Out-Null
    }

    $TweakList.Content = $panel
    $SysInfoBox.Text = Get-SystemInfoText

    $ApplyBtn.Add_Click({
        if ($global:SelectedTweaks.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Chưa chọn tweak nào!")
            return
        }

        $ApplyBtn.IsEnabled = $false
        $ApplyBtn.Content = "⏳ ĐANG ÁP DỤNG..."
        Write-Log "Bắt đầu tối ưu..."

        foreach ($name in $global:SelectedTweaks.Keys) {
            Write-Log "→ $name"
            try {
                & $global:SelectedTweaks[$name]
                Write-Log "✓ Thành công: $name"
            } catch {
                Write-Log "✗ Lỗi: $name - $_"
            }
        }

        Write-Log "Hoàn tất!"
        $ApplyBtn.Content = "✔ HOÀN TẤT"
        $ApplyBtn.IsEnabled = $true
    })

    return $win
}
#endregion

#region RUN
$window = Create-MainWindow
$null = $window.ShowDialog()
#endregion
