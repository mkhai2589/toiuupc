# =========================================
# ToiUuPC Bundled - GUI WinUtil Style
# =========================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ---------- ADMIN ----------
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Start-Process powershell `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs
    exit
}

# ---------- LOG ----------
$Root = Join-Path $env:TEMP "ToiUuPC"
$LogDir = Join-Path $Root "logs"
$LogFile = Join-Path $LogDir "gui.log"
New-Item $LogDir -ItemType Directory -Force | Out-Null

function Write-Log {
    param($Msg)
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $Msg" |
        Out-File $LogFile -Append -Encoding utf8
}

# ---------- RESTORE POINT ----------
function Try-CreateRestorePoint {
    param([bool]$Enable)

    if (-not $Enable) { return }

    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
        Checkpoint-Computer -Description "ToiUuPC Restore" -RestorePointType MODIFY_SETTINGS
        Write-Log "Restore point created"
    }
    catch {
        Write-Log "Restore point skipped"
    }
}

# ---------- ACTIONS ----------
function Do-Tweaks {
    param($CreateRestore)

    Try-CreateRestorePoint $CreateRestore

    Write-Log "Apply tweaks"

    $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    New-Item $reg -Force | Out-Null
    Set-ItemProperty $reg HideFileExt 0
    Set-ItemProperty $reg ShowTaskViewButton 0

    Write-Log "Tweaks done"
}

function Do-Clean {
    Write-Log "Clean system"
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

function Do-InstallApps {
    Write-Log "Install apps"
    $apps = "Google.Chrome","7zip.7zip","VideoLAN.VLC"
    foreach ($a in $apps) {
        Start-Process winget `
            -ArgumentList "install --id $a --silent --accept-source-agreements" `
            -Wait -NoNewWindow
    }
}

function Do-DnsGoogle {
    Get-NetAdapter | Where Status -eq Up | ForEach-Object {
        Set-DnsClientServerAddress $_.Name 8.8.8.8,8.8.4.4
    }
}

function Do-DnsReset {
    Get-NetAdapter | Where Status -eq Up | ForEach-Object {
        Set-DnsClientServerAddress $_.Name -ResetServerAddresses
    }
}

# ---------- GUI ----------
Add-Type -AssemblyName PresentationFramework

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="ToiUuPC"
        Width="520"
        Height="420"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <StackPanel>
            <TextBlock Text="TOI UU PC"
                       FontSize="22"
                       FontWeight="Bold"/>
            <CheckBox Name="ChkRestore"
                      Content="Create restore point before changes"
                      Margin="0,10,0,10"/>
        </StackPanel>

        <StackPanel Grid.Row="1">
            <Button Name="BtnTweaks" Content="Apply Windows Tweaks" Height="38" Margin="0,5"/>
            <Button Name="BtnApps" Content="Install Applications" Height="38" Margin="0,5"/>
            <Button Name="BtnClean" Content="Clean System" Height="38" Margin="0,5"/>
            <Button Name="BtnDNSG" Content="Set DNS Google" Height="38" Margin="0,5"/>
            <Button Name="BtnDNSR" Content="Reset DNS" Height="38" Margin="0,5"/>
            <Button Name="BtnExit" Content="Exit" Height="38" Margin="0,15"/>
        </StackPanel>
    </Grid>
</Window>
"@

$w = [Windows.Markup.XamlReader]::Load(
    (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
)

# ---------- EVENTS ----------
$w.FindName("BtnTweaks").Add_Click({
    Do-Tweaks $w.FindName("ChkRestore").IsChecked
})

$w.FindName("BtnApps").Add_Click({ Do-InstallApps })
$w.FindName("BtnClean").Add_Click({ Do-Clean })
$w.FindName("BtnDNSG").Add_Click({ Do-DnsGoogle })
$w.FindName("BtnDNSR").Add_Click({ Do-DnsReset })
$w.FindName("BtnExit").Add_Click({ $w.Close() })

# ---------- START ----------
$null = $w.ShowDialog()
