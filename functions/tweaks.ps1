# ==========================================================
# tweaks.ps1
# PMK Toolbox - Windows Tweaks Engine (WinUtil Style)
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ==========================================================
# TWEAK STATE DETECTION
# ==========================================================
function Get-TweakState {
    param($Tweak)

    try {
        switch ($Tweak.type) {

            "registry" {
                $val = Get-ItemProperty `
                    -Path $Tweak.path `
                    -Name $Tweak.nameReg `
                    -ErrorAction Stop

                if ($val.$($Tweak.nameReg) -eq $Tweak.value) {
                    return "ON"
                } else {
                    return "OFF"
                }
            }

            "service" {
                $svc = Get-CimInstance Win32_Service `
                    -Filter "Name='$($Tweak.serviceName)'" `
                    -ErrorAction Stop

                if ($svc.StartMode -eq $Tweak.startup) {
                    return "ON"
                } else {
                    return "OFF"
                }
            }

            "service_multiple" {
                foreach ($s in $Tweak.services) {
                    $svc = Get-CimInstance Win32_Service `
                        -Filter "Name='$($s.name)'" `
                        -ErrorAction Stop

                    if ($svc.StartMode -ne $s.startup) {
                        return "OFF"
                    }
                }
                return "ON"
            }

            "scheduled_task" {
                if ($Tweak.taskName) {
                    $task = Get-ScheduledTask `
                        -TaskName $Tweak.taskName `
                        -ErrorAction Stop
                    return ($task.Enabled -eq $false) ? "ON" : "OFF"
                }

                if ($Tweak.tasks) {
                    foreach ($name in $Tweak.tasks) {
                        $task = Get-ScheduledTask `
                            -TaskName $name `
                            -ErrorAction Stop
                        if ($task.Enabled) { return "OFF" }
                    }
                    return "ON"
                }
            }
        }
    } catch {
        return "UNKNOWN"
    }

    return "UNKNOWN"
}

# ==========================================================
# BUILD GUI MODEL (CHECKBOX + STATE)
# ==========================================================
function Build-TweakViewModel {
    param([array]$Tweaks)

    foreach ($t in $Tweaks) {
        $state = Get-TweakState $t

        [PSCustomObject]@{
            Id          = $t.id
            Name        = $t.name
            Description = $t.description
            Category    = $t.category
            State       = $state
            IsChecked   = ($state -eq "ON")
            Raw         = $t
        }
    }
}

# ==========================================================
# APPLY SYSTEM TWEAKS
# ==========================================================
function Invoke-SystemTweaks {
    param(
        [array]$Tweaks,
        [string[]]$SelectedIds,
        [string]$BackupPath,
        $ProgressBar
    )

    if (-not (Test-Path $BackupPath)) {
        New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    }

    $applyList = $Tweaks | Where-Object { $_.id -in $SelectedIds }
    $total = $applyList.Count
    $i = 0

    foreach ($t in $applyList) {
        $i++
        Set-Progress $ProgressBar $i $total
        Write-Log "Apply tweak: $($t.id)"

        switch ($t.type) {

            # ---------------- REGISTRY ----------------
            "registry" {
                if (-not (Test-Path $t.path)) {
                    New-Item -Path $t.path -Force | Out-Null
                }

                $bkFile = Join-Path $BackupPath "$($t.id).json"

                if (-not (Test-Path $bkFile)) {
                    try {
                        $old = Get-ItemProperty `
                            -Path $t.path `
                            -Name $t.nameReg `
                            -ErrorAction SilentlyContinue

                        if ($old) {
                            $old | ConvertTo-Json |
                                Out-File $bkFile -Encoding UTF8
                        }
                    } catch {}
                }

                Set-ItemProperty `
                    -Path $t.path `
                    -Name $t.nameReg `
                    -Value $t.value `
                    -Type $t.regType
            }

            # ---------------- SERVICE ----------------
            "service" {
                $svc = Get-Service -Name $t.serviceName -ErrorAction SilentlyContinue
                if ($svc) {
                    sc.exe config $t.serviceName start= $t.startup | Out-Null
                    if ($t.startup -eq "disabled") {
                        Stop-Service $t.serviceName -Force -ErrorAction SilentlyContinue
                    }
                }
            }

            "service_multiple" {
                foreach ($s in $t.services) {
                    $svc = Get-Service -Name $s.name -ErrorAction SilentlyContinue
                    if ($svc) {
                        sc.exe config $s.name start= $s.startup | Out-Null
                        if ($s.startup -eq "disabled") {
                            Stop-Service $s.name -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
            }

            # ---------------- SCHEDULED TASK ----------------
            "scheduled_task" {
                if ($t.taskName) {
                    Get-ScheduledTask -TaskName $t.taskName -ErrorAction SilentlyContinue |
                        Disable-ScheduledTask | Out-Null
                }

                if ($t.tasks) {
                    foreach ($name in $t.tasks) {
                        Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue |
                            Disable-ScheduledTask | Out-Null
                    }
                }
            }
        }
    }

    Set-Progress $ProgressBar $total $total
    Write-Log "System tweaks applied"
}

# ==========================================================
# UNDO SYSTEM TWEAKS (REGISTRY ONLY - SAFE)
# ==========================================================
function Undo-SystemTweaks {
    param([string]$BackupPath)

    if (-not (Test-Path $BackupPath)) {
        Write-Log "No backup found" "WARN"
        return
    }

    Get-ChildItem $BackupPath -Filter "*.json" | ForEach-Object {
        try {
            $data = Get-Content $_.FullName -Raw | ConvertFrom-Json

            if ($data.PSPath -and $data.PSChildName) {
                Set-ItemProperty `
                    -Path $data.PSPath `
                    -Name $data.PSChildName `
                    -Value $data.$($data.PSChildName)
            }
        } catch {
            Write-Log "Undo failed: $($_.Name)" "WARN"
        }
    }

    Write-Log "Undo tweaks completed"
}
