# ===============================
# ToiUuPC Bootstrap (FINAL)
# ===============================

# ---- UTF-8 FIX (MANDATORY) ----
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ---- Admin Check ----
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "❌ Vui lòng chạy PowerShell với quyền Administrator" -ForegroundColor Red
    Pause
    exit 1
}

# ---- Paths ----
$RepoRaw = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"
$WORKDIR = Join-Path $env:TEMP "ToiUuPC"

$MainFile = Join-Path $WORKDIR "ToiUuPC.ps1"

# ---- Prepare Folder ----
if (-not (Test-Path $WORKDIR)) {
    New-Item -ItemType Directory -Path $WORKDIR | Out-Null
}

# ---- Download Main ----
Write-Host "⬇ Đang tải ToiUuPC..." -ForegroundColor Cyan
Invoke-WebRequest `
    -Uri "$RepoRaw/ToiUuPC.ps1" `
    -OutFile $MainFile `
    -UseBasicParsing

# ---- Run Main (Bypass Policy) ----
Write-Host "🚀 Khởi động ToiUuPC..." -ForegroundColor Green

powershell `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File $MainFile
