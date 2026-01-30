# ============================================================
# PMK TOOLBOX - WINDOWS TWEAKS ENGINE
# Author : Minh Khai
# Schema  : tweaks.json v1.0
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ============================================================
# REGISTRY
# ============================================================
function Apply-RegistryTweak {
    param($t)

    try {
        if (-not (Test-Path $t.path)) {
            New-Item -Path $t.path -Force | Out-Null
        }

        Set-ItemProperty `
            -Path  $t.path `
            -Name  $t.nameReg `
            -Value $t.value `
            -Type  $t.regType `
            -Force

        return $true
    } catch { return $false }
}

# ============================================================
# SERVICE
# ============================================================
function Apply-ServiceTweak {
    param($t)

    try {
        Stop-Service $t.serviceName -Force -ErrorAction SilentlyContinue
        Set-Service `
            -Name $t.serviceName `
            -StartupType $t.startup `
            -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

# ============================================================
# SCHEDULED TASK
# ============================================================
function Apply-ScheduledTaskTweak {
    param($t)

    try {
        if ($t.taskName) {
            Disable-ScheduledTask `
                -TaskName $t.taskName `
                -ErrorAction SilentlyContinue
        }

        if ($t.tasks) {
            foreach ($task in $t.tasks) {
                Disable-ScheduledTask `
                    -TaskName $task `
                    -ErrorAction SilentlyContinue
            }
        }
        return $true
    } catch { return $false }
}

# ============================================================
# APPLY TWEAK ROUTER
# ============================================================
function Apply-Tweak {
    param($t)

    Write-Host "`n[APPLY] $($t.name)" -ForegroundColor Cyan

    $ok = $false

    switch ($t.type) {
        "registry"        { $ok = Apply-RegistryTweak       $t }
        "service"         { $ok = Apply-ServiceTweak        $t }
        "scheduled_task"  { $ok = Apply-ScheduledTaskTweak  $t }
        default {
            Write-Host "Unsupported type: $($t.type)" -ForegroundColor Red
            return
        }
    }

    if ($ok) {
        Write-Host " ✔ Applied successfully" -ForegroundColor Green
    } else {
        Write-Host " ✖ Failed" -ForegroundColor Red
    }

    if ($t.reboot_required) {
        Write-Host " ⚠ Reboot required" -ForegroundColor Yellow
    }
}

# ============================================================
# MENU
# ============================================================
function Invoke-TweaksMenu {
    param($Config)

    if (-not $Config.tweaks) {
        Write-Host "Invalid tweaks.json schema!" -ForegroundColor Red
        Read-Host "Press Enter"
        return
    }

    while ($true) {
        Clear-Host
        Write-Host "====== WINDOWS TWEAKS ======" -ForegroundColor Cyan
        Write-Host ""

        $map = @{}
        $i = 1

        foreach ($t in $Config.tweaks) {
            $key = "{0:00}" -f $i
            Write-Host " [$key] $($t.name)"
            $map[$key] = $t
            $i++
        }

        Write-Host ""
        Write-Host " [00] Back"
        Write-Host ""

        $sel = Read-Host "Select"

        if ($sel -eq "00") { return }

        if ($map.ContainsKey($sel)) {
            Apply-Tweak $map[$sel]
            Read-Host "`nPress Enter"
        } else {
            Write-Host "Invalid selection" -ForegroundColor Red
            Start-Sleep 1
        }
    }
}
