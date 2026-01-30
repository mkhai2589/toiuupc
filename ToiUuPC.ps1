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
# MENU RENDER
# ==========================================================
function Show-MainMenu {

    Clear-Screen

    if (Get-Command Show-PMKLogo -ErrorAction SilentlyContinue) {
        Show-PMKLogo
    }

    Write-Host " PMK TOOLBOX – TOI UU WINDOWS" -ForegroundColor Cyan
    Write-Host " Author : MINH KHAI" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "+------------------------------+------------------------------+" -ForegroundColor DarkGray
    Write-Host "|  SYSTEM / NETWORK            |  INSTALLER                  |" -ForegroundColor Gray
    Write-Host "|------------------------------|------------------------------|" -ForegroundColor DarkGray
    Write-Host "| [01] Windows Tweaks          | [51] Applications            |" -ForegroundColor White
    Write-Host "| [02] DNS Management          |                              |" -ForegroundColor White
    Write-Host "| [03] Clean System            |                              |" -ForegroundColor White
    Write-Host "+------------------------------+------------------------------+" -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "+------------------------------+------------------------------+" -ForegroundColor DarkGray
    Write-Host "|  OTHER                       |  EXIT                       |" -ForegroundColor Gray
    Write-Host "|------------------------------|------------------------------|" -ForegroundColor DarkGray
    Write-Host "| [21] Reload Config           | [00] Exit                    |" -ForegroundColor White
    Write-Host "+------------------------------+------------------------------+" -ForegroundColor DarkGray
}

# ==========================================================
# MAIN LOOP
# ==========================================================
while ($true) {

    Show-MainMenu
    $choice = Read-Host "Select option"

    switch ($choice) {

        "1"  { Invoke-TweaksMenu -Config $TweaksConfig }
        "01" { Invoke-TweaksMenu -Config $TweaksConfig }

        "2"  { Invoke-DnsMenu -ConfigPath (Join-Path $ConfigDir "dns.json") }
        "02" { Invoke-DnsMenu -ConfigPath (Join-Path $ConfigDir "dns.json") }

        "3"  { Invoke-CleanSystem }
        "03" { Invoke-CleanSystem }

        "51" { Invoke-AppMenu -Config $AppsConfig }

        "21" {
            $TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
            $AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
            $DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")
            Write-Host "Config reloaded successfully." -ForegroundColor Green
            Start-Sleep 1
        }

        "0"  { break }
        "00" { break }

        default {
            Write-Host "Invalid option." -ForegroundColor Yellow
            Start-Sleep 1
        }
    }
}

Clear-Host
Write-Host "Exit PMK Toolbox." -ForegroundColor Cyan
