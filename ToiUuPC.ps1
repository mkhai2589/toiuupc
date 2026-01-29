# =========================================================
# ToiUuPC – Windows 10 / 11 Optimization Toolkit
# Main Controller + Bootstrap
# Author: PMK
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# ---------------- ADMIN CHECK ----------------
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "❌ Vui lòng chạy PowerShell với quyền Administrator" -ForegroundColor Red
    exit 1
}

# ---------------- DETECT RUN MODE ----------------
$IsRemote = (-not $PSScriptRoot) -and (-not $MyInvocation.MyCommand.Path)

if (-not $IsRemote) {
    $Root = $PSScriptRoot ?? (Split-Path -Parent $MyInvocation.MyCommand.Path)
}
else {
    $Root = Join-Path $env:TEMP "ToiUuPC"
}

# ---------------- PATHS ----------------
$Functions = Join-Path $Root "functions"
$Config    = Join-Path $Root "config"
$Assets    = Join-Path $Root "assets"
$Logs      = Join-Path $Root "logs"
$Backups   = Join-Path $Root "backups"

# ---------------- ENSURE FOLDERS ----------------
$Folders = @($Functions, $Config, $Assets, $Logs, $Backups)
foreach ($f in $Folders) {
    if (-not (Test-Path $f)) {
        New-Item -ItemType Directory -Path $f -Force | Out-Null
    }
}

# ---------------- GITHUB SOURCE ----------------
$RepoRaw = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"

$RequiredFiles = @{
    "functions\utils.ps1"            = "functions/utils.ps1"
    "functions\Show-PMKLogo.ps1"     = "functions/Show-PMKLogo.ps1"
    "functions\tweaks.ps1"           = "functions/tweaks.ps1"
    "functions\install-apps.ps1"     = "functions/install-apps.ps1"
    "functions\dns-management.ps1"   = "functions/dns-management.ps1"
    "functions\clean-system.ps1"     = "functions/clean-system.ps1"
    "config\tweaks.json"             = "config/tweaks.json"
    "config\applications.json"       = "config/applications.json"
}

# ---------------- UPDATE MODE ----------------
if ($args -contains "--update") {
    Write-Host "🔄 Đang cập nhật ToiUuPC..." -ForegroundColor Cyan
    Remove-Item $Functions, $Config -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------------- BOOTSTRAP DOWNLOAD ----------------
if ($IsRemote -or ($args -contains "--update")) {

    Write-Host "🌐 Đang đồng bộ thành phần ToiUuPC..." -ForegroundColor Cyan

    foreach ($item in $RequiredFiles.GetEnumerator()) {

        $localPath  = Join-Path $Root $item.Key
        $remotePath = "$RepoRaw/$($item.Value)"

        if (-not (Test-Path $localPath)) {
            try {
                Invoke-RestMethod $remotePath -OutFile $localPath -UseBasicParsing
            }
            catch {
                Write-Host "❌ Không tải được: $remotePath" -ForegroundColor Red
                exit 1
            }
        }
    }
}

Write-Host "📁 Workspace: $Root" -ForegroundColor DarkGray

# ---------------- LOAD FUNCTIONS ----------------
$FunctionFiles = @(
    "utils.ps1"
    "Show-PMKLogo.ps1"
    "tweaks.ps1"
    "install-apps.ps1"
    "dns-management.ps1"
    "clean-system.ps1"
)

foreach ($file in $FunctionFiles) {
    $path = Join-Path $Functions $file
    if (Test-Path $path) {
        . $path
    }
    else {
        Write-Host "❌ Thiếu file: $file" -ForegroundColor Red
        exit 1
    }
}

# ---------------- MAIN MENU ----------------
function Show-MainMenu {
    Clear-Host
    if (Get-Command Show-PMKLogo -ErrorAction SilentlyContinue) {
        Show-PMKLogo
    }

    Write-Host "=================================================" -ForegroundColor DarkGray
    Write-Host "  ToiUuPC – Tối ưu Windows 10 / 11" -ForegroundColor Cyan
    Write-Host "=================================================`n"

    Write-Host "1. Tối ưu hệ thống (Tweaks)"
    Write-Host "2. Cài đặt ứng dụng (Winget)"
    Write-Host "3. Thiết lập DNS"
    Write-Host "4. Dọn dẹp hệ thống"
    Write-Host "5. Rollback tweaks"
    Write-Host "6. Cập nhật ToiUuPC"
    Write-Host "0. Thoát`n"
}

# ---------------- MAIN LOOP ----------------
while ($true) {

    Show-MainMenu
    $choice = Read-Host "👉 Chọn chức năng"

    switch ($choice) {

        "1" {
            Clear-Host
            Invoke-Tweaks
            Pause
        }

        "2" {
            Clear-Host
            Invoke-InstallApps
            Pause
        }

        "3" {
            Clear-Host
            Invoke-DNSManager
            Pause
        }

        "4" {
            Clear-Host
            Invoke-SystemCleanup
            Pause
        }

        "5" {
            Clear-Host
            Invoke-Tweaks -Rollback
            Pause
        }

        "6" {
            Write-Host "🔄 Đang cập nhật..." -ForegroundColor Cyan
            & powershell -NoProfile -Command {
                irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex --update
            }
            break
        }

        "0" {
            Write-Host "`n👋 Thoát ToiUuPC. Hẹn gặp lại!" -ForegroundColor Green
            break
        }

        default {
            Write-Host "❌ Lựa chọn không hợp lệ" -ForegroundColor Red
            Start-Sleep 1
        }
    }
}
