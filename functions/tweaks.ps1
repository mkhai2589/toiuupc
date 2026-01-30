# ============================================================
# PMK TOOLBOX - WINDOWS TWEAKS ENGINE (SIMPLE VERSION)
# Author : Minh Khai
# Schema  : tweaks.json v1.0
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

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

    Write-Host "`n[DANG AP DUNG] $($t.name)" -ForegroundColor Cyan

    $ok = $false

    switch ($t.type) {
        "registry"        { $ok = Apply-RegistryTweak       $t }
        "service"         { $ok = Apply-ServiceTweak        $t }
        "scheduled_task"  { $ok = Apply-ScheduledTaskTweak  $t }
        default {
            Write-Host "Khong ho tro loai tweak nay: $($t.type)" -ForegroundColor Red
            return
        }
    }

    if ($ok) {
        Write-Host "   => Thanh cong!" -ForegroundColor Green
    } else {
        Write-Host "   => That bai!" -ForegroundColor Red
    }

    if ($t.reboot_required) {
        Write-Host "   => Can khoi dong lai may!" -ForegroundColor Yellow
    }
}

# ============================================================
# MENU TWEAKS (TÊN HÀM CHUẨN: Invoke-TweaksMenu)
# ============================================================
function Invoke-TweaksMenu {
    param($Config)

    if (-not $Config.tweaks) {
        Write-Host "LOI: Cau hinh tweaks.json khong hop le!" -ForegroundColor Red
        Pause
        return
    }

    while ($true) {
        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "      TINH CHINH WINDOWS (TWEAKS)       " -ForegroundColor White
        Write-Host "========================================" -ForegroundColor Cyan
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
        Write-Host " [00] Quay lai Menu Chinh"
        Write-Host ""

        $sel = Read-Host "Lua chon"

        if ($sel -eq "00") { 
            return 
        }

        if ($map.ContainsKey($sel)) {
            Clear-Host
            Apply-Tweak $map[$sel]
            Write-Host ""
            Pause
        } else {
            Write-Host "Lua chon khong hop le!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
