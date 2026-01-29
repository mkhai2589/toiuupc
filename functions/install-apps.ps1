# ==========================================================
# install-apps.ps1
# PMK Toolbox - Application Installer (WinUtil compatible)
# PowerShell 5.1 SAFE
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ==========================================================
# CHECK WINGET
# ==========================================================
function Ensure-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Winget chua duoc cai dat" -ForegroundColor Red
        return $false
    }
    return $true
}

# ==========================================================
# CHECK APP INSTALLED
# ==========================================================
function Test-AppInstalled {
    param([string]$PackageId)

    try {
        $result = winget list --id $PackageId -e 2>$null
        if ($result -match $PackageId) {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

# ==========================================================
# MAIN INSTALLER (CORE)
# ==========================================================
function Invoke-AppInstaller {
    param(
        [object]$Config,
        [string[]]$SelectedIds
    )

    if (-not (Ensure-Winget)) { return }

    if (-not $SelectedIds -or $SelectedIds.Count -eq 0) {
        Write-Host "Khong co ung dung nao duoc chon" -ForegroundColor Yellow
        return
    }

    $apps = $Config.applications | Where-Object { $_.id -in $SelectedIds }
    if (-not $apps) {
        Write-Host "Khong tim thay ung dung hop le" -ForegroundColor Red
        return
    }

    $total   = $apps.Count
    $current = 0
    $results = @()

    Write-Host "`n Dang cai dat ung dung..." -ForegroundColor Cyan

    foreach ($app in $apps) {

        $current++
        $percent = [int](($current / $total) * 100)

        Write-Progress `
            -Activity "Dang cai dat ung dung" `
            -Status "$($app.name) ($current/$total)" `
            -PercentComplete $percent

        # ==========================
        # CHECK INSTALLED
        # ==========================
        if (Test-AppInstalled $app.packageId) {
            Write-Host "Da cai: $($app.name)" -ForegroundColor DarkGray
            $results += [PSCustomObject]@{
                App    = $app.name
                Status = "SKIPPED"
            }
            continue
        }

        Write-Host "Dang cai: $($app.name)" -ForegroundColor Yellow

        $args = @(
            "install",
            "--id", $app.packageId,
            "-e"
        )

        if ($app.source) {
            $args += @("--source", $app.source)
        }

        if ($app.silent) {
            $args += @(
                "--silent",
                "--accept-package-agreements",
                "--accept-source-agreements"
            )
        }

        try {
            $p = Start-Process winget `
                -ArgumentList $args `
                -Wait `
                -NoNewWindow `
                -PassThru

            if ($p.ExitCode -eq 0) {
                Write-Host "OK: $($app.name)" -ForegroundColor Green
                $results += [PSCustomObject]@{
                    App    = $app.name
                    Status = "OK"
                }
            }
            else {
                throw "ExitCode $($p.ExitCode)"
            }
        }
        catch {
            Write-Host "FAIL: $($app.name)" -ForegroundColor Red
            $results += [PSCustomObject]@{
                App    = $app.name
                Status = "FAIL"
            }
        }
    }

    Write-Progress -Activity "Dang cai dat ung dung" -Completed

    # ==========================
    # SUMMARY
    # ==========================
    Write-Host "`n KET QUA CAI DAT" -ForegroundColor Cyan
    foreach ($r in $results) {
        switch ($r.Status) {
            "OK"      { Write-Host " $($r.App)" -ForegroundColor Green }
            "SKIPPED" { Write-Host " $($r.App)" -ForegroundColor DarkGray }
            "FAIL"    { Write-Host " $($r.App)" -ForegroundColor Red }
        }
    }

    Write-Host "`n Hoan tat $total ung dung" -ForegroundColor Cyan
}

# ==========================================================
# MENU WRAPPER (REQUIRED BY ToiUuPC.ps1)
# ==========================================================
function Invoke-AppMenu {
    param([object]$Config)

    if (-not $Config -or -not $Config.applications) {
        Write-Host "Invalid applications config" -ForegroundColor Red
        return
    }

    $apps     = $Config.applications
    $selected = @{}

    while ($true) {
        Clear-Host
        Write-Host "==============================="
        Write-Host " INSTALL APPLICATIONS"
        Write-Host "==============================="
        Write-Host ""

        $i   = 1
        $map = @{}

        foreach ($app in $apps) {

            $checked = $selected.ContainsKey($app.id)
            $status  = Test-AppInstalled $app.packageId

            if ($checked) {
                $flag = "[X]"
            }
            else {
                $flag = "[ ]"
            }

            if ($status) {
                $inst = "(Installed)"
            }
            else {
                $inst = ""
            }

            Write-Host ("[{0}] {1} {2} {3}" -f $i, $flag, $app.name, $inst)
            $map[$i] = $app
            $i++
        }

        Write-Host ""
        Write-Host "Nhap so de CHON / BO CHON"
        Write-Host "Nhan I de CAI DAT"
        Write-Host "Nhan ENTER de thoat"
        Write-Host ""

        $input = Read-Host "Chon"
        if (-not $input) { break }

        if ($input -match "^[Ii]$") {
            Invoke-AppInstaller `
                -Config $Config `
                -SelectedIds $selected.Keys
            Pause
            break
        }

        $num = [int]$input
        if ($map.ContainsKey($num)) {
            $id = $map[$num].id
            if ($selected.ContainsKey($id)) {
                $selected.Remove($id)
            }
            else {
                $selected[$id] = $true
            }
        }
    }
}
