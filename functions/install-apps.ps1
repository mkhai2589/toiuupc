# ==========================================================
# install-apps.ps1
# PMK Toolbox - Application Installer (WinUtil Pro)
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
        return ($result -match $PackageId)
    } catch {
        return $false
    }
}

# ==========================================================
# MAIN INSTALLER
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

    if (-not $apps -or $apps.Count -eq 0) {
        Write-Host "Khong tim thay ung dung hop le" -ForegroundColor Red
        return
    }

    $total = $apps.Count
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
        # CHECK EXIST
        # ==========================
        if (Test-AppInstalled $app.packageId) {

            Write-Host "Da cai: $($app.name)" -ForegroundColor DarkGray
            Write-Log "SKIP | $($app.name)"

            $results += [PSCustomObject]@{
                App    = $app.name
                Status = "SKIPPED"
            }
            continue
        }

        Write-Host "Dang cai: $($app.name)" -ForegroundColor Yellow
        Write-Log "INSTALL | $($app.name)"

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
            $process = Start-Process winget `
                -ArgumentList $args `
                -Wait `
                -NoNewWindow `
                -PassThru

            if ($process.ExitCode -eq 0) {
                Write-Host "OK: $($app.name)" -ForegroundColor Green
                Write-Log "OK | $($app.name)"

                $results += [PSCustomObject]@{
                    App    = $app.name
                    Status = "OK"
                }
            } else {
                throw "ExitCode $($process.ExitCode)"
            }

        } catch {
            Write-Host "FAIL: $($app.name)" -ForegroundColor Red
            Write-Log "FAIL | $($app.name) | $($_.Exception.Message)"

            $results += [PSCustomObject]@{
                App    = $app.name
                Status = "FAIL"
            }
        }
    }

    Write-Progress -Activity "Dang cai dat ung dung" -Completed

    # ==================================================
    # SUMMARY
    # ==================================================
    Write-Host "`n📊 KET QUA CAI DAT" -ForegroundColor Cyan

    $results | ForEach-Object {
        switch ($_.Status) {
            "OK"      { Write-Host " $($_.App)" -ForegroundColor Green }
            "SKIPPED" { Write-Host " $($_.App)" -ForegroundColor DarkGray }
            "FAIL"    { Write-Host " $($_.App)" -ForegroundColor Red }
        }
    }

    Write-Host "`n Hoan tat $total ung dung" -ForegroundColor Cyan
}
