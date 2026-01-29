# ==========================================
# PMK ToiUuPC – Application Installer Engine
# UI: Console Checkbox
# Log: logs/apps.log
# Rollback: winget uninstall
# ==========================================

$ErrorActionPreference = "Stop"

# ---------- Paths ----------
$Root = Split-Path -Parent $PSScriptRoot
$ConfigPath = Join-Path $Root "config\applications.json"
$LogDir = Join-Path $Root "logs"
$LogFile = Join-Path $LogDir "apps.log"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

# ---------- Logging ----------
function Write-AppLog {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time [$Level] $Message" | Tee-Object -FilePath $LogFile -Append
}

# ---------- Winget Check ----------
function Test-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Winget chưa có trên hệ thống." -ForegroundColor Red
        Write-Host "👉 Yêu cầu Windows 10 1809+ hoặc Windows 11." -ForegroundColor Yellow
        Write-AppLog "Winget not found" "ERROR"
        return $false
    }
    return $true
}

# ---------- Load applications.json ----------
function Load-ApplicationsConfig {
    if (-not (Test-Path $ConfigPath)) {
        throw "❌ Không tìm thấy applications.json"
    }
    return Get-Content $ConfigPath -Raw | ConvertFrom-Json
}

# ---------- Detect installed app ----------
function Test-AppInstalled {
    param ([string]$PackageId)

    $result = winget list --id $PackageId --exact 2>$null
    return ($result -match $PackageId)
}

# ---------- UI: Select Preset ----------
function Select-Preset {
    Clear-Host
    Write-Host "===== CHỌN PRESET =====" -ForegroundColor Cyan
    Write-Host "1. Office"
    Write-Host "2. Gaming"
    Write-Host "3. Privacy"
    Write-Host "4. Tùy chọn thủ công"
    Write-Host ""

    switch (Read-Host "Chọn") {
        "1" { return "Office" }
        "2" { return "Gaming" }
        "3" { return "Privacy" }
        default { return $null }
    }
}

# ---------- UI: Checkbox Select ----------
function Select-Applications {
    param ([array]$Apps)

    $selected = @{}
    for ($i = 0; $i -lt $Apps.Count; $i++) {
        $selected[$i] = $false
    }

    while ($true) {
        Clear-Host
        Write-Host "===== CHỌN ỨNG DỤNG =====" -ForegroundColor Cyan
        Write-Host "Số = bật/tắt | A = tất | N = bỏ | ENTER = tiếp tục`n" -ForegroundColor DarkGray

        for ($i = 0; $i -lt $Apps.Count; $i++) {
            $check = if ($selected[$i]) { "[x]" } else { "[ ]" }
            $installed = Test-AppInstalled $Apps[$i].packageId
            $status = if ($installed) { "(đã cài)" } else { "" }
            $color = if ($installed) { "DarkGray" } else { "White" }

            Write-Host ("{0,2}. {1} {2} {3}" -f ($i + 1), $check, $Apps[$i].name, $status) -ForegroundColor $color
        }

        $input = Read-Host "`nChọn"
        if ([string]::IsNullOrWhiteSpace($input)) { break }

        switch ($input.ToUpper()) {
            "A" { $selected.Keys | ForEach-Object { $selected[$_] = $true } }
            "N" { $selected.Keys | ForEach-Object { $selected[$_] = $false } }
            default {
                if ($input -match '^\d+$') {
                    $idx = [int]$input - 1
                    if ($idx -ge 0 -and $idx -lt $Apps.Count) {
                        $selected[$idx] = -not $selected[$idx]
                    }
                }
            }
        }
    }

    return $selected
}

# ---------- Install Apps ----------
function Install-Applications {
    param (
        [array]$Apps,
        [hashtable]$Selected
    )

    foreach ($key in $Selected.Keys) {
        if (-not $Selected[$key]) { continue }

        $app = $Apps[$key]

        if (Test-AppInstalled $app.packageId) {
            Write-Host "⏭ Đã cài: $($app.name)" -ForegroundColor DarkGray
            Write-AppLog "Skipped (already installed): $($app.packageId)"
            continue
        }

        Write-Host "`n➡ Cài $($app.name)..." -ForegroundColor Yellow
        Write-AppLog "Installing $($app.packageId)"

        try {
            winget install `
                --id $app.packageId `
                --source $app.source `
                --accept-package-agreements `
                --accept-source-agreements `
                --silent

            Write-AppLog "Installed $($app.packageId)" "SUCCESS"
        }
        catch {
            Write-Host "❌ Lỗi khi cài $($app.name)" -ForegroundColor Red
            Write-AppLog "Failed $($app.packageId): $_" "ERROR"
        }
    }
}

# ---------- Rollback ----------
function Rollback-Applications {
    param ([array]$Apps)

    foreach ($app in $Apps) {
        if (Test-AppInstalled $app.packageId) {
            Write-Host "↩ Gỡ $($app.name)" -ForegroundColor Yellow
            Write-AppLog "Uninstalling $($app.packageId)"

            winget uninstall --id $app.packageId --silent
        }
    }
}

# ---------- MAIN ENTRY ----------
function Invoke-AppInstaller {

    if (-not (Test-Winget)) { return }

    $config = Load-ApplicationsConfig
    $preset = Select-Preset

    if ($preset) {
        $apps = $config.applications | Where-Object { $_.preset -contains $preset }
    }
    else {
        $apps = $config.applications
    }

    if ($apps.Count -eq 0) {
        Write-Host "❌ Không có ứng dụng phù hợp preset." -ForegroundColor Red
        return
    }

    $selected = Select-Applications -Apps $apps
    Install-Applications -Apps $apps -Selected $selected

    Write-Host "`n✅ Hoàn tất cài ứng dụng." -ForegroundColor Green
    Write-AppLog "Installation finished"
}
