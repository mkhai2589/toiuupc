# ==================================================
# ToiUuPC.ps1 - FINAL STABLE VERSION
# Windows 10 / 11 Optimization Tool (CLI Core)
# Author: PMK
# ==================================================

# ---------------- UTF8 ----------------
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ==================================================
# ADMIN CHECK (EARLY)
# ==================================================
function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p  = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

if (-not (Test-IsAdmin)) {
    Write-Host "❌ Vui long chay PowerShell bang quyen Administrator" -ForegroundColor Red
    pause
    exit 1
}

# ==================================================
# ROOT PATHS (PROJECT RELATIVE)
# ==================================================
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$FUNC = Join-Path $ScriptRoot "functions"
$CFG  = Join-Path $ScriptRoot "config"

# ==================================================
# LOAD CORE FUNCTIONS
# ==================================================
if (-not (Test-Path $FUNC)) {
    Write-Host "❌ Khong tim thay thu muc functions" -ForegroundColor Red
    exit 1
}

Get-ChildItem $FUNC -Filter *.ps1 | Sort-Object Name | ForEach-Object {
    try {
        . $_.FullName
        Write-Host "Loaded: $($_.Name)" -ForegroundColor DarkGray
    } catch {
        Write-Host "❌ Loi load $($_.Name)" -ForegroundColor Red
        exit 1
    }
}

# ==================================================
# INIT ENV + ADMIN ENSURE
# ==================================================
Initialize-ToiUuPCEnvironment
Ensure-Admin

Write-Log "ToiUuPC started"

# ==================================================
# MAIN MENU UI
# ==================================================
function Show-MainMenu {
    Clear-Host

    if (Get-Command Show-PMKLogo -ErrorAction SilentlyContinue) {
        Show-PMKLogo
    }

    Write-Host ""
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host "1. Apply Windows Tweaks"
    Write-Host "2. Install Applications"
    Write-Host "3. DNS Management"
    Write-Host "4. Clean System"
    Write-Host "5. Create Restore Point"
    Write-Host "0. Exit"
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host ""
}

# ==================================================
# MAIN LOOP
# ==================================================
do {
    Show-MainMenu
    $choice = Read-Host "Chon chuc nang"

    switch ($choice) {

        "1" {
            if (-not (Test-Path "$CFG\tweaks.json")) {
                Write-Host "❌ Khong tim thay tweaks.json" -ForegroundColor Red
                pause
                break
            }

            $cfg = Get-Content "$CFG\tweaks.json" -Raw | ConvertFrom-Json
            Invoke-TweaksMenu -Config $cfg
            pause
        }

        "2" {
            if (-not (Test-Path "$CFG\applications.json")) {
                Write-Host "❌ Khong tim thay applications.json" -ForegroundColor Red
                pause
                break
            }

            $cfg = Get-Content "$CFG\applications.json" -Raw | ConvertFrom-Json
            Invoke-AppMenu -Config $cfg
            pause
        }

        "3" {
            if (-not (Test-Path "$CFG\dns.json")) {
                Write-Host "❌ Khong tim thay dns.json" -ForegroundColor Red
                pause
                break
            }

            Invoke-DnsMenu -ConfigPath "$CFG\dns.json"
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

        "0" {
            Write-Log "ToiUuPC exited"
            Write-Host "👋 Tam biet!" -ForegroundColor Green
            break
        }

        default {
            Write-Host "Lua chon khong hop le" -ForegroundColor Yellow
            Start-Sleep 1
        }
    }

} while ($true)
