# ==================================================
# ToiUuPC.ps1
# PMK TOOLBOX – CLI FINAL VERSION
# ==================================================

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ==================================================
# PATHS
# ==================================================
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Func = Join-Path $Root "functions"
$Cfg  = Join-Path $Root "config"

# ==================================================
# LOAD FUNCTIONS
# ==================================================
Get-ChildItem $Func -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

# ==================================================
# UI HELPERS
# ==================================================
function Pause {
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Clear {
    Clear-Host
}

# ==================================================
# LOGO
# ==================================================
Show-PMKLogo
Pause

# ==================================================
# WINDOWS TWEAKS
# ==================================================
function Menu-WindowsTweaks {
    Clear
    Write-Host "WINDOWS TWEAKS" -ForegroundColor Cyan
    Write-Host "1. Apply all tweaks"
    Write-Host "2. Revert tweaks"
    Write-Host "0. Back"
    $c = Read-Host "Select"

    switch ($c) {
        "1" {
            Write-Host "`nApplying tweaks..." -ForegroundColor Yellow
            Apply-WindowsTweaks
            Write-Host "Done." -ForegroundColor Green
            Pause
        }
        "2" {
            Write-Host "`nReverting tweaks..." -ForegroundColor Yellow
            Revert-WindowsTweaks
            Write-Host "Done." -ForegroundColor Green
            Pause
        }
    }
}

# ==================================================
# APP INSTALLER
# ==================================================
function Menu-InstallApps {
    Clear
    Write-Host "INSTALL APPLICATIONS" -ForegroundColor Cyan
    Install-Applications -Verbose
    Pause
}

# ==================================================
# DNS MANAGEMENT
# ==================================================
function Menu-DNS {
    Clear
    Write-Host "DNS MANAGEMENT" -ForegroundColor Cyan

    $dnsList = Get-DnsProfiles
    $i = 1
    foreach ($d in $dnsList) {
        Write-Host "$i. $($d.name)"
        $i++
    }
    Write-Host "0. Back"

    $c = Read-Host "Select DNS"
    if ($c -match '^\d+$' -and $c -gt 0) {
        Set-DnsProfile $dnsList[$c-1]
        Write-Host "DNS applied." -ForegroundColor Green
        Pause
    }
}

# ==================================================
# CLEAN SYSTEM
# ==================================================
function Menu-Clean {
    Clear
    Write-Host "SYSTEM CLEANUP" -ForegroundColor Cyan
    Clean-System -Verbose
    Pause
}

# ==================================================
# MAIN MENU LOOP
# ==================================================
while ($true) {

    Clear
    Show-PMKLogo

    Write-Host ""
    Write-Host "1. Windows Tweaks"
    Write-Host "2. Install Applications"
    Write-Host "3. DNS Management"
    Write-Host "4. Clean System"
    Write-Host "0. Exit"
    Write-Host ""

    $choice = Read-Host "Select"

    switch ($choice) {
        "1" { Menu-WindowsTweaks }
        "2" { Menu-InstallApps }
        "3" { Menu-DNS }
        "4" { Menu-Clean }
        "0" { break }
    }
}

Write-Host "Goodbye." -ForegroundColor Green
