# =========================================================
# ToiUuPC – Windows 10 / 11 Optimization Toolkit
# Bootstrap + Controller
# Author: PMK
# =========================================================

# ⚠️ ENTRY SCRIPT: KHÔNG STRICT MODE
Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ---------------- CONSTANTS ----------------
$REPO_RAW = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"
$WORKDIR  = Join-Path $env:TEMP "ToiUuPC"

$DIRS = @{
    Root      = $WORKDIR
    Functions = Join-Path $WORKDIR "functions"
    Config    = Join-Path $WORKDIR "config"
    Logs      = Join-Path $WORKDIR "logs"
    Backups   = Join-Path $WORKDIR "backups"
}

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

# ---------------- ARGS ----------------
param(
    [switch]$Update
)

# ---------------- PREPARE DIR ----------------
foreach ($d in $DIRS.Values) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }
}

# ---------------- DOWNLOAD HELPER ----------------
function Get-RemoteFile {
    param(
        [string]$Url,
        [string]$OutFile
    )

    try {
        Invoke-RestMethod -Uri $Url -UseBasicParsing -ErrorAction Stop |
            Out-File -FilePath $OutFile -Encoding UTF8 -Force
    } catch {
        Write-Host "❌ Không tải được: $Url" -ForegroundColor Red
        throw
    }
}

# ---------------- FILE MANIFEST ----------------
$FILES = @{
    "functions/utils.ps1"         = "functions\utils.ps1"
    "functions/Show-PMKLogo.ps1"  = "functions\Show-PMKLogo.ps1"
    "functions/tweaks.ps1"        = "functions\tweaks.ps1"
    "functions/install-apps.ps1"  = "functions\install-apps.ps1"
    "functions/dns-management.ps1"= "functions\dns-management.ps1"
    "functions/clean-system.ps1"  = "functions\clean-system.ps1"
    "config/tweaks.json"          = "config\tweaks.json"
    "config/applications.json"    = "config\applications.json"
}

# ---------------- UPDATE / FIRST BOOTSTRAP ----------------
if ($Update -or -not (Test-Path (Join-Path $DIRS.Functions "utils.ps1"))) {

    Write-Host "⬇ Đang tải ToiUuPC..." -ForegroundColor Cyan

    foreach ($key in $FILES.Keys) {
        $dest = Join-Path $DIRS.Root $FILES[$key]
        $url  = "$REPO_RAW/$key"
        Get-RemoteFile -Url $url -OutFile $dest
    }

    Write-Host "✅ Đã cập nhật ToiUuPC" -ForegroundColor Green

    if ($Update) {
        Write-Host "🔁 Vui lòng chạy lại lệnh để sử dụng phiên bản mới" -ForegroundColor Yellow
        return
    }
}

# ---------------- LOAD FUNCTIONS ----------------
Get-ChildItem $DIRS.Functions -Filter *.ps1 | ForEach-Object {
    . $_.FullName
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

    Write-Host "1. ⚙️ Tối ưu hệ thống (Tweaks)"
    Write-Host "2. 📦 Cài đặt ứng dụng (Winget)"
    Write-Host "3. 🌐 Thiết lập DNS"
    Write-Host "4. 🧹 Dọn dẹp hệ thống"
    Write-Host "5. 🔄 Rollback tweaks"
    Write-Host "6. 🔄 Cập nhật ToiUuPC"
    Write-Host "0. ❌ Thoát`n"
}

# ---------------- MAIN LOOP ----------------
while ($true) {

    Show-MainMenu
    $choice = Read-Host "👉 Chọn chức năng"

    switch ($choice) {

        "1" {
            Invoke-Tweaks
            Pause
        }

        "2" {
            Invoke-InstallApps
            Pause
        }

        "3" {
            Invoke-DNSManager
            Pause
        }

        "4" {
            Invoke-SystemCleanup
            Pause
        }

        "5" {
            Invoke-Tweaks -Rollback
            Pause
        }

        "6" {
            Write-Host "🔄 Đang cập nhật..." -ForegroundColor Cyan
            & powershell -NoProfile -ExecutionPolicy Bypass `
                -Command "irm $REPO_RAW/ToiUuPC.ps1 | iex -Update"
            return
        }

        "0" {
            Write-Host "`n👋 Thoát ToiUuPC" -ForegroundColor Green
            break
        }

        default {
            Write-Host "❌ Lựa chọn không hợp lệ" -ForegroundColor Red
            Start-Sleep 1
        }
    }
}
