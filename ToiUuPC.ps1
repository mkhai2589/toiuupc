# ==========================================================
# ToiUuPC.ps1 - MAIN SCRIPT (FINAL VERSION)
# ==========================================================

# Load core utilities
$utilsPath = Join-Path $PSScriptRoot "functions\utils.ps1"
if (-not (Test-Path $utilsPath)) {
    Write-Host "[ERROR] Khong tim thay utils.ps1" -ForegroundColor Red
    exit 1
}
. $utilsPath

# Ensure admin rights
Ensure-Admin

# Load all function modules
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
        . $path
        Write-Status "Loaded: $func" -Type 'INFO'
    } else {
        Write-Status "Missing: $func" -Type 'WARNING'
    }
}

# Load configurations
$ConfigDir = Join-Path $PSScriptRoot "config"
$global:TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
$global:AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
$global:DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")

if (-not $global:TweaksConfig -or -not $global:AppsConfig -or -not $global:DnsConfig) {
    Write-Status "Tai cau hinh JSON that bai!" -Type 'ERROR'
    Pause
    exit 1
}

# Main menu definition
$MainMenuItems = @(
    @{ Key = "1"; Text = "Windows Tweaks" }
    @{ Key = "2"; Text = "DNS Management" }
    @{ Key = "3"; Text = "Clean System" }
    @{ Key = "4"; Text = "Install Applications" }
    @{ Key = "5"; Text = "Reload Configuration" }
    @{ Key = "0"; Text = "Thoat ToiUuPC" }
)

# Main program loop
while ($true) {
    Show-Menu -MenuItems $MainMenuItems -Title "PMK TOOLBOX - MAIN MENU"
    
    $choice = Read-Host
    
    switch ($choice) {
        '1' {
            # Windows Tweaks
            Show-TweaksMenu -Config $global:TweaksConfig
        }
        '2' {
            # DNS Management  
            Show-DnsMenu -Config $global:DnsConfig
        }
        '3' {
            # Clean System
            Show-CleanSystem
        }
        '4' {
            # Install Applications
            Show-AppsMenu -Config $global:AppsConfig
        }
        '5' {
            # Reload Configuration
            Show-Header -Title "RELOAD CONFIGURATION"
            Write-Status "Dang tai lai cau hinh..." -Type 'INFO'
            
            $global:TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
            $global:AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
            $global:DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")
            
            Write-Status "Tai lai cau hinh thanh cong!" -Type 'SUCCESS'
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
