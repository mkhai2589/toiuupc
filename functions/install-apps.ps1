# ============================================================
# install-apps.ps1 - MENU 2 CỘT & LOGIC CHUẨN
# ============================================================
Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

$Script:AppConfigPath = Join-Path $PSScriptRoot "..\config\applications.json"

function Load-ApplicationConfig {
    if (-not (Test-Path $Script:AppConfigPath)) {
        Write-Host "LOI: Khong tim thay file applications.json!" -ForegroundColor Red
        return $null
    }
    try {
        return Get-Content $Script:AppConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Host "LOI: Dinh dang applications.json khong hop le!" -ForegroundColor Red
        return $null
    }
}

function Ensure-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "LOI: Khong tim thay winget!" -ForegroundColor Red
        Write-Host "Vui long cai dat 'App Installer' tu Microsoft Store." -ForegroundColor Yellow
        return $false
    }
    return $true
}

function Is-AppInstalled {
    param([string]$PackageId)
    try {
        # Sử dụng --exact để kiểm tra chính xác
        $result = winget list --id $PackageId --exact 2>$null
        return ($result -match $PackageId)
    } catch {
        return $false
    }
}

function Install-Application {
    param([object]$App)
    if (-not $App.packageId) {
        Write-Host "LOI: Cau hinh ung dung khong hop le!" -ForegroundColor Red
        return
    }
    if (Is-AppInstalled $App.packageId) {
        Write-Host "[SKIP] $($App.name) da duoc cai dat." -ForegroundColor Yellow
        return
    }
    Write-Host "[CAI DAT] $($App.name)..." -ForegroundColor Cyan
    $arguments = @(
        "install",
        "--id", $App.packageId,
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--disable-interactivity"
    )
    if ($App.source) {
        $arguments += @("--source", $App.source)
    }
    if ($App.silent -eq $true) {
        $arguments += "--silent"
    }
    try {
        # Chạy winget trực tiếp, bắt lỗi rõ ràng
        winget @arguments 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   => Thanh cong!" -ForegroundColor Green
        } else {
            Write-Host "   => That bai (Code: $LASTEXITCODE)." -ForegroundColor Red
        }
    } catch {
        Write-Host "   => Loi trong qua trinh cai dat: $_" -ForegroundColor Red
    }
}

# ============================================================
# HÀM HIỂN THỊ MENU 2 CỘT (CẢI TIẾN)
# ============================================================
function Show-AppMenu {
    param([object]$Config)
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       CAI DAT UNG DUNG (2 COT)        " -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    # Nhóm ứng dụng theo category
    $categories = @{}
    foreach ($app in $Config.applications) {
        if (-not $categories.ContainsKey($app.category)) {
            $categories[$app.category] = @()
        }
        $categories[$app.category] += $app
    }
    # Chia danh sách category thành 2 cột
    $categoryNames = $categories.Keys | Sort-Object
    $midIndex = [Math]::Ceiling($categoryNames.Count / 2)
    $leftCol = $categoryNames[0..($midIndex-1)]
    $rightCol = $categoryNames[$midIndex..($categoryNames.Count-1)]
    $maxRows = [Math]::Max($leftCol.Count, $rightCol.Count)
    $menuMap = @{}
    $itemNumber = 1
    # Hiển thị tiêu đề cột
    Write-Host ("{0,-35} {1,-35}" -f "[COT TRAI]", "[COT PHAI]") -ForegroundColor Gray
    Write-Host ("{0,-35} {1,-35}" -f "---------", "----------")
    # Duyệt và in từng dòng
    for ($i = 0; $i -lt $maxRows; $i++) {
        $leftCat = if ($i -lt $leftCol.Count) { $leftCol[$i] } else { $null }
        $rightCat = if ($i -lt $rightCol.Count) { $rightCol[$i] } else { $null }
        # In tên category
        $leftHeader = if ($leftCat) { "== $leftCat ==" } else { "" }
        $rightHeader = if ($rightCat) { "== $rightCat ==" } else { "" }
        Write-Host ("{0,-35} {1,-35}" -f $leftHeader, $rightHeader) -ForegroundColor Green
        # Lấy danh sách app cho mỗi category ở dòng này
        $leftApps = if ($leftCat) { $categories[$leftCat] } else { @() }
        $rightApps = if ($rightCat) { $categories[$rightCat] } else { @() }
        $maxAppsInRow = [Math]::Max($leftApps.Count, $rightApps.Count)
        # In từng ứng dụng trong category
        for ($j = 0; $j -lt $maxAppsInRow; $j++) {
            $leftApp = if ($j -lt $leftApps.Count) { $leftApps[$j] } else { $null }
            $rightApp = if ($j -lt $rightApps.Count) { $rightApps[$j] } else { $null }
            $leftText = if ($leftApp) { ("  [{0:00}] {1}" -f $itemNumber, $leftApp.name) } else { "" }
            $menuMap["{0:00}" -f $itemNumber] = $leftApp
            if ($leftApp) { $itemNumber++ }
            $rightText = if ($rightApp) { ("  [{0:00}] {1}" -f $itemNumber, $rightApp.name) } else { "" }
            $menuMap["{0:00}" -f $itemNumber] = $rightApp
            if ($rightApp) { $itemNumber++ }
            Write-Host ("{0,-35} {1,-35}" -f $leftText, $rightText)
        }
        Write-Host "" # Khoảng cách giữa các category
    }
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [00] Quay lai Menu Chinh" -ForegroundColor Yellow
    Write-Host ""
    return $menuMap
}

# ============================================================
# HÀM CHÍNH (ĐƯỢC GỌI TỪ ToiUuPC.ps1) - TÊN CHUẨN
# ============================================================
function Invoke-AppMenu {
    param([object]$Config)
    if (-not (Ensure-Winget)) {
        Write-Host "Kiem tra winget that bai. Tro ve menu chinh..." -ForegroundColor Red
        Pause
        return
    }
    if (-not $Config) {
        $Config = Load-ApplicationConfig
        if (-not $Config) {
            Pause
            return
        }
    }
    while ($true) {
        $menuMap = Show-AppMenu -Config $Config
        $choice = Read-Host "Nhap so ung dung de cai dat (hoac 00 de quay lai)"
        if ($choice -eq "00") {
            return # Thoát sạch về menu chính
        }
        if ($menuMap.ContainsKey($choice) -and $menuMap[$choice] -ne $null) {
            Clear-Host
            Install-Application $menuMap[$choice]
            Write-Host ""
            Pause
        } else {
            Write-Host "Lua chon khong hop le! Vui long thu lai." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
