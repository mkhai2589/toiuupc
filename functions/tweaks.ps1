# ==========================================================
# tweaks.ps1
# PMK Toolbox - Windows Tweaks Engine
# Compatible with tweaks.json schema (FULL)
# ==========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ==========================================================
# LOG
# ==========================================================
$Global:TweaksLog = Join-Path $Global:LogDir "tweaks.log"

function Write-TweakLog {
    param([string]$Message)
    Write-Log -Message "[TWEAK] $Message"
    "$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")) $Message" |
        Out-File -FilePath $Global:TweaksLog -Append -Encoding UTF8
}

# ==========================================================
# OS GUARD
# ==========================================================
function Test-OsGuard {
    param($Guard)

    if (-not $Guard) { return $true }

    try {
        $ver = [System.Environment]::OSVersion.Version
        $cur = [double]("{0}.{1}" -f $ver.Major, $ver.Minor)

        if ($Guard.min) {
            if ($cur -lt [double]$Guard.min) { return $false }
        }
        if ($Guard.max) {
            if ($cur -gt [double]$Guard.max) { return $false }
        }
        return $true
    }
    catch {
        return $true
    }
}

# ==========================================================
# TWEAK STATE
# ==========================================================
function Get-TweakState {
    param($Tweak)

    try {
        switch ($Tweak.type) {

            "registry" {
                if (-not (Test-Path $Tweak.path)) { return "OFF" }

                $val = Get-ItemProperty -Path $Tweak.path `
                        -Name $Tweak.nameReg -ErrorAction SilentlyContinue

                if ($null -eq $val) { return "OFF" }

                if ($val.$($Tweak.nameReg) -eq $Tweak.value) {
                    return "ON"
                }
                return "OFF"
            }

            "service" {
                $svc = Get-Service -Name $Tweak.serviceName -ErrorAction Stop
                if ($svc.StartType.ToString().ToLower() -eq $Tweak.startup.ToLower()) {
                    return "ON"
                }
                return "OFF"
            }

            "scheduled_task" {
                if ($Tweak.taskName) {
                    $task = Get-ScheduledTask -TaskName $Tweak.taskName -ErrorAction Stop
                    if ($task.Enabled -eq $false) { return "ON" }
                    return "OFF"
                }

                if ($Tweak.tasks) {
                    foreach ($t in $Tweak.tasks) {
                        $task = Get-ScheduledTask -TaskName $t -ErrorAction Stop
                        if ($task.Enabled) { return "OFF" }
                    }
                    return "ON"
                }
            }
        }
    }
    catch {
        return "UNKNOWN"
    }

    return "UNKNOWN"
}

# ==========================================================
# APPLY TWEAK
# ==========================================================
function Apply-Tweak {
    param($Tweak)

    if (-not (Test-OsGuard $Tweak.os_guard)) {
        Write-Host "OS not supported for this tweak" -ForegroundColor Yellow
        return
    }

    switch ($Tweak.type) {

        "registry" {
            if (-not (Test-Path $Tweak.path)) {
                New-Item -Path $Tweak.path -Force | Out-Null
            }

            Set-ItemProperty `
                -Path  $Tweak.path `
                -Name  $Tweak.nameReg `
                -Value $Tweak.value `
                -Type  $Tweak.regType `
                -Force

            Write-TweakLog "Registry ON: $($Tweak.id)"
        }

        "service" {
            sc.exe config $Tweak.serviceName start= $Tweak.startup | Out-Null
            if ($Tweak.startup -eq "Disabled") {
                Stop-Service $Tweak.serviceName -Force -ErrorAction SilentlyContinue
            }
            Write-TweakLog "Service ON: $($Tweak.serviceName)"
        }

        "scheduled_task" {
            if ($Tweak.taskName) {
                Disable-ScheduledTask -TaskName $Tweak.taskName `
                    -ErrorAction SilentlyContinue | Out-Null
            }
            if ($Tweak.tasks) {
                foreach ($t in $Tweak.tasks) {
                    Disable-ScheduledTask -TaskName $t `
                        -ErrorAction SilentlyContinue | Out-Null
                }
            }
            Write-TweakLog "Task ON: $($Tweak.id)"
        }
    }
}

# ==========================================================
# UNDO TWEAK
# ==========================================================
function Undo-Tweak {
    param($Tweak)

    if (-not $Tweak.rollback) {
        Write-Host "No rollback defined" -ForegroundColor Yellow
        return
    }

    switch ($Tweak.type) {

        "registry" {
            if (-not (Test-Path $Tweak.path)) { return }

            Set-ItemProperty `
                -Path  $Tweak.path `
                -Name  $Tweak.nameReg `
                -Value $Tweak.rollback.value `
                -Force

            Write-TweakLog "Registry OFF: $($Tweak.id)"
        }

        "service" {
            sc.exe config $Tweak.serviceName start= $Tweak.rollback.startup | Out-Null
            Write-TweakLog "Service OFF: $($Tweak.serviceName)"
        }

        "scheduled_task" {
            if ($Tweak.taskName) {
                Enable-ScheduledTask -TaskName $Tweak.taskName `
                    -ErrorAction SilentlyContinue | Out-Null
            }
            if ($Tweak.tasks) {
                foreach ($t in $Tweak.tasks) {
                    Enable-ScheduledTask -TaskName $t `
                        -ErrorAction SilentlyContinue | Out-Null
                }
            }
            Write-TweakLog "Task OFF: $($Tweak.id)"
        }
    }
}

# ==========================================================
# MENU
# ==========================================================
function Invoke-TweaksMenu {
    param([object]$Config)

    $Tweaks = $Config.tweaks

    while ($true) {
        Clear-Screen
        Write-Host "WINDOWS TWEAKS" -ForegroundColor Cyan
        Write-Host ""

        $map = @{}
        $i = 1

        foreach ($t in $Tweaks) {
            $state = Get-TweakState $t
            $color = if ($state -eq "ON") { "Green" } else { "Yellow" }

            Write-Host ("[{0}] {1} [{2}]" -f $i, $t.name, $state) `
                -ForegroundColor $color

            $map[$i] = $t
            $i++
        }

        Write-Host ""
        Write-Host "[0] Back"
        $sel = Read-Choice "Select"

        if ($sel -eq "0") { break }

        if ($map.ContainsKey([int]$sel)) {
            $item = $map[[int]$sel]
            $state = Get-TweakState $item

            if ($state -eq "ON") {
                Undo-Tweak $item
            }
            else {
                Apply-Tweak $item
            }

            Start-Sleep 1
        }
    }
}
