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
    }
    else {
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

if (-not $TweaksConfig -or -not $AppsConfig -or -not $DnsConfig) {
    Write-Host "ERROR: One or more config files failed to load" -ForegroundColor Red
    exit 1
}

# ==========================================================
# MENU DATA
# ==========================================================
$MenuItems = @(
    @{ Key = "01"; Text = "Windows Tweaks";      Action = { Invoke-TweaksMenu -Config $TweaksConfig } },
    @{ Key = "02"; Text = "DNS Management";      Action = { Invoke-DnsMenu -ConfigPath (Join-Path $ConfigDir "dns.json") } },
    @{ Key = "03"; Text = "Clean System";        Action = { Invoke-CleanSystem } },
    @{ Key = "51"; Text = "Applications";        Action = { Invoke-AppMenu -Config $AppsConfig } },
    @{ Key = "21"; Text = "Reload Config";       Action = {
            $TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
            $AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
            $DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")
            Write-Host "Config reloaded successfully." -ForegroundColor Green
            Start-Sleep 1
        }
    },
    @{ Key = "00"; Text = "Exit";                Action = { $script:ExitMenu = $true } }
)

# ==========================================================
# RENDER MENU
# ==========================================================
function Render-MainMenu {
    param ($SelectedIndex)

    Clear-Host

    if (Get-Command Show-PMKLogo -ErrorAction SilentlyContinue) {
        Show-PMKLogo
    }

    Write-Host " PMK TOOLBOX – TOI UU WINDOWS" -ForegroundColor Cyan
    Write-Host " Author : MINH KHAI" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "+------------------------------+------------------------------+" -ForegroundColor DarkGray
    Write-Host "|  SYSTEM / TOOLS              |  ACTION                     |" -ForegroundColor Gray
    Write-Host "|------------------------------|------------------------------|" -ForegroundColor DarkGray

    for ($i = 0; $i -lt $MenuItems.Count; $i++) {
        $item = $MenuItems[$i]

        $line = "| [{0}] {1,-22} |                              |" -f $item.Key, $item.Text

        if ($i -eq $SelectedIndex) {
            Write-Host $line -ForegroundColor Black -BackgroundColor Cyan
        }
        else {
            Write-Host $line -ForegroundColor White
        }
    }

    Write-Host "+------------------------------+------------------------------+" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host " ↑ ↓ : Navigate   |  Enter : Select   |  Number : Direct select" -ForegroundColor DarkGray
}

# ==========================================================
# MAIN LOOP (REAL-TIME ↑↓)
# ==========================================================
$SelectedIndex = 0
$ExitMenu = $false
$NumberBuffer = ""

while (-not $ExitMenu) {

    Render-MainMenu -SelectedIndex $SelectedIndex

    $key = [Console]::ReadKey($true)

    switch ($key.Key) {

        'UpArrow' {
            if ($SelectedIndex -gt 0) { $SelectedIndex-- }
        }

        'DownArrow' {
            if ($SelectedIndex -lt ($MenuItems.Count - 1)) { $SelectedIndex++ }
        }

        'Enter' {
            & $MenuItems[$SelectedIndex].Action
        }

        default {
            if ($key.KeyChar -match '\d') {
                $NumberBuffer += $key.KeyChar

                $match = $MenuItems | Where-Object { $_.Key -eq $NumberBuffer }
                if ($match) {
                    & $match.Action
                    $NumberBuffer = ""
                }

                if ($NumberBuffer.Length -ge 2) {
                    $NumberBuffer = ""
                }
            }
            else {
                $NumberBuffer = ""
            }
        }
    }
}

Clear-Host
Write-Host "Exit PMK Toolbox." -ForegroundColor Cyan
