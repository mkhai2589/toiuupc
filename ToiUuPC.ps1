# ==========================================================
# ToiUuPC.ps1
# PMK TOOLBOX – Toi Uu Windows
# Author: Minh Khai
# ==========================================================

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ==========================================================
# ROOT
# ==========================================================
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# ==========================================================
# LOAD CORE UTILS FIRST
# ==========================================================
$utilsPath = Join-Path $ScriptRoot "functions\utils.ps1"
if (-not (Test-Path $utilsPath)) {
    Write-Host "ERROR: utils.ps1 not found" -ForegroundColor Red
    exit 1
}
. $utilsPath

Ensure-Admin

# ==========================================================
# LOAD ALL FUNCTION MODULES
# ==========================================================
$FunctionFiles = @(
    "Show-PMKLogo.ps1",
    "tweaks.ps1",
    "install-apps.ps1",
    "dns-management.ps1",
    "clean-system.ps1"
)

foreach ($file in $FunctionFiles) {
    $path = Join-Path $ScriptRoot "functions\$file"
    if (Test-Path $path) {
        . $path
    } else {
        Write-Host "ERROR: Missing function file: $file" -ForegroundColor Red
        exit 1
    }
}

# ==========================================================
# LOAD CONFIG FILES
# ==========================================================
$ConfigDir = Join-Path $ScriptRoot "config"

$TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
$AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
$DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")

# ==========================================================
# HEADER STATUS (NO MENU REDRAW)
# ==========================================================
function Draw-Header {

    $user = $env:USERNAME
    $os   = (Get-CimInstance Win32_OperatingSystem).Caption
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $principal = New-Object Security.Principal.WindowsPrincipal `
        ([Security.Principal.WindowsIdentity]::GetCurrent())

    $mode = if ($principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
        "ADMIN"
    } else {
        "USER"
    }

    $net = if (Get-NetAdapter | Where-Object Status -eq "Up") {
        "ONLINE"
    } else {
        "OFFLINE"
    }

    [Console]::SetCursorPosition(0,0)
    Write-Host (" USER:{0} | OS:{1}" -f $user, $os) -ForegroundColor Cyan
    Write-Host (" NET:{0} | MODE:{1} | TIME:{2}" -f $net, $mode, $time) -ForegroundColor DarkGray
    Write-Host ""
}

# ==========================================================
# MENU DATA
# ==========================================================
$MenuItems = @(
    @{ Key="01"; Text="Windows Tweaks"; Action={ Invoke-TweaksMenu -Config $TweaksConfig } },
    @{ Key="02"; Text="DNS Management"; Action={ Invoke-DnsMenu -ConfigPath (Join-Path $ConfigDir "dns.json") } },
    @{ Key="03"; Text="Clean System";   Action={ Invoke-CleanSystem } },
    @{ Key="51"; Text="Applications";   Action={ Invoke-AppMenu -Config $AppsConfig } },
    @{ Key="21"; Text="Reload Config";  Action={
        $TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
        $AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
        $DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")
    }},
    @{ Key="00"; Text="Exit"; Action={ $script:ExitMenu = $true } }
)

# ==========================================================
# RENDER MENU (FIXED POSITION)
# ==========================================================
function Render-MainMenu {
    param ($SelectedIndex)

    [Console]::SetCursorPosition(0,4)

    Write-Host "+------------------------------+------------------------------+" -ForegroundColor DarkGray
    Write-Host "|  SYSTEM / TOOLS              |  ACTION                     |" -ForegroundColor Gray
    Write-Host "|------------------------------|------------------------------|" -ForegroundColor DarkGray

    for ($i=0; $i -lt $MenuItems.Count; $i++) {
        $item = $MenuItems[$i]
        $line = "| [{0}] {1,-22} |                              |" -f $item.Key, $item.Text

        if ($i -eq $SelectedIndex) {
            Write-Host $line -ForegroundColor Black -BackgroundColor Cyan
        } else {
            Write-Host $line -ForegroundColor White
        }
    }

    Write-Host "+------------------------------+------------------------------+" -ForegroundColor DarkGray
    Write-Host " ↑ ↓ Navigate | Enter Select | Number Direct" -ForegroundColor DarkGray
}

# ==========================================================
# MAIN LOOP
# ==========================================================
Clear-Host
$SelectedIndex = 0
$ExitMenu = $false
$NumberBuffer = ""
$LastHeader = Get-Date

while (-not $ExitMenu) {

    if ((Get-Date) - $LastHeader -gt [TimeSpan]::FromSeconds(1)) {
        Draw-Header
        $LastHeader = Get-Date
    }

    Render-MainMenu -SelectedIndex $SelectedIndex

    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            'UpArrow'   { if ($SelectedIndex -gt 0) { $SelectedIndex-- } }
            'DownArrow' { if ($SelectedIndex -lt ($MenuItems.Count-1)) { $SelectedIndex++ } }
            'Enter'     { & $MenuItems[$SelectedIndex].Action }
            default {
                if ($key.KeyChar -match '\d') {
                    $NumberBuffer += $key.KeyChar
                    $match = $MenuItems | Where-Object Key -eq $NumberBuffer
                    if ($match) {
                        & $match.Action
                        $NumberBuffer = ""
                    }
                    if ($NumberBuffer.Length -ge 2) { $NumberBuffer = "" }
                } else {
                    $NumberBuffer = ""
                }
            }
        }
    }

    Start-Sleep -Milliseconds 50
}

Clear-Host
Write-Host "Exit PMK Toolbox." -ForegroundColor Cyan
