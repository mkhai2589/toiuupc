# ==========================================================
# ToiUuPC.ps1 - MAIN SCRIPT (FINAL VERSION)
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
    exit 1
}
. $utilsPath

# ==========================================================
# ENSURE ADMINISTRATOR RIGHTS
# ==========================================================
Ensure-Admin

# ==========================================================
# LOAD ALL FUNCTION MODULES
# ==========================================================
$functions = @(
    "Show-PMKLogo.ps1",
    "tweaks.ps1",
    "install-apps.ps1", 
    "dns-management.ps1",
    "clean-system.ps1"
)

foreach ($func in $functions) {
    $path = Join-Path $PSScriptRoot "functions\$func"
    if (Test-Path $path) {
        try {
            . $path
            Write-Status "Loaded: $func" -Type 'INFO'
        } catch {
            Write-Status "Error loading $func : $_" -Type 'ERROR'
        }
    } else {
        Write-Status "Missing: $func" -Type 'WARNING'
    }
}

# ==========================================================
# LOAD CONFIGURATIONS
# ==========================================================
$ConfigDir = Join-Path $PSScriptRoot "config"
$global:TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
$global:AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
$global:DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")

if (-not $global:TweaksConfig) {
    Write-Status "Tai cau hinh tweaks.json that bai!" -Type 'ERROR'
}
if (-not $global:AppsConfig) {
    Write-Status "Tai cau hinh applications.json that bai!" -Type 'ERROR'
}
if (-not $global:DnsConfig) {
    Write-Status "Tai cau hinh dns.json that bai!" -Type 'ERROR'
}

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
            # Windows Tweaks
            if ($global:TweaksConfig) {
                Show-TweaksMenu -Config $global:TweaksConfig
            } else {
                Write-Status "Cau hinh tweaks chua duoc tai!" -Type 'ERROR'
                Pause
            }
        }
        '2' {
            # DNS Management  
            if ($global:DnsConfig) {
                Show-DnsMenu -Config $global:DnsConfig
            } else {
                Write-Status "Cau hinh DNS chua duoc tai!" -Type 'ERROR'
                Pause
            }
        }
        '3' {
            # Clean System
            Show-CleanSystem
        }
        '4' {
            # Install Applications
            if ($global:AppsConfig) {
                Show-AppsMenu -Config $global:AppsConfig
            } else {
                Write-Status "Cau hinh ung dung chua duoc tai!" -Type 'ERROR'
                Pause
            }
        }
        '5' {
            # Reload Configuration
            Show-Header -Title "TAI LAI CAU HINH"
            Write-Status "Dang tai lai cau hinh..." -Type 'INFO'
            
            $global:TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
            $global:AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
            $global:DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")
            
            if ($global:TweaksConfig -and $global:AppsConfig -and $global:DnsConfig) {
                Write-Status "Tai lai cau hinh thanh cong!" -Type 'SUCCESS'
            } else {
                Write-Status "Co loi khi tai lai cau hinh!" -Type 'ERROR'
            }
            Pause
        }
        '0' {
            # Exit program
            Show-Header -Title "THOAT CHUONG TRINH"
            Write-Status "Cam on ban da su dung ToiUuPC!" -Type 'INFO'
            Write-Host "Chuong trinh se dong trong 2 giay..." -ForegroundColor $global:UI_Colors.Warning
            Start-Sleep -Seconds 2
            exit 0
        }
        default {
            Write-Status "Lua chon khong hop le!" -Type 'WARNING'
            Pause
        }
    }
}
