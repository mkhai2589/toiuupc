# ============================================================
# PMK TOOLBOX - INSTALL APPLICATIONS
# Author : Minh Khai
# Target : Windows 10 / Windows 11
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ============================================================
# CONFIG PATH
# ============================================================
$Script:AppConfigPath = Join-Path $PSScriptRoot "..\config\applications.json"

# ============================================================
# LOAD JSON
# ============================================================
function Load-ApplicationConfig {

    if (-not (Test-Path $Script:AppConfigPath)) {
        Write-Host "applications.json not found!" -ForegroundColor Red
        Read-Host "Press Enter"
        return $null
    }

    try {
        return Get-Content $Script:AppConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Host "Invalid applications.json format!" -ForegroundColor Red
        Read-Host "Press Enter"
        return $null
    }
}

# ============================================================
# CHECK WINGET
# ============================================================
function Ensure-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "winget not found. Please install App Installer from Microsoft Store." -ForegroundColor Red
        Read-Host "Press Enter"
        return $false
    }
    return $true
}

# ============================================================
# CHECK INSTALLED
# ============================================================
function Is-AppInstalled {
    param([string]$PackageId)

    try {
        $out = winget list --id $PackageId 2>$null
        return ($out -match $PackageId)
    } catch {
        return $false
    }
}

# ============================================================
# INSTALL APP
# ============================================================
function Install-Application {
    param([object]$App)

    if (-not $App.packageId) {
        Write-Host "Invalid application config" -ForegroundColor Red
        return
    }

    if (Is-AppInstalled $App.packageId) {
        Write-Host "[SKIP] $($App.name) already installed" -ForegroundColor Yellow
        return
    }

    Write-Host "[INSTALL] $($App.name)" -ForegroundColor Cyan

    $args = @(
        "install",
        "--id", $App.packageId,
        "--accept-package-agreements",
        "--accept-source-agreements"
    )

    if ($App.source) {
        $args += @("--source", $App.source)
    }

    if ($App.silent -eq $true) {
        $args += "--silent"
    }

    Start-Process `
        -FilePath "winget" `
        -ArgumentList $args `
        -Wait `
        -NoNewWindow
}

# ============================================================
# SHOW MENU
# ============================================================
function Show-AppMenu {
    param([object]$Config)

    Clear-Host
    Write-Host "====== INSTALL APPLICATIONS ======" -ForegroundColor Cyan
    Write-Host ""

    $menuMap = @{}
    $i = 1

    foreach ($cat in $Config.categories) {

        Write-Host "[$cat]" -ForegroundColor Green

        $apps = $Config.applications | Where-Object { $_.category -eq $cat }

        foreach ($app in $apps) {
            $key = "{0:00}" -f $i
            Write-Host " $key. $($app.name)"
            $menuMap[$key] = $app
            $i++
        }

        Write-Host ""
    }

    Write-Host "00. Back"
    Write-Host ""

    return $menuMap
}

# ============================================================
# MAIN ENTRY (CALLED BY ToiUuPC.ps1)
# ============================================================
function Invoke-AppMenu {
    param([object]$Config)

    if (-not (Ensure-Winget)) { return }

    if (-not $Config) {
        $Config = Load-ApplicationConfig
    }

    if (-not $Config) { return }

    while ($true) {

        $menuMap = Show-AppMenu -Config $Config
        $choice = Read-Host "Select"

        if ($choice -eq "00") { return }

        if ($menuMap.ContainsKey($choice)) {
            Install-Application $menuMap[$choice]
            Read-Host "`nPress Enter"
        } else {
            Write-Host "Invalid selection!" -ForegroundColor Red
            Start-Sleep 1
        }
    }
}
