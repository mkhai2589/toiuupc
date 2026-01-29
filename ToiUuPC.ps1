param([switch]$Update)

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ===============================
# GLOBAL
# ===============================
$RepoRaw = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"

$ROOT = Join-Path $env:TEMP "ToiUuPC"
$FUNC = Join-Path $ROOT "functions"
$CFG  = Join-Path $ROOT "config"
$RUN  = Join-Path $ROOT "runtime"
$LOG  = Join-Path $RUN  "logs"
$BK   = Join-Path $RUN  "backups"

# ===============================
# ADMIN CHECK
# ===============================
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "Please run PowerShell as Administrator"
    pause
    exit 1
}

# ===============================
# PREPARE FOLDERS
# ===============================
foreach ($d in @($ROOT,$FUNC,$CFG,$RUN,$LOG,$BK)) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d | Out-Null
    }
}

# ===============================
# DOWNLOAD HELPER
# ===============================
function Get-RemoteFile {
    param([string]$Url,[string]$Out)
    Invoke-WebRequest $Url -OutFile $Out -UseBasicParsing
}

# ===============================
# SYNC PROJECT
# ===============================
function Sync-ToiUuPC {

    Write-Host "Dang dong bo ToiUuPC..."

    $FunctionFiles = @(
        "utils.ps1",
        "Show-PMKLogo.ps1",
        "tweaks.ps1",
        "install-apps.ps1",
        "dns-management.ps1",
        "clean-system.ps1"
    )

    foreach ($f in $FunctionFiles) {
        Get-RemoteFile "$RepoRaw/functions/$f" (Join-Path $FUNC $f)
    }

    $ConfigFiles = @(
        "tweaks.json",
        "applications.json",
        "dns.json"
    )

    foreach ($c in $ConfigFiles) {
        Get-RemoteFile "$RepoRaw/config/$c" (Join-Path $CFG $c)
    }

    Write-Host "Dong bo hoan tat"
}

# ===============================
# INIT
# ===============================
Sync-ToiUuPC

Get-ChildItem $FUNC -Filter "*.ps1" | ForEach-Object {
    . $_.FullName
}

if ($Update) {
    Write-Host "Cap nhat hoan tat"
    exit 0
}

# ===============================
# UI
# ===============================
Clear-Host
Show-PMKLogo

function Show-MainMenu {
    Write-Host ""
    Write-Host "=============================="
    Write-Host "          TOI UU PC           "
    Write-Host "=============================="
    Write-Host "1. Toi uu Windows"
    Write-Host "2. Cai ung dung"
    Write-Host "3. Quan ly DNS"
    Write-Host "4. Don dep he thong"
    Write-Host "5. Cap nhat ToiUuPC"
    Write-Host "0. Thoat"
    Write-Host "=============================="
}

# ===============================
# MAIN LOOP
# ===============================
while ($true) {

    Show-MainMenu
    $choice = Read-Host "Chon chuc nang"

    switch ($choice) {

        "1" {
            Write-Host "Dang toi uu Windows..."
            Invoke-SystemTweaks `
                -ConfigPath (Join-Path $CFG "tweaks.json")
            Write-Host "Hoan tat toi uu"
        }

        "2" {
            Write-Host "Dang cai ung dung..."
            Invoke-AppInstaller `
                -ConfigPath (Join-Path $CFG "applications.json")
            Write-Host "Cai ung dung hoan tat"
        }

        "3" {
            Start-DnsManager `
                -ConfigPath (Join-Path $CFG "dns.json")
        }

        "4" {
            Write-Host ""
            Write-Host "1. Don dep tat ca"
            Write-Host "2. Don temp"
            Write-Host "3. Don Windows Update"
            Write-Host "4. Don log he thong"
            Write-Host "5. Don Recycle Bin"
            Write-Host "6. Don browser cache"
            Write-Host "7. WinSxS nang cao"
            Write-Host "0. Quay lai"

            $c = Read-Host "Chon che do don dep"

            switch ($c) {
                "1" { Invoke-CleanSystem -All }
                "2" { Invoke-CleanSystem -Temp }
                "3" { Invoke-CleanSystem -Update }
                "4" { Invoke-CleanSystem -Logs }
                "5" { Invoke-CleanSystem -RecycleBin }
                "6" { Invoke-CleanSystem -Browser }
                "7" {
                    Write-Host "Canh bao: WinSxS khong rollback"
                    $ok = Read-Host "Nhap y de tiep tuc"
                    if ($ok -eq "y") {
                        Invoke-CleanSystem -WinSxS
                    }
                }
            }
        }

        "5" {
            Write-Host "Dang cap nhat ToiUuPC..."
            powershell `
                -NoProfile `
                -ExecutionPolicy Bypass `
                -File "$ROOT\ToiUuPC.ps1" -Update
            Write-Host "Cap nhat xong, hay chay lai tool"
            break
        }

        "0" {
            Write-Host "Thoat ToiUuPC"
            break
        }

        default {
            Write-Host "Lua chon khong hop le"
        }
    }

    pause
}
