# =========================================================
# ToiUuPC – Compile Script
# Build PowerShell → EXE
# Author: PMK
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "▶ ToiUuPC Compile Tool" -ForegroundColor Cyan

# ---------------- PATH ----------------
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Source = Join-Path $Root "ToiUuPC-Bundled.ps1"
$Output = Join-Path $Root "ToiUuPC.exe"

# ---------------- CHECK SOURCE ----------------
if (-not (Test-Path $Source)) {
    Write-Host "❌ Không tìm thấy ToiUuPC-Bundled.ps1" -ForegroundColor Red
    exit 1
}

# ---------------- CHECK PS2EXE ----------------
if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "⚠ Chưa có ps2exe, đang cài..." -ForegroundColor Yellow
    Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber
}

Import-Module ps2exe

# ---------------- COMPILE ----------------
Write-Host "⚙️ Đang build EXE..." -ForegroundColor Cyan

Invoke-ps2exe `
    -InputFile $Source `
    -OutputFile $Output `
    -NoConsole:$false `
    -RequireAdmin `
    -Title "ToiUuPC – Windows Optimizer" `
    -Description "ToiUuPC - Windows 10/11 Optimization Toolkit" `
    -Company "PMK" `
    -Product "ToiUuPC" `
    -Copyright "© PMK"

# ---------------- DONE ----------------
if (Test-Path $Output) {
    Write-Host "✅ Build thành công: $Output" -ForegroundColor Green
} else {
    Write-Host "❌ Build thất bại" -ForegroundColor Red
}
