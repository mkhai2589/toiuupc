# =========================================
# ToiUuPC - Bundled Version
# Author: PMK
# Windows PowerShell 5.1
# =========================================

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# =========================================
# ADMIN CHECK
# =========================================
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Start-Process powershell `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs
    exit
}

# =========================================
# GLOBAL PATH
# =========================================
$Root = Join-Path $env:TEMP "ToiUuPC"
$LogDir = Join-Path $Root "logs"
$LogFile = Join-Path $LogDir "toiuupc.log"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# =========================================
# LOGGING
# =========================================
function Write-Log {
    param([string]$Message)
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$time | $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# =========================================
# RESTORE POINT
# =========================================
function New-ToiUuPCRestorePoint {
    Write-Host "Creating restore point..."
    Write-Log "Create restore point"

    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue

    Checkpoint-Computer `
        -Description "ToiUuPC Restore Point" `
        -RestorePointType "MODIFY_SETTINGS"
}

# =========================================
# WINDOWS TWEAKS
# =========================================
function Invoke-WindowsTweaks {

    Write-Host "Applying Windows tweaks..."
    Write-Log "Tweaks start"

    New-ToiUuPCRestorePoint

    $Tweaks = @(
        # Disable Task View
        @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="ShowTaskViewButton"; Value=0; Type="DWord" }

        # Disable Widgets (Win11)
        @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="TaskbarDa"; Value=0; Type="DWord" }

        # Disable Chat
        @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="TaskbarMn"; Value=0; Type="DWord" }

        # Show file extensions
        @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="HideFileExt"; Value=0; Type="DWord" }

        # Disable Bing search
        @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name="BingSearchEnabled"; Value=0; Type="DWord" }
    )

    foreach ($t in $Tweaks) {
        if (-not (Test-Path $t.Path)) {
            New-Item -Path $t.Path -Force | Out-Null
        }
        Set-ItemProperty `
            -Path $t.Path `
            -Name $t.Name `
            -Value $t.Value `
            -Type $t.Type
    }

    Write-Host "Tweaks completed"
    Write-Log "Tweaks end"
}

# =========================================
# CLEAN SYSTEM
# =========================================
function Invoke-CleanSystem {

    Write-Host "Cleaning system..."
    Write-Log "Clean start"

    $Paths = @(
        "$env:TEMP\*",
        "$env:LOCALAPPDATA\Temp\*",
        "C:\Windows\Temp\*"
    )

    foreach ($p in $Paths) {
        Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
    }

    Clear-RecycleBin -Force -ErrorAction SilentlyContinue

    Write-Host "Clean completed"
    Write-Log "Clean end"
}

# =========================================
# INSTALL APPS (WINGET)
# =========================================
function Invoke-AppInstall {

    Write-Host "Installing applications..."
    Write-Log "Install apps start"

    $Apps = @(
        "Google.Chrome",
        "7zip.7zip",
        "VideoLAN.VLC",
        "Notepad++.Notepad++"
    )

    foreach ($app in $Apps) {
        Start-Process winget `
            -ArgumentList "install --id $app --silent --accept-package-agreements --accept-source-agreements" `
            -Wait `
            -NoNewWindow
    }

    Write-Host "Apps installed"
    Write-Log "Install apps end"
}

# =========================================
# DNS MANAGEMENT
# =========================================
function Set-DnsGoogle {

    Write-Host "Setting Google DNS..."
    Write-Log "DNS Google"

    Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
        Set-DnsClientServerAddress `
            -InterfaceAlias $_.Name `
            -ServerAddresses 8.8.8.8,8.8.4.4
    }
}

function Set-DnsCloudflare {

    Write-Host "Setting Cloudflare DNS..."
    Write-Log "DNS Cloudflare"

    Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
        Set-DnsClientServerAddress `
            -InterfaceAlias $_.Name `
            -ServerAddresses 1.1.1.1,1.0.0.1
    }
}

function Reset-Dns {

    Write-Host "Reset DNS to automatic..."
    Write-Log "DNS Reset"

    Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
        Set-DnsClientServerAddress `
            -InterfaceAlias $_.Name `
            -ResetServerAddresses
    }
}

# =========================================
# GUI WPF
# =========================================
Add-Type -AssemblyName PresentationFramework

$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="ToiUuPC"
        Height="420"
        Width="420"
        WindowStartupLocation="CenterScreen">
    <StackPanel Margin="20">
        <TextBlock Text="TOI UU PC"
                   FontSize="22"
                   FontWeight="Bold"
                   Margin="0,0,0,20"/>

        <Button Name="BtnTweaks" Content="Toi uu Windows" Height="40" Margin="0,5"/>
        <Button Name="BtnApps" Content="Cai ung dung" Height="40" Margin="0,5"/>
        <Button Name="BtnDNSGoogle" Content="DNS Google" Height="40" Margin="0,5"/>
        <Button Name="BtnDNSCloud" Content="DNS Cloudflare" Height="40" Margin="0,5"/>
        <Button Name="BtnDNSReset" Content="Reset DNS" Height="40" Margin="0,5"/>
        <Button Name="BtnClean" Content="Don dep he thong" Height="40" Margin="0,5"/>
        <Button Name="BtnExit" Content="Thoat" Height="40" Margin="0,20,0,0"/>
    </StackPanel>
</Window>
"@

$Reader = New-Object System.Xml.XmlNodeReader ([xml]$Xaml)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# =========================================
# GUI EVENTS
# =========================================
$Window.FindName("BtnTweaks").Add_Click({ Invoke-WindowsTweaks })
$Window.FindName("BtnApps").Add_Click({ Invoke-AppInstall })
$Window.FindName("BtnDNSGoogle").Add_Click({ Set-DnsGoogle })
$Window.FindName("BtnDNSCloud").Add_Click({ Set-DnsCloudflare })
$Window.FindName("BtnDNSReset").Add_Click({ Reset-Dns })
$Window.FindName("BtnClean").Add_Click({ Invoke-CleanSystem })
$Window.FindName("BtnExit").Add_Click({ $Window.Close() })

# =========================================
# START GUI
# =========================================
$Window.ShowDialog() | Out-Null
