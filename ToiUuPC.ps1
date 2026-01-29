# ==================================================
# ToiUuPC.ps1 - FINAL FULL VERSION (FIXED)
# Windows 10/11 Optimization Tool
# ==================================================

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ==================================================
# ADMIN CHECK
# ==================================================
function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "Vui long chay PowerShell bang quyen Administrator" -ForegroundColor Red
    pause
    exit 1
}

# ==================================================
# PATHS
# ==================================================
$RepoRaw = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"

$ROOT = Join-Path $env:TEMP "ToiUuPC"
$FUNC = Join-Path $ROOT "functions"
$CFG  = Join-Path $ROOT "config"
$RUN  = Join-Path $ROOT "runtime"
$LOG  = Join-Path $RUN  "toiuupc.log"
$BK   = Join-Path $RUN  "backup"

foreach ($d in @($ROOT,$FUNC,$CFG,$RUN,$BK)) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }
}
if (-not (Test-Path $LOG)) {
    New-Item -ItemType File -Path $LOG -Force | Out-Null
}

# ==================================================
# BASIC LOG
# ==================================================
function Write-BootLog {
    param([string]$Message,[string]$Level="INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts [$Level] $Message" | Out-File $LOG -Append -Encoding UTF8
    Write-Host "[$Level] $Message"
}

Write-BootLog "ToiUuPC starting..."

# ==================================================
# DOWNLOAD
# ==================================================
function Download-File {
    param([string]$Url,[string]$OutFile)
    try {
        Invoke-WebRequest $Url -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
        Write-BootLog "Downloaded $(Split-Path $OutFile -Leaf)"
        return $true
    } catch {
        Write-BootLog "Download failed $Url" "ERROR"
        return $false
    }
}

# ==================================================
# SYNC
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

    foreach ($c in @("tweaks.json","applications.json","dns.json")) {
        Download-File "$RepoRaw/config/$c" (Join-Path $CFG $c) | Out-Null
    }

    Write-Host "Dong bo hoan tat" -ForegroundColor Green
}

# ==================================================
# LOAD FUNCTIONS
# ==================================================
function Load-Functions {
    Get-ChildItem $FUNC -Filter *.ps1 | ForEach-Object {
        try {
            . $_.FullName
            Write-BootLog "Loaded $($_.Name)"
        } catch {
            Write-BootLog "Load failed $($_.Name)" "ERROR"
        }
    }
}

# ==================================================
# MENU FUNCTIONS (FIX THIEU)
# ==================================================
function Invoke-TweaksMenu {
    param($Config)

    Write-Host "`nDang ap dung tat ca Tweaks..." -ForegroundColor Yellow
    $ids = $Config.tweaks | ForEach-Object { $_.id }

    Invoke-SystemTweaks `
        -Tweaks $Config.tweaks `
        -SelectedIds $ids `
        -BackupPath $BK `
        -ProgressBar $null
}

function Invoke-AppMenu {
    param($Config)

    Write-Host "`nDang cai ung dung..." -ForegroundColor Yellow
    $ids = $Config.applications | ForEach-Object { $_.id }

    Invoke-AppInstaller `
        -Config $Config `
        -SelectedIds $ids `
        -ProgressBar $null
}

function Invoke-DnsMenu {
    param($ConfigPath)
    Start-DnsManager -ConfigPath $ConfigPath
}

function Invoke-CleanMenu {
    Invoke-CleanSystem -All
}

function New-RestorePoint {
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "ToiUuPC Restore Point" -RestorePointType MODIFY_SETTINGS
        Write-Log "Restore point created"
    } catch {
        Write-Log "Restore point skipped" "WARN"
    }
}

# ==================================================
# MAIN MENU
# ==================================================
function Show-MainMenu {
    Clear-Host
    if (Get-Command Show-PMKLogo -ErrorAction SilentlyContinue) {
        Show-PMKLogo
    }

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
# START
# ==================================================
Sync-ToiUuPC
Load-Functions
Initialize-ToiUuPCEnvironment
Ensure-Admin

Write-Log "ToiUuPC ready"

# ==================================================
# LOOP
# ==================================================
do {
    Show-MainMenu
    $c = Read-Host "Chon"

    switch ($c) {
        "1" {
            $cfg = Get-Content "$CFG\tweaks.json" -Raw | ConvertFrom-Json
            Invoke-TweaksMenu $cfg
            pause
        }
        "2" {
            $cfg = Get-Content "$CFG\applications.json" -Raw | ConvertFrom-Json
            Invoke-AppMenu $cfg
            pause
        }
        "3" {
            Invoke-DnsMenu "$CFG\dns.json"
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
