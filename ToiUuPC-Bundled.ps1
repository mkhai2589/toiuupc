# =========================================================
# ToiUuPC – BUNDLED EDITION (Single File)
# Windows 10 / 11 Optimization Toolkit
# Author: PMK
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# =========================================================
# ADMIN CHECK
# =========================================================
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "❌ Vui lòng chạy PowerShell với quyền Administrator" -ForegroundColor Red
    Pause
    exit 1
}

# =========================================================
# GLOBAL PATHS
# =========================================================
$BaseDir = "$env:SystemDrive\ToiUuPC"
$LogDir  = Join-Path $BaseDir "logs"
$BakDir  = Join-Path $BaseDir "backup"

foreach ($d in @($BaseDir, $LogDir, $BakDir)) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d | Out-Null
    }
}

# =========================================================
# UTILS
# =========================================================
$global:TEXT_COLOR    = "White"
$global:HEADER_COLOR  = "Cyan"
$global:SUCCESS_COLOR = "Green"
$global:ERROR_COLOR   = "Red"
$global:WARN_COLOR    = "Yellow"
$global:BORDER_COLOR  = "DarkGray"

function Write-Log {
    param([string]$Message, [string]$File = "main.log")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path (Join-Path $LogDir $File) -Value "[$ts] $Message"
}

function Show-Header {
    Clear-Host
    Write-Host "=================================================" -ForegroundColor $BORDER_COLOR
    Write-Host "        ToiUuPC – BUNDLED EDITION" -ForegroundColor $HEADER_COLOR
    Write-Host "        Windows 10 / 11 Optimizer" -ForegroundColor $TEXT_COLOR
    Write-Host "=================================================`n" -ForegroundColor $BORDER_COLOR
}

function Create-RestorePoint {
    try {
        Checkpoint-Computer -Description "ToiUuPC Restore" -RestorePointType MODIFY_SETTINGS
        Write-Host "✔ Đã tạo restore point" -ForegroundColor $SUCCESS_COLOR
        Write-Log "Created restore point"
    } catch {
        Write-Host "⚠ Không tạo được restore point" -ForegroundColor $WARN_COLOR
    }
}

# =========================================================
# EMBEDDED TWEAKS DATA
# =========================================================
$Tweaks = @(
    @{
        id="disable-telemetry"; category="Privacy"; preset=@("Privacy","Office")
        dangerous=$false
        action={ Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" AllowTelemetry 0 -Type DWord -Force }
    },
    @{
        id="disable-windows-tips"; category="Privacy"; preset=@("Privacy","Office")
        dangerous=$false
        action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" SubscribedContent-338389Enabled 0 -Type DWord -Force }
    },
    @{
        id="disable-hibernation"; category="Performance"; preset=@("Gaming")
        dangerous=$true
        action={ powercfg -h off }
    },
    @{
        id="gaming-power-plan"; category="Performance"; preset=@("Gaming")
        dangerous=$false
        action={ powercfg /setactive SCHEME_MIN }
    }
)

# =========================================================
# TWEAK ENGINE
# =========================================================
function Invoke-TweaksEngine {
    param(
        [string]$Preset,
        [string[]]$Ids,
        [switch]$Rollback
    )

    if ($Rollback) {
        Write-Host "⏪ Rollback hiện tại chỉ hỗ trợ thủ công (restore point)" -ForegroundColor $WARN_COLOR
        Write-Host "👉 Vào System Restore để khôi phục"
        return
    }

    Create-RestorePoint

    $targets = @()

    if ($Preset) {
        $targets = $Tweaks | Where-Object { $_.preset -contains $Preset }
    }
    elseif ($Ids) {
        $targets = $Tweaks | Where-Object { $Ids -contains $_.id }
    }

    foreach ($t in $targets) {
        if ($t.dangerous) {
            Write-Host "⚠ $($t.id) (DANGEROUS)" -ForegroundColor $WARN_COLOR
        } else {
            Write-Host "▶ $($t.id)" -ForegroundColor Cyan
        }

        try {
            & $t.action
            Write-Log "Applied tweak: $($t.id)" "tweaks.log"
        } catch {
            Write-Host "❌ Lỗi tweak $($t.id)" -ForegroundColor Red
        }
    }

    Write-Host "✅ Hoàn tất tweaks" -ForegroundColor Green
}

# =========================================================
# INSTALL APPS (WINGET)
# =========================================================
function Test-Winget {
    return (Get-Command winget -ErrorAction SilentlyContinue)
}

$Applications = @(
    @{ name="Google Chrome"; id="Google.Chrome"; preset=@("Office","Gaming") },
    @{ name="Firefox"; id="Mozilla.Firefox"; preset=@("Office") },
    @{ name="7-Zip"; id="7zip.7zip"; preset=@("Office","Gaming") },
    @{ name="VS Code"; id="Microsoft.VisualStudioCode"; preset=@("Office") },
    @{ name="Steam"; id="Valve.Steam"; preset=@("Gaming") }
)

function Invoke-InstallApps {
    if (-not (Test-Winget)) {
        Write-Host "❌ Winget chưa có" -ForegroundColor Red
        return
    }

    Write-Host "Chọn preset cài app:"
    Write-Host "1. Office"
    Write-Host "2. Gaming"
    $c = Read-Host "👉 Chọn"

    $preset = if ($c -eq "2") { "Gaming" } else { "Office" }

    $apps = $Applications | Where-Object { $_.preset -contains $preset }

    foreach ($app in $apps) {
        Write-Host "▶ Cài $($app.name)" -ForegroundColor Cyan
        winget install --id $app.id --silent --accept-package-agreements --accept-source-agreements
        Write-Log "Installed app: $($app.id)" "apps.log"
    }

    Write-Host "✅ Hoàn tất cài ứng dụng" -ForegroundColor Green
}

# =========================================================
# DNS
# =========================================================
function Invoke-DNSManager {
    Write-Host "1. Google DNS"
    Write-Host "2. Cloudflare"
    $c = Read-Host "👉 Chọn"

    $dns = if ($c -eq "2") { @("1.1.1.1","1.0.0.1") } else { @("8.8.8.8","8.8.4.4") }

    Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ServerAddresses $dns
    }

    Write-Log "DNS set to $($dns -join ',')" "dns.log"
    Write-Host "✅ Đã thiết lập DNS" -ForegroundColor Green
}

# =========================================================
# CLEAN SYSTEM
# =========================================================
function Invoke-CleanSystem {
    Write-Host "🧹 Dọn dẹp hệ thống..." -ForegroundColor Cyan

    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue

    Write-Log "System cleaned" "clean.log"
    Write-Host "✅ Hoàn tất dọn dẹp" -ForegroundColor Green
}

# =========================================================
# MAIN MENU
# =========================================================
while ($true) {
    Show-Header

    Write-Host "1. ⚙️  Tối ưu hệ thống (Tweaks)"
    Write-Host "2. 📦 Cài ứng dụng"
    Write-Host "3. 🌐 DNS"
    Write-Host "4. 🧹 Dọn dẹp"
    Write-Host "0. ❌ Thoát`n"

    $c = Read-Host "👉 Chọn"

    switch ($c) {
        "1" {
            Write-Host "1. Privacy"
            Write-Host "2. Gaming"
            Write-Host "3. Office"
            $p = Read-Host "👉 Preset"
            $preset = @("Privacy","Gaming","Office")[[int]$p-1]
            Invoke-TweaksEngine -Preset $preset
            Pause
        }
        "2" { Invoke-InstallApps; Pause }
        "3" { Invoke-DNSManager; Pause }
        "4" { Invoke-CleanSystem; Pause }
        "0" { break }
    }
}
