# ============================================================
# install-apps.ps1 - INSTALL APPLICATIONS (2-COLUMN)
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# APPLICATION FUNCTIONS
# ============================================================
function Load-ApplicationConfig {
    $path = Join-Path $PSScriptRoot "..\config\applications.json"
    return Load-JsonFile -Path $path
}

function Ensure-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Status "Khong tim thay winget!" -Type 'ERROR'
        Write-Host "  Vui long cai dat 'App Installer' tu Microsoft Store." -ForegroundColor $global:UI_Colors.Warning
        return $false
    }
    return $true
}

function Is-AppInstalled {
    param([string]$PackageId)
    
    try {
        $result = winget list --id $PackageId --exact 2>$null
        return ($result -match $PackageId)
    } catch {
        return $false
    }
}

function Install-Application {
    param([object]$App)
    
    if (-not $App.packageId) {
        Write-Status "Cau hinh ung dung khong hop le!" -Type 'ERROR'
        return
    }
    
    Write-Status "Kiem tra: $($App.name)" -Type 'INFO'
    
    # Check if already installed
    if (Is-AppInstalled $App.packageId) {
        Write-Status "Da duoc cai dat (bo qua)" -Type 'WARNING'
        return
    }
    
    Write-Status "Dang cai dat: $($App.name)" -Type 'INFO'
    
    $arguments = @(
        "install",
        "--id", $App.packageId,
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--disable-interactivity"
    )
    
    if ($App.source) {
        $arguments += "--source", $App.source
    }
    
    if ($App.silent -eq $true) {
        $arguments += "--silent"
    }
    
    try {
        # Run winget directly
        winget @arguments 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Cai dat thanh cong!" -Type 'SUCCESS'
        } else {
            Write-Status "That bai (Ma loi: $LASTEXITCODE)" -Type 'ERROR'
        }
    } catch {
        Write-Status "Loi: $_" -Type 'ERROR'
    }
}

# ============================================================
# APPLICATIONS MENU (2-COLUMN LAYOUT)
# ============================================================
function Show-AppsMenu {
    param($Config)
    
    if (-not $Config.applications) {
        Write-Status "Cau hinh applications.json khong hop le!" -Type 'ERROR'
        Pause
        return
    }
    
    if (-not (Ensure-Winget)) {
        Pause
        return
    }
    
    while ($true) {
        # Group apps by category
        $categories = @{}
        foreach ($app in $Config.applications) {
            if (-not $categories.ContainsKey($app.category)) {
                $categories[$app.category] = @()
            }
            $categories[$app.category] += $app
        }
        
        # Build menu with category headers
        $menuItems = @()
        $index = 1
        $appMap = @{}
        
        foreach ($category in ($categories.Keys | Sort-Object)) {
            # Add category header
            $menuItems += @{ Key = "==="; Text = "=== $category ===" }
            
            # Add apps in this category
            foreach ($app in ($categories[$category] | Sort-Object Name)) {
                $menuItems += @{ Key = $index.ToString("00"); Text = $app.name }
                $appMap[$index.ToString("00")] = $app
                $index++
            }
            
            # Add spacer
            $menuItems += @{ Key = ""; Text = "" }
        }
        
        $menuItems += @{ Key = "00"; Text = "Quay lai Menu Chinh" }
        
        Show-Menu -MenuItems $menuItems -Title "CAI DAT UNG DUNG" -TwoColumn -Prompt "Nhap so ung dung de cai dat (00 de quay lai): "
        
        $choice = Read-Host
        
        if ($choice -eq "00") {
            return
        }
        
        if ($appMap.ContainsKey($choice)) {
            $selectedApp = $appMap[$choice]
            
            Show-Header -Title "CAI DAT UNG DUNG"
            Write-Host ""
            Write-Host " Thong tin ung dung:" -ForegroundColor $global:UI_Colors.Title
            Write-Host "   Ten: $($selectedApp.name)" -ForegroundColor $global:UI_Colors.Value
            Write-Host "   ID: $($selectedApp.packageId)" -ForegroundColor $global:UI_Colors.Label
            Write-Host "   Loai: $($selectedApp.category)" -ForegroundColor $global:UI_Colors.Label
            Write-Host ""
            
            Install-Application -App $selectedApp
            Write-Host ""
            Pause
        } else {
            Write-Status "Lua chon khong hop le!" -Type 'WARNING'
            Pause
        }
    }
}
