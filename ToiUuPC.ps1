param(
    [switch]$Update
)

# ===============================
# ToiUuPC - Main Controller FINAL
# Author: PMK
# ===============================

# ---- UTF-8 FIX ----
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ---- Global ----
$RepoRaw = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"

$WORKDIR  = Join-Path $env:TEMP "ToiUuPC"
$FUNC_DIR = Join-Path $WORKDIR "functions"
$CFG_DIR  = Join-Path $WORKDIR "config"
$LOG_DIR  = Join-Path $WORKDIR "runtime\logs"
$BK_DIR   = Join-Path $WORKDIR "runtime\backups"

# ---- Admin Check ----
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "❌ Vui lòng chạy PowerShell với quyền Administrator" -ForegroundColor Red
    exit 1
}

# ---- Prepare Folders ----
foreach ($dir in @($WORKDIR, $FUNC_DIR, $CFG_DIR, $LOG_DIR, $BK_DIR)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

# ---- Download Helper ----
function Get-RemoteFile {
    param(
        [string]$Url,
        [string]$OutFile
    )
    Write-Host "⬇ $Url" -ForegroundColor DarkGray
    Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
}

# ---- Sync Project ----
function Sync-ToiUuPC {

    Write-Host "`n🔄 Đồng bộ ToiUuPC..." -ForegroundColor Cyan

    $Functions = @(
        "utils.ps1",
        "Show-PMKLogo.ps1",
        "tweaks.ps1",
        "install-apps.ps1",
        "dns-management.ps1",
        "clean-system.ps1"
    )

    foreach ($f in $Functions) {
        Get-RemoteFile "$RepoRaw/functions/$f" (Join-Path $FUNC_DIR $f)
    }

    $Configs = @(
        "tweaks.json",
        "applications.json",
        "dns.json"
    )

    foreach ($c in $Configs) {
        Get-RemoteFile "$RepoRaw/config/$c" (Join-Path $CFG_DIR $c)
    }

    Write-Host "✅ Đồng bộ hoàn tất" -ForegroundColor Green
}

# ---- Initial Sync ----
Sync-ToiUuPC

# ---- SAFE LOAD FUNCTIONS (NO EXECUTION POLICY ISSUE) ----
Get-ChildItem $FUNC_DIR -Filter "*.ps1" | ForEach-Object {
    Invoke-Expression (Get-Content $_.FullName -Raw)
}

# ---- Update Only ----
if ($Update) {
    Write-Host "✅ ToiUuPC đã cập nhật xong" -ForegroundColor Green
    exit 0
}

# ---- UI ----
Clear-Host
if (Get-Command Show-PMKLogo -ErrorAction SilentlyContinue) {
    Show-PMKLogo
}

function Show-MainMenu {
    Write-Host ""
    Write-Host "=========== TOI UU PC ===========" -ForegroundColor Cyan
    Write-Host "1. Tối ưu Windows (Tweaks)"
    Write-Host "2. Cài ứng dụng (Winget)"
    Write-Host "3. Quản lý DNS"
    Write-Host "4. Dọn dẹp hệ thống"
    Write-Host "5. Cập nhật tool"
    Write-Host "0. Thoát"
    Write-Host "================================"
}

# ---- Main Loop ----
while ($true) {

    Show-MainMenu
    $choice = Read-Host "👉 Chọn chức năng"

    switch ($choice) {

        "1" {
            Invoke-SystemTweaks `
                -ConfigPath (Join-Path $CFG_DIR "tweaks.json") `
                -BackupPath $BK_DIR
        }

        "2" {
            Invoke-AppInstaller `
                -ConfigPath (Join-Path $CFG_DIR "applications.json")
        }

        "3" {
            Start-DnsManager `
                -ConfigPath (Join-Path $CFG_DIR "dns.json")
        }

        "4" {
            Invoke-CleanSystem -All
        }

        "5" {
            Write-Host "`n🔄 Đang cập nhật..." -ForegroundColor Yellow
            powershell `
                -NoProfile `
                -ExecutionPolicy Bypass `
                -File "$WORKDIR\ToiUuPC.ps1" -Update
            Write-Host "✅ Cập nhật xong. Vui lòng chạy lại tool." -ForegroundColor Green
            break
        }

        "0" {
            Write-Host "👋 Thoát ToiUuPC" -ForegroundColor Cyan
            break
        }

        default {
            Write-Host "❌ Lựa chọn không hợp lệ" -ForegroundColor Red
        }
    }

    Pause
}
