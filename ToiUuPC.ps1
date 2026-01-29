# ==================================================
# ToiUuPC.ps1 - FINAL STABLE VERSION
# Windows Optimization Tool
# ==================================================

# ---------- UTF8 ----------
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ---------- ADMIN CHECK ----------
function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "❌ Vui long chay PowerShell bang quyen Administrator" -ForegroundColor Red
    pause
    exit
}

# ---------- GLOBAL PATH ----------
$RepoRaw = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"

$ROOT = Join-Path $env:TEMP "ToiUuPC"
$FUNC = Join-Path $ROOT "functions"
$CFG  = Join-Path $ROOT "config"
$RUN  = Join-Path $ROOT "runtime"
$LOG  = Join-Path $RUN  "toiuupc.log"
$BK   = Join-Path $RUN  "backup"

# ---------- ENSURE DIR ----------
foreach ($dir in @($ROOT,$FUNC,$CFG,$RUN,$BK)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# ---------- LOG ----------
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts [$Level] $Message" | Out-File $LOG -Append -Encoding UTF8
    Write-Host "[$Level] $Message"
}

# ---------- DOWNLOAD ----------
function Download-File {
    param($Url,$Out)
    try {
        Invoke-WebRequest $Url -OutFile $Out -UseBasicParsing -ErrorAction Stop
        Write-Log "Downloaded $(Split-Path $Out -Leaf)"
        return $true
    } catch {
        Write-Log "Download failed: $Url" "ERROR"
        return $false
    }
}

# ==================================================
# SYNC PROJECT
# ==================================================
function Sync-ToiUuPC {

    Write-Host "`nDang dong bo ToiUuPC..." -ForegroundColor Cyan

    $FunctionFiles = @(
        "utils.ps1",
        "Show-PMKLogo.ps1",
        "tweaks.ps1",
        "install-apps.ps1",
        "dns-management.ps1",
        "clean-system.ps1"
    )

    foreach ($f in $FunctionFiles) {
        Download-File "$RepoRaw/functions/$f" (Join-Path $FUNC $f) | Out-Null
    }

    $ConfigFiles = @(
        "tweaks.json",
        "applications.json",
        "dns.json"
    )

    foreach ($c in $ConfigFiles) {
        Download-File "$RepoRaw/config/$c" (Join-Path $CFG $c) | Out-Null
    }

    Write-Host "Dong bo hoan tat" -ForegroundColor Green
}

# ==================================================
# LOAD FUNCTIONS
# ==================================================
function Load-Functions {
    Write-Host "`nDang nap function modules..." -ForegroundColor Cyan

    Get-ChildItem $FUNC -Filter *.ps1 | ForEach-Object {
        try {
            . $_.FullName
            Write-Log "Loaded $($_.Name)"
        } catch {
            Write-Log "Load failed $($_.Name)" "ERROR"
        }
    }
}

# ==================================================
# RESTORE POINT (SAFE)
# ==================================================
function New-RestorePoint-Safe {
    Write-Host "Dang tao Restore Point..." -ForegroundColor Yellow
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "ToiUuPC Restore Point" -RestorePointType MODIFY_SETTINGS
        Write-Log "Restore point created"
    } catch {
        Write-Log "Restore point skipped (service disabled)" "WARN"
    }
}

# ==================================================
# MENU
# ==================================================
function Show-MainMenu {
    Clear-Host
    Show-PMKLogo

    Write-Host "==============================="
    Write-Host "1. Apply Windows Tweaks"
    Write-Host "2. Install Applications"
    Write-Host "3. DNS Management"
    Write-Host "4. Clean System"
    Write-Host "5. Create Restore Point"
    Write-Host "0. Exit"
    Write-Host "==============================="
}

# ==================================================
# MAIN
# ==================================================
Sync-ToiUuPC
Load-Functions

Write-Log "ToiUuPC Started"

do {
    Show-MainMenu
    $choice = Read-Host "Chon chuc nang"

    switch ($choice) {

        "1" {
            $cfg = Get-Content "$CFG\tweaks.json" -Raw | ConvertFrom-Json
            Invoke-TweaksMenu -Config $cfg
            pause
        }

        "2" {
            $cfg = Get-Content "$CFG\applications.json" -Raw | ConvertFrom-Json
            Invoke-AppMenu -Config $cfg
            pause
        }

        "3" {
            Invoke-DnsMenu
            pause
        }

        "4" {
            Invoke-CleanMenu
            pause
        }

        "5" {
            New-RestorePoint-Safe
            pause
        }

        "0" {
            Write-Log "Exit ToiUuPC"
            break
        }

        default {
            Write-Host "Lua chon khong hop le"
            Start-Sleep 1
        }
    }

} while ($true)
