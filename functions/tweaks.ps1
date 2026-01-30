# tweaks.ps1 - Sửa tên hàm và bổ sung rollback
Set-StrictMode -Off
$ErrorActionPreference = 'SilentlyContinue'

function Apply-RegistryTweak {
    param($t)
    try {
        if (-not (Test-Path $t.path)) {
            New-Item -Path $t.path -Force | Out-Null
        }
        Set-ItemProperty -Path $t.path -Name $t.nameReg -Value $t.value -Type $t.regType -Force
        return $true
    } catch { return $false }
}

function Apply-ServiceTweak {
    param($t)
    try {
        Stop-Service $t.serviceName -Force -ErrorAction SilentlyContinue
        Set-Service -Name $t.serviceName -StartupType $t.startup -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

function Apply-ScheduledTaskTweak {
    param($t)
    try {
        if ($t.taskName) {
            Disable-ScheduledTask -TaskName $t.taskName -ErrorAction SilentlyContinue
        }
        if ($t.tasks) {
            foreach ($task in $t.tasks) {
                Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
            }
        }
        return $true
    } catch { return $false }
}

# Hàm kiểm tra điều kiện hệ điều hành
function Test-OSGuard {
    param($t)
    if (-not $t.os_guard) { return $true }
    $os = Get-CimInstance Win32_OperatingSystem
    $currentVersion = [version]$os.Version
    $min = if ($t.os_guard.min) { [version]$t.os_guard.min } else { $currentVersion }
    $max = if ($t.os_guard.max) { [version]$t.os_guard.max } else { $currentVersion }
    return ($currentVersion -ge $min -and $currentVersion -le $max)
}

function Apply-Tweak {
    param($t)
    Write-Host "`n[APPLY] $($t.name)" -ForegroundColor Cyan
    # Kiểm tra điều kiện OS
    if (-not (Test-OSGuard $t)) {
        Write-Host " Skipped (not compatible with current OS version)" -ForegroundColor Yellow
        return
    }
    $ok = $false
    switch ($t.type) {
        "registry"        { $ok = Apply-RegistryTweak $t }
        "service"         { $ok = Apply-ServiceTweak $t }
        "scheduled_task"  { $ok = Apply-ScheduledTaskTweak $t }
        default {
            Write-Host " Unsupported type: $($t.type)" -ForegroundColor Red
            return
        }
    }
    if ($ok) {
        Write-Host " Applied successfully" -ForegroundColor Green
    } else {
        Write-Host " Failed" -ForegroundColor Red
    }
    if ($t.reboot_required) {
        Write-Host " Reboot required" -ForegroundColor Yellow
    }
}

# Hàm chính để gọi từ menu - TÊN HÀM PHẢI LÀ Invoke-TweaksMenu
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
            Write-Host " [$i] $($t.name)"
            $map[$i] = $t
            $i++
        }
        Write-Host ""
        Write-Host " [0] Back"
        Write-Host ""
        $sel = Read-Host "Select"
        if ($sel -eq "0") { return }
        if ($map.ContainsKey([int]$sel)) {
            Apply-Tweak $map[[int]$sel]
            Read-Host "`nPress Enter"
        } else {
            Write-Host "Invalid selection" -ForegroundColor Red
            Start-Sleep 1
        }
    }
}
