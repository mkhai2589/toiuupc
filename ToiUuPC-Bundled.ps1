# ===============================
# 🛠️ ToiUuPC – Windows 10 / 11 Optimization Toolkit
# Author : Phạm Minh Khải (PMK)
# License: MIT
# ===============================

param(
    [switch]$Update
)

# ===============================
# GLOBAL CONFIG (BOOTSTRAP SAFE)
# ===============================
$Global:ToiUuPCRoot = "$env:ProgramData\ToiUuPC"
$Global:LogFile     = "$ToiUuPCRoot\toiuupc.log"
$Global:RepoRaw     = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC-Bundled.ps1"

# ===============================
# INIT
# ===============================
if (-not (Test-Path $ToiUuPCRoot)) {
    New-Item -ItemType Directory -Path $ToiUuPCRoot | Out-Null
}

function Write-Log {
    param([string]$Message)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time | $Message" | Tee-Object -FilePath $LogFile -Append
}

# ===============================
# ADMIN CHECK
# ===============================
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ Vui lòng chạy PowerShell với quyền Administrator" -ForegroundColor Red
    exit
}

# ===============================
# SELF UPDATE
# ===============================
if ($Update) {
    Write-Host "🔄 Đang cập nhật ToiUuPC..." -ForegroundColor Cyan
    try {
        $content = Invoke-RestMethod $RepoRaw
        $local   = "$ToiUuPCRoot\ToiUuPC-Bundled.ps1"
        $content | Set-Content -Encoding UTF8 $local
        Write-Host "✅ Cập nhật thành công. Chạy lại bằng:" -ForegroundColor Green
        Write-Host "powershell -ExecutionPolicy Bypass -File `"$local`"" -ForegroundColor Yellow
    } catch {
        Write-Host "❌ Lỗi cập nhật: $_" -ForegroundColor Red
    }
    exit
}

# ===============================
# RESTORE POINT
# ===============================
function Create-RestorePoint {
    Write-Log "Create restore point"
    Checkpoint-Computer -Description "ToiUuPC Restore Point" -RestorePointType MODIFY_SETTINGS
}

# ===============================
# SYSTEM TWEAKS
# ===============================
function Apply-PrivacyTweaks {
    Write-Log "Apply Privacy Tweaks"

    $keys = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    )

    foreach ($k in $keys) {
        if (-not (Test-Path $k)) { New-Item $k -Force | Out-Null }
    }

    Set-ItemProperty $keys[0] AllowTelemetry -Type DWord -Value 0
    Set-ItemProperty $keys[1] Enabled -Type DWord -Value 0
}

function Apply-PerformanceTweaks {
    Write-Log "Apply Performance Tweaks"
    powercfg -setactive SCHEME_MIN
    Set-ItemProperty "HKCU:\Control Panel\Desktop" MenuShowDelay -Value 0
}

# ===============================
# DNS
# ===============================
function Set-DNSGoogle {
    Write-Log "Set Google DNS"
    Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceIndex $_.IfIndex `
            -ServerAddresses 8.8.8.8,8.8.4.4
    }
}

function Set-DNSCloudflare {
    Write-Log "Set Cloudflare DNS"
    Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceIndex $_.IfIndex `
            -ServerAddresses 1.1.1.1,1.0.0.1
    }
}

# ===============================
# CLEAN SYSTEM
# ===============================
function Clean-System {
    Write-Log "Clean system"
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

# ===============================
# WINGET
# ===============================
function Install-Apps {
    $apps = @(
        "Google.Chrome",
        "Mozilla.Firefox",
        "Microsoft.VisualStudioCode",
        "7zip.7zip",
        "Valve.Steam"
    )

    foreach ($app in $apps) {
        winget list --id $app | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Install $app"
            winget install --id $app --silent --accept-source-agreements --accept-package-agreements
        }
    }
}

# ===============================
# MENU
# ===============================
function Show-Menu {
    Clear-Host
    Write-Host "==============================="
    Write-Host "🛠️  ToiUuPC – Windows Optimizer"
    Write-Host "Author: Phạm Minh Khải (PMK)"
    Write-Host "==============================="
    Write-Host "1. Privacy Preset"
    Write-Host "2. Performance Preset"
    Write-Host "3. Install Popular Apps"
    Write-Host "4. Set DNS (Google)"
    Write-Host "5. Set DNS (Cloudflare)"
    Write-Host "6. Clean System"
    Write-Host "0. Exit"
}

# ===============================
# MAIN
# ===============================
Create-RestorePoint

do {
    Show-Menu
    $choice = Read-Host "Chọn chức năng"

    switch ($choice) {
        "1" { Apply-PrivacyTweaks }
        "2" { Apply-PerformanceTweaks }
        "3" { Install-Apps }
        "4" { Set-DNSGoogle }
        "5" { Set-DNSCloudflare }
        "6" { Clean-System }
        "0" { break }
    }

    Pause
} while ($true)

Write-Host "✅ Hoàn tất. Log: $LogFile" -ForegroundColor Green
