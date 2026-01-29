# ==================================================
# ToiUuPC.ps1 - FINAL FIXED (MATCH PROJECT STRUCTURE)
# ==================================================

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ==================================================
# FORCE WORKING DIRECTORY = SCRIPT ROOT
# ==================================================
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptRoot

# ==================================================
# PATHS (MATCH TREE)
# ==================================================
$FUNC = Join-Path $ScriptRoot "functions"
$CFG  = Join-Path $ScriptRoot "config"

# ==================================================
# LOAD FUNCTIONS (BẮT BUỘC)
# ==================================================
if (-not (Test-Path $FUNC)) {
    Write-Host "❌ Khong tim thay thu muc functions" -ForegroundColor Red
    exit 1
}

Get-ChildItem $FUNC -Filter *.ps1 | Sort-Object Name | ForEach-Object {
    . $_.FullName
}

# ==================================================
# INIT + ADMIN
# ==================================================
Initialize-ToiUuPCEnvironment
Ensure-Admin

# ==================================================
# MAIN MENU
# ==================================================
function Show-MainMenu {
    Clear-Host
    Show-PMKLogo
    Write-Host ""
    Write-Host "1. Apply Windows Tweaks"
    Write-Host "2. Install Applications"
    Write-Host "3. DNS Management"
    Write-Host "4. Clean System"
    Write-Host "5. Create Restore Point"
    Write-Host "0. Exit"
    Write-Host ""
}

# ==================================================
# MAIN LOOP
# ==================================================
do {
    Show-MainMenu
    $c = Read-Host "Chon"

    switch ($c) {

        "1" {
            $path = Join-Path $CFG "tweaks.json"
            if (-not (Test-Path $path)) {
                Write-Host "❌ Khong tim thay tweaks.json" -ForegroundColor Red
                pause; break
            }
            $cfg = Get-Content $path -Raw | ConvertFrom-Json
            Invoke-TweaksMenu -Config $cfg
            pause
        }

        "2" {
            $path = Join-Path $CFG "applications.json"
            if (-not (Test-Path $path)) {
                Write-Host "❌ Khong tim thay applications.json" -ForegroundColor Red
                pause; break
            }
            $cfg = Get-Content $path -Raw | ConvertFrom-Json
            Invoke-AppMenu -Config $cfg
            pause
        }

        "3" {
            $path = Join-Path $CFG "dns.json"
            if (-not (Test-Path $path)) {
                Write-Host "❌ Khong tim thay dns.json" -ForegroundColor Red
                pause; break
            }
            Invoke-DnsMenu -ConfigPath $path
            pause
        }

        "4" {
            Invoke-CleanMenu
            pause
        }

        "5" {
            New-RestorePoint
            pause
        }

        "0" { break }

        default {
            Write-Host "Lua chon khong hop le"
            Start-Sleep 1
        }
    }

} while ($true)
