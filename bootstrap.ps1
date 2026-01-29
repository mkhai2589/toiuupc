# =========================================
# ToiUuPC Bootstrap (SAFE - WinUtil style)
# =========================================



# Force UTF-8
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$ErrorActionPreference = "Stop"

$RepoRaw = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"
$WorkDir = Join-Path $env:TEMP "ToiUuPC"
$MainScript = Join-Path $WorkDir "ToiUuPC.ps1"

# ---------- Admin check (SAFE, 1 line) ----------
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "❌ Vui lòng chạy PowerShell với quyền Administrator" -ForegroundColor Red
    return
}

# ---------- Prepare working directory ----------
if (-not (Test-Path $WorkDir)) {
    New-Item -ItemType Directory -Path $WorkDir | Out-Null
}

# ---------- Download main controller ----------
Write-Host "⬇ Đang tải ToiUuPC..." -ForegroundColor Cyan

Invoke-WebRequest `
    -Uri "$RepoRaw/ToiUuPC.ps1" `
    -OutFile $MainScript `
    -UseBasicParsing

Write-Host "✅ Tải xong. Đang khởi động..." -ForegroundColor Green

# ---------- Run controller ----------
& powershell -NoProfile -ExecutionPolicy Bypass -File $MainScript
