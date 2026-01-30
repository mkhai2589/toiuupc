# ==========================================================
# ToiUuPC.ps1 - MAIN MENU (REAL-TIME UI ENGINE - FINAL)
# Author: Minh Khai
# Description: Engine menu console mượt mà, không dùng Read-Host
# ==========================================================

#region ----- INITIALIZATION -----
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
#endregion

#region ----- GLOBAL VARIABLES & PATHS -----
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = Join-Path $ScriptRoot "config"

# UI Configuration
$global:UI = @{
    Width = 70
    Border = 'DarkGray'
    Header = 'Cyan'
    Title = 'White'
    Menu = 'Gray'
    Active = 'Green'
    Warn = 'Yellow'
    Error = 'Red'
    Note = 'DarkGray'
}

# Menu Structure - ĐƠN GIẢN HÓA SỐ THỨ TỰ
$global:MenuItems = @(
    @{ Key = "1"; Text = "Windows Tweaks";        Action = "Invoke-TweaksMenu" }
    @{ Key = "2"; Text = "DNS Management";        Action = "Invoke-DnsMenu" }
    @{ Key = "3"; Text = "Clean System";          Action = "Invoke-CleanSystem" }
    @{ Key = "4"; Text = "Install Applications";  Action = "Invoke-AppMenu" }
    @{ Key = "5"; Text = "Reload Configuration";  Action = "Reload-Configuration" }
    @{ Key = "0"; Text = "Exit ToiUuPC";          Action = "Exit-Program" }
)
#endregion

#region ----- CORE FUNCTIONS: MODULE LOADING -----
function Import-Modules {
    # Load core utilities
    $utilsPath = Join-Path $ScriptRoot "functions\utils.ps1"
    if (-not (Test-Path $utilsPath)) {
        Write-Host "[ERROR] Khong tim thay utils.ps1!" -ForegroundColor Red
        exit 1
    }
    . $utilsPath
    Ensure-Admin

    # Load all function modules với tên CHUẨN
    $functions = @(
        "Show-PMKLogo.ps1",
        "tweaks.ps1",           # Phải chứa hàm 'Invoke-TweaksMenu'
        "install-apps.ps1",     # Phải chứa hàm 'Invoke-AppMenu'
        "dns-management.ps1",   # Phải chứa hàm 'Invoke-DnsMenu'
        "clean-system.ps1"      # Phải chứa hàm 'Invoke-CleanSystem'
    )
    
    foreach ($func in $functions) {
        $path = Join-Path $ScriptRoot "functions\$func"
        if (Test-Path $path) {
            . $path
            Write-Host "[LOAD] $func" -ForegroundColor $global:UI.Note
        } else {
            Write-Host "[WARN] Thieu file: $func" -ForegroundColor $global:UI.Warn
        }
    }
}

function Load-Configurations {
    # Sử dụng hàm Load-JsonFile từ utils.ps1
    $global:TweaksConfig = Load-JsonFile (Join-Path $ConfigDir "tweaks.json")
    $global:AppsConfig   = Load-JsonFile (Join-Path $ConfigDir "applications.json")
    $global:DnsConfig    = Load-JsonFile (Join-Path $ConfigDir "dns.json")
    
    if (-not $global:TweaksConfig -or -not $global:AppsConfig -or -not $global:DnsConfig) {
        Write-Host "[ERROR] Tai cau hinh JSON that bai!" -ForegroundColor Red
        Pause
        exit 1
    }
    Write-Host "[LOAD] Tai cau hinh JSON thanh cong." -ForegroundColor $global:UI.Note
}
#endregion

#region ----- CORE FUNCTIONS: REAL-TIME UI ENGINE -----
function Draw-Header {
    # Header cố định, không có cột Action
    $line = "+" + ("=" * ($global:UI.Width - 2)) + "+"
    Write-Host $line -ForegroundColor $global:UI.Border
    Write-Host "|" -NoNewline
    Write-Host " TOI UU PC - PMK TOOLBOX " -ForegroundColor $global:UI.Header -NoNewline
    Write-Host (" " * ($global:UI.Width - 26)) + "|"
    Write-Host $line -ForegroundColor $global:UI.Border
    Write-Host ""
}

function Render-MainMenu {
    param([int]$SelectedIndex = 0)
    
    Clear-Host
    Draw-Header
    
    Write-Host "  CHON CHUC NANG (Nhap so hoac dung phim mui ten):" -ForegroundColor $global:UI.Title
    Write-Host ""
    
    for ($i = 0; $i -lt $global:MenuItems.Count; $i++) {
        $item = $global:MenuItems[$i]
        $indicator = if ($i -eq $SelectedIndex) { ">>" } else { "  " }
        $color = if ($i -eq $SelectedIndex) { $global:UI.Active } else { $global:UI.Menu }
        
        Write-Host "  $indicator " -NoNewline
        Write-Host "[$($item.Key)] " -NoNewline -ForegroundColor $color
        Write-Host $item.Text -ForegroundColor $color
    }
    
    Write-Host ""
    Write-Host "  * Su dung:" -ForegroundColor $global:UI.Note
    Write-Host "    - Phim [↑][↓] hoac [1-5,0] de chon" -ForegroundColor $global:UI.Note
    Write-Host "    - Phim [Enter] de xac nhan" -ForegroundColor $global:UI.Note
    Write-Host "    - Phim [ESC] de thoat" -ForegroundColor $global:UI.Note
}

function Invoke-MainMenu {
    $selectedIndex = 0
    $exitMain = $false
    
    while (-not $exitMain) {
        Render-MainMenu -SelectedIndex $selectedIndex
        
        # Xử lý phím với ReadKey (KHÔNG DÙNG Read-Host)
        $key = $null
        while (-not [Console]::KeyAvailable) {
            Start-Sleep -Milliseconds 50
        }
        $key = [Console]::ReadKey($true)
        
        switch ($key.Key) {
            'UpArrow'    { if ($selectedIndex -gt 0) { $selectedIndex-- } }
            'DownArrow'  { if ($selectedIndex -lt ($global:MenuItems.Count - 1)) { $selectedIndex++ } }
            'Enter'      { 
                $action = $global:MenuItems[$selectedIndex].Action
                Invoke-Expression $action
                # Sau khi menu con thoát, quay lại vòng lặp chính
                break
            }
            'Escape'     { $exitMain = $true; break }
            'D0'         { if ($key.KeyChar -eq '0') { $exitMain = $true; break } } # Phím số 0
            { $_ -ge 'D1' -and $_ -le 'D5' } { 
                # Phím số 1-5
                $num = [int][string]$key.KeyChar
                $item = $global:MenuItems | Where-Object { [int]$_.Key -eq $num }
                if ($item) {
                    Invoke-Expression $item.Action
                }
                break
            }
            default {
                # Bỏ qua các phím khác
            }
        }
    }
    
    # Thoát chương trình sạch sẽ
    Clear-Host
    Write-Host "Cam on ban da su dung ToiUuPC!" -ForegroundColor $global:UI.Active
    Write-Host "Chuong trinh se dong trong 2 giay..." -ForegroundColor $global:UI.Note
    Start-Sleep -Seconds 2
    exit 0
}
#endregion

#region ----- ACTION HANDLERS (Gọi menu con) -----
function Invoke-TweaksMenu {
    # Gọi menu Tweaks real-time (sẽ được implement trong tweaks.ps1)
    if (Get-Command "Show-TweaksMenu" -ErrorAction SilentlyContinue) {
        Show-TweaksMenu -Config $global:TweaksConfig
    } else {
        Write-Host "[ERROR] Ham 'Show-TweaksMenu' chua duoc dinh nghia!" -ForegroundColor Red
        Pause
    }
}

function Invoke-DnsMenu {
    # Gọi menu DNS real-time
    if (Get-Command "Show-DnsMenu" -ErrorAction SilentlyContinue) {
        Show-DnsMenu -Config $global:DnsConfig
    } else {
        Write-Host "[ERROR] Ham 'Show-DnsMenu' chua duoc dinh nghia!" -ForegroundColor Red
        Pause
    }
}

function Invoke-CleanSystem {
    # Gọi chức năng Clean (có thể giữ Read-Host vì là one-action)
    if (Get-Command "Invoke-CleanSystem" -ErrorAction SilentlyContinue) {
        # Tạm thời gọi hàm cũ, sẽ nâng cấp sau
        & "Invoke-CleanSystem"
    } else {
        Write-Host "[ERROR] Ham 'Invoke-CleanSystem' chua duoc dinh nghia!" -ForegroundColor Red
        Pause
    }
}

function Invoke-AppMenu {
    # Gọi menu Applications real-time 2 cột
    if (Get-Command "Show-AppsMenu" -ErrorAction SilentlyContinue) {
        Show-AppsMenu -Config $global:AppsConfig
    } else {
        Write-Host "[ERROR] Ham 'Show-AppsMenu' chua duoc dinh nghia!" -ForegroundColor Red
        Pause
    }
}

function Reload-Configuration {
    Clear-Host
    Write-Host "[INFO] Dang tai lai cau hinh tu JSON..." -ForegroundColor $global:UI.Header
    Load-Configurations
    Write-Host "[SUCCESS] Tai lai cau hinh thanh cong!" -ForegroundColor $global:UI.Active
    Pause
}

function Exit-Program {
    # Được gọi trực tiếp từ menu item 0
    exit 0
}
#endregion

#region ----- MAIN EXECUTION -----
try {
    # Import modules và config
    Write-Host "[BOOT] Khoi dong ToiUuPC..." -ForegroundColor $global:UI.Header
    Import-Modules
    Load-Configurations
    
    # Khởi chạy Real-time UI Engine
    Invoke-MainMenu
}
catch {
    Write-Host "[FATAL ERROR] Co loi nghiem trong xay ra:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Pause
    exit 1
}
#endregion
