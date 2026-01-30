# ============================================================
# PMK TOOLBOX - INSTALL APPLICATIONS
# Author : Minh Khai
# Compatible: Windows 10 / Windows 11
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ============================================================
# PATH
# ============================================================
$Script:AppConfigPath = Join-Path $PSScriptRoot "..\config\applications.json"

# ============================================================
# LOAD APPLICATION JSON
# ============================================================
function Load-ApplicationConfig {

    if (-not (Test-Path $Script:AppConfigPath)) {
        Write-Host "ERROR: applications.json not found!" -ForegroundColor Red
        Read-Host "Press Enter"
        return $null
    }

    try {
        return Get-Content $Script:AppConfigPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Host "ERROR: Invalid applications.json format!" -ForegroundColor Red
        Read-Host "Press Enter"
        return $null
    }
}

# ============================================================
# CHECK APP INSTALLED (WINGET)
# ============================================================
function Is-AppInstalled {
    param([string]$PackageId)

    try {
        $result = winget list --id $PackageId 2>$null
        return ($result -match $PackageId)
    }
    catch {
        return $false
    }
}

# ============================================================
# INSTALL SINGLE APPLICATION
# ============================================================
function Install-Application {
    param([object]$App)

    if (-not $App.packageId) {
        Write-Host "Invalid app config!" -ForegroundColor Red
        return
    }

    if (Is-AppInstalled -PackageId $App.packageId) {
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

    Start-Process -FilePath "winget" `
        -ArgumentList $args `
        -Wait `
        -NoNewWindow
}

# ============================================================
# SHOW APPLICATION MENU (GROUP BY CATEGORY)
# ============================================================
function Show-AppMenu {
    param([object]$Config)

    Clear-Host

    Write-Host "+======================================================+" -ForegroundColor DarkGray
    Write-Host "| INSTALL APPLICATIONS                                  |" -ForegroundColor White
    Write-Host "+======================================================+" -ForegroundColor DarkGray
    Write-Host ""

    $index = 1
    $menuMap = @{}

    foreach ($category in $Config.categories) {

        Write-Host "[$category]" -ForegroundColor Green

        $apps = $Config.applications | Where-Object {
            $_.category -eq $category
        }

        foreach ($app in $apps) {
            $key = "{0:00}" -f $index
            Write-Host (" {0}. {1}" -f $key, $app.name)
            $menuMap[$key] = $app
            $index++
        }

        Write-Host ""
    }

    Write-Host "[00] Back"
    Write-Host ""

    return $menuMap
}

# ============================================================
# MAIN APPLICATION MENU (CALLED FROM ToiUuPC.ps1)
# ============================================================
function Invoke-AppMenu {
    param(
        [object]$Config
    )

    if (-not $Config) {
        $Config = Load-ApplicationConfig
    }

    if (-not $Config) { return }

    while ($true) {

        $menuMap = Show-AppMenu -Config $Config
        $choice = Read-Host "Select app number"

        if ($choice -eq "00") {
            return
        }

        if ($menuMap.ContainsKey($choice)) {

            Install-Application -App $menuMap[$choice]

            Write-Host ""
            Read-Host "Press Enter to continue"
        }
        else {
            Write-Host "Invalid selection!" -ForegroundColor Red
            Start-Sleep 1
        }
    }
}
