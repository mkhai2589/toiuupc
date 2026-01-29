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

                return ($val.$($Tweak.nameReg) -eq $Tweak.value) ? "ON" : "OFF"
            }

            "service" {
                $svc = Get-CimInstance Win32_Service `
                    -Filter "Name='$($Tweak.serviceName)'" `
                    -ErrorAction Stop

                return ($svc.StartMode -eq $Tweak.startup) ? "ON" : "OFF"
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
                    $task = Get-ScheduledTask -TaskName $Tweak.taskName -ErrorAction Stop
                    return ($task.Enabled -eq $false) ? "ON" : "OFF"
                }

                if ($Tweak.tasks) {
                    foreach ($name in $Tweak.tasks) {
                        $task = Get-ScheduledTask -TaskName $name -ErrorAction Stop
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
# VIEW MODEL
# ==========================================================
function Build-TweakViewModel {
    param([array]$Tweaks)

    $list = @()

    foreach ($t in $Tweaks) {
        $state = Get-TweakState $t

        $list += [PSCustomObject]@{
            Id        = $t.id
            Name      = $t.name
            Category  = $t.category
            State     = $state
            Raw       = $t
        }
    }

    return $list
}

# ==========================================================
# APPLY SINGLE TWEAK (ON)
# ==========================================================
function Apply-Tweak {
    param($Tweak, $BackupPath)

    switch ($Tweak.type) {

        "registry" {
            if (-not (Test-Path $Tweak.path)) {
                New-Item -Path $Tweak.path -Force | Out-Null
            }

            $bkFile = Join-Path $BackupPath "$($Tweak.id).json"
            if (-not (Test-Path $bkFile)) {
                $old = Get-ItemProperty `
                    -Path $Tweak.path `
                    -Name $Tweak.nameReg `
                    -ErrorAction SilentlyContinue
                if ($old) {
                    $old | ConvertTo-Json | Out-File $bkFile -Encoding UTF8
                }
            }

            Set-ItemProperty `
                -Path $Tweak.path `
                -Name $Tweak.nameReg `
                -Value $Tweak.value `
                -Type $Tweak.regType `
                -Force
        }

        "service" {
            sc.exe config $Tweak.serviceName start= $Tweak.startup | Out-Null
            if ($Tweak.startup -eq "disabled") {
                Stop-Service $Tweak.serviceName -Force -ErrorAction SilentlyContinue
            }
        }

        "service_multiple" {
            foreach ($s in $Tweak.services) {
                sc.exe config $s.name start= $s.startup | Out-Null
                if ($s.startup -eq "disabled") {
                    Stop-Service $s.name -Force -ErrorAction SilentlyContinue
                }
            }
        }

        "scheduled_task" {
            if ($Tweak.taskName) {
                Disable-ScheduledTask -TaskName $Tweak.taskName -ErrorAction SilentlyContinue | Out-Null
            }
            if ($Tweak.tasks) {
                foreach ($name in $Tweak.tasks) {
                    Disable-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue | Out-Null
                }
            }
        }
    }
}

# ==========================================================
# UNDO SINGLE TWEAK (OFF)
# ==========================================================
function Undo-Tweak {
    param($Tweak, $BackupPath)

    if ($Tweak.type -ne "registry") {
        Write-Host "Undo not supported for $($Tweak.id)" -ForegroundColor Yellow
        return
    }

    $bkFile = Join-Path $BackupPath "$($Tweak.id).json"
    if (-not (Test-Path $bkFile)) {
        Write-Host "No backup for $($Tweak.id)" -ForegroundColor Yellow
        return
    }

    $data = Get-Content $bkFile -Raw | ConvertFrom-Json
    if ($data.PSPath -and $data.PSChildName) {
        Set-ItemProperty `
            -Path $data.PSPath `
            -Name $data.PSChildName `
            -Value $data.$($data.PSChildName)
    }
}

# ==========================================================
# MAIN MENU (REQUIRED)
# ==========================================================
function Invoke-TweaksMenu {
    param([object]$Config)

    if (-not $Config -or -not $Config.tweaks) {
        Write-Host "Invalid tweaks config" -ForegroundColor Red
        return
    }

    $BackupPath = Join-Path $env:TEMP "PMK_Tweaks_Backup"
    if (-not (Test-Path $BackupPath)) {
        New-Item -ItemType Directory -Path $BackupPath | Out-Null
    }

    do {
        Clear-Host
        Write-Host "==============================="
        Write-Host " WINDOWS TWEAKS"
        Write-Host "==============================="
        Write-Host ""

        $vm = Build-TweakViewModel $Config.tweaks
        $map = @{}
        $i = 1

        foreach ($t in $vm) {
            $color = ($t.State -eq "ON") ? "Green" : "Yellow"
            Write-Host ("[{0}] {1} [{2}]" -f $i, $t.Name, $t.State) -ForegroundColor $color
            $map[$i] = $t
            $i++
        }

        Write-Host ""
        Write-Host "Enter number to TOGGLE (ON/OFF)"
        Write-Host "Enter U<ID> to UNDO by ID (ex: U disable_telemetry)"
        Write-Host "Press ENTER to return"
        Write-Host ""

        $input = Read-Host "Select"
        if (-not $input) { break }

        # UNDO BY ID
        if ($input -match "^U\s*(.+)$") {
            $id = $Matches[1]
            $t = $Config.tweaks | Where-Object { $_.id -eq $id }
            if ($t) {
                Undo-Tweak $t $BackupPath
                Write-Host "Undo completed for $id" -ForegroundColor Cyan
            }
            Start-Sleep 1
            continue
        }

        # TOGGLE
        $num = [int]$input
        if ($map.ContainsKey($num)) {
            $item = $map[$num]
            $raw  = $item.Raw

            if ($item.State -eq "ON") {
                Undo-Tweak $raw $BackupPath
                Write-Host "Tweak OFF: $($raw.name)" -ForegroundColor Yellow
            }
            else {
                Apply-Tweak $raw $BackupPath
                Write-Host "Tweak ON: $($raw.name)" -ForegroundColor Green
            }
            Start-Sleep 1
        }

    } while ($true)
}
