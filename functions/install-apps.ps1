# install-apps.ps1 - Menu 2 cột và sửa logic
Set-StrictMode -Off
$ErrorActionPreference = 'SilentlyContinue'

$Script:AppConfigPath = Join-Path $PSScriptRoot "..\config\applications.json"

function Load-ApplicationConfig {
    if (-not (Test-Path $Script:AppConfigPath)) {
        Write-Host "applications.json not found!" -ForegroundColor Red
        return $null
    }
    try {
        return Get-Content $Script:AppConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Host "Invalid applications.json format!" -ForegroundColor Red
        return $null
    }
}

function Ensure-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "winget not found. Please install App Installer from Microsoft Store." -ForegroundColor Red
        return $false
    }
    return $true
}

function Is-AppInstalled {
    param([string]$PackageId)
    try {
        $out = winget list --id $PackageId --exact 2>$null | Select-String $PackageId
        return ($out -ne $null)
    } catch {
        return $false
    }
}

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
    # Chạy winget trực tiếp, không dùng Start-Process để tránh treo
    try {
        winget $args
    } catch {
        Write-Host " Installation failed: $_" -ForegroundColor Red
    }
}

function Show-AppMenu {
    param([object]$Config)
    Clear-Host
    Write-Host "====== INSTALL APPLICATIONS ======" -ForegroundColor Cyan
    Write-Host ""
    $menuMap = @{}
    $i = 1
    $appsByCategory = @{}
    foreach ($app in $Config.applications) {
        if (-not $appsByCategory.ContainsKey($app.category)) {
            $appsByCategory[$app.category] = @()
        }
        $appsByCategory[$app.category] += $app
    }
    # Tính toán để hiển thị 2 cột
    $totalCategories = $appsByCategory.Keys.Count
    $half = [math]::Ceiling($totalCategories / 2)
    $leftCategories = $appsByCategory.Keys | Select-Object -First $half
    $rightCategories = $appsByCategory.Keys | Select-Object -Skip $half
    # In header 2 cột
    Write-Host ("{0,-40}{1}" -f "Left Column", "Right Column") -ForegroundColor Gray
    Write-Host ("{0,-40}{1}" -f "-----------", "------------")
    # In từng dòng cho mỗi category
    for ($row=0; $row -lt $half; $row++) {
        $leftCat = if ($row -lt $leftCategories.Count) { $leftCategories[$row] } else { $null }
        $rightCat = if ($row -lt $rightCategories.Count) { $rightCategories[$row] } else { $null }
        $leftText = if ($leftCat) { "[$leftCat]" } else { "" }
        $rightText = if ($rightCat) { "[$rightCat]" } else { "" }
        Write-Host ("{0,-40}{1}" -f $leftText, $rightText) -ForegroundColor Green
        # Lấy danh sách ứng dụng cho category bên trái và bên phải
        $leftApps = if ($leftCat) { $appsByCategory[$leftCat] } else { @() }
        $rightApps = if ($rightCat) { $appsByCategory[$rightCat] } else { @() }
        $maxRows = [math]::Max($leftApps.Count, $rightApps.Count)
        for ($appRow=0; $appRow -lt $maxRows; $appRow++) {
            $leftApp = if ($appRow -lt $leftApps.Count) { $leftApps[$appRow] } else { $null }
            $rightApp = if ($appRow -lt $rightApps.Count) { $rightApps[$appRow] } else { $null }
            $leftKey = if ($leftApp) { "{0:00}" -f $i } else { "" }
            $leftName = if ($leftApp) { $leftApp.name } else { "" }
            $leftStr = if ($leftApp) { " $leftKey. $leftName" } else { "" }
            $menuMap[$leftKey] = $leftApp
            if ($leftApp) { $i++ }
            $rightKey = if ($rightApp) { "{0:00}" -f $i } else { "" }
            $rightName = if ($rightApp) { $rightApp.name } else { "" }
            $rightStr = if ($rightApp) { " $rightKey. $rightName" } else { "" }
            $menuMap[$rightKey] = $rightApp
            if ($rightApp) { $i++ }
            Write-Host ("{0,-40}{1}" -f $leftStr, $rightStr)
        }
        Write-Host ""
    }
    Write-Host "00. Back"
    Write-Host ""
    return $menuMap
}

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
