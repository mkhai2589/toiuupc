# ==========================================================
# ToiUuPC.ps1 - MAIN SCRIPT (FIXED VERSION)
# ==========================================================

# SUPPRESS ERRORS FOR CLEAN START
Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# ==========================================================
# SETUP ENVIRONMENT
# ==========================================================
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
} catch {
    # Ignore encoding errors
}

# ==========================================================
# LOAD CORE UTILITIES
# ==========================================================
$utilsPath = Join-Path $PSScriptRoot "functions\utils.ps1"
if (-not (Test-Path $utilsPath)) {
    Write-Host "[ERROR] Khong tim thay utils.ps1" -ForegroundColor Red
    Write-Host "Vui long chay bootstrap.ps1 de tai lai du an." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Nhan Enter de thoat"
    exit 1
}

try {
    . $utilsPath
} catch {
    Write-Host "[ERROR] Khong the load utils.ps1: $_" -ForegroundColor Red
    exit 1
}

# ==========================================================
# ENSURE ADMINISTRATOR RIGHTS
# ==========================================================
Ensure-Admin

# ==========================================================
# LOAD ALL FUNCTION MODULES (SIMPLE AND EFFECTIVE)
# ==========================================================
Write-Host ""
Write-Status "Loading modules..." -Type 'INFO'

$modules = @(
    @{ Name = "Show-PMKLogo.ps1"; Required = $false }
    @{ Name = "tweaks.ps1"; Required = $true }
    @{ Name = "install-apps.ps1"; Required = $true }
    @{ Name = "dns-management.ps1"; Required = $true }
    @{ Name = "clean-system.ps1"; Required = $true }
)

foreach ($module in $modules) {
    $path = Join-Path $PSScriptRoot "functions\$($module.Name)"
    if (Test-Path $path) {
        try {
            . $path
            Write-Host "  ✓ $($module.Name)" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ $($module.Name) - Error: $_" -ForegroundColor Red
            if ($module.Required) {
                Write-Host "[ERROR] Required module failed to load!" -ForegroundColor Red
                Pause
                exit 1
            }
        }
    } else {
        Write-Host "  ✗ $($module.Name) - Not found" -ForegroundColor Yellow
        if ($module.Required) {
            Write-Host "[ERROR] Required module not found!" -ForegroundColor Red
            Pause
            exit 1
        }
    }
}

# ==========================================================
# LOAD CONFIGURATIONS
# ==========================================================
$ConfigDir = Join-Path $PSScriptRoot "config"

function Load-ConfigFile {
    param([string]$FileName)
    
    $path = Join-Path $ConfigDir $FileName
    if (-not (Test-Path $path)) {
        Write-Status "Khong tim thay file: $FileName" -Type 'ERROR'
        return $null
    }
    
    try {
        $content = Get-Content $path -Raw -Encoding UTF8
        return $content | ConvertFrom-Json
    } catch {
        Write-Status "Dinh dang JSON khong hop le: $FileName" -Type 'ERROR'
        return $null
    }
}

$global:TweaksConfig = Load-ConfigFile "tweaks.json"
$global:AppsConfig   = Load-ConfigFile "applications.json"
$global:DnsConfig    = Load-ConfigFile "dns.json"

# ==========================================================
# MAIN MENU DEFINITION
# ==========================================================
$MainMenuItems = @(
    @{ Key = "1"; Text = "Windows Tweaks (Toi uu he thong)" }
    @{ Key = "2"; Text = "DNS Management (Quan ly DNS)" }
    @{ Key = "3"; Text = "Clean System (Don dep he thong)" }
    @{ Key = "4"; Text = "Install Applications (Cai dat ung dung)" }
    @{ Key = "5"; Text = "Reload Configuration (Tai lai cau hinh)" }
    @{ Key = "0"; Text = "Thoat ToiUuPC" }
)

# ==========================================================
# MAIN PROGRAM LOOP
# ==========================================================
while ($true) {
    Show-Menu -MenuItems $MainMenuItems -Title "PMK TOOLBOX - MAIN MENU"
    
    $choice = Read-Host
    
    switch ($choice) {
        '1' {
            if ($global:TweaksConfig) {
                Show-TweaksMenu -Config $global:TweaksConfig
            } else {
                Write-Status "Cau hinh tweaks chua duoc tai!" -Type 'ERROR'
                Pause
            }
        }
        '2' {
            if ($global:DnsConfig) {
                Show-DnsMenu -Config $global:DnsConfig
            } else {
                Write-Status "Cau hinh DNS chua duoc tai!" -Type 'ERROR'
                Pause
            }
        }
        '3' {
            Show-CleanSystem
        }
        '4' {
            if ($global:AppsConfig) {
                Show-AppsMenu -Config $global:AppsConfig
            } else {
                Write-Status "Cau hinh ung dung chua duoc tai!" -Type 'ERROR'
                Pause
            }
        }
        '5' {
            Show-Header -Title "TAI LAI CAU HINH"
            Write-Status "Dang tai lai cau hinh..." -Type 'INFO'
            
            $global:TweaksConfig = Load-ConfigFile "tweaks.json"
            $global:AppsConfig   = Load-ConfigFile "applications.json"
            $global:DnsConfig    = Load-ConfigFile "dns.json"
            
            if ($global:TweaksConfig -and $global:AppsConfig -and $global:DnsConfig) {
                Write-Status "Tai lai cau hinh thanh cong!" -Type 'SUCCESS'
            } else {
                Write-Status "Co loi khi tai lai cau hinh!" -Type 'ERROR'
            }
            Pause
        }
        '0' {
            Show-Header -Title "THOAT CHUONG TRINH"
            Write-Status "Cam on ban da su dung ToiUuPC!" -Type 'INFO'
            Write-Host "Chuong trinh se dong trong 2 giay..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            exit 0
        }
        default {
            Write-Status "Lua chon khong hop le!" -Type 'WARNING'
            Pause
        }
    }
}
