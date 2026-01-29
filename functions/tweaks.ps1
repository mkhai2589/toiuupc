# =========================================================
# tweaks.ps1 – Engine Tối Ưu (KHÔNG UI)
# Chỉ xử lý logic tweak – được gọi từ ToiUuPC.ps1
# =========================================================

Set-StrictMode -Version Latest

# ---------------- ĐƯỜNG DẪN ----------------
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$ConfigDir  = Join-Path $Root "config"
$RuntimeDir = Join-Path $Root "runtime"

$LogDir     = Join-Path $RuntimeDir "logs"
$BackupDir  = Join-Path $RuntimeDir "backups"

$TweaksFile = Join-Path $ConfigDir "tweaks.json"
$LogFile    = Join-Path $LogDir "tweaks.log"

New-Item -ItemType Directory -Force -Path $LogDir, $BackupDir | Out-Null

# ---------------- GHI LOG ----------------
function Write-TweakLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $dong = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $LogFile -Value $dong -Encoding UTF8
}

# ---------------- HIỂN THỊ CONSOLE CÓ MÀU ----------------
function Write-TweakConsole {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    switch ($Level) {
        "DANGEROUS" { Write-Host $Message -ForegroundColor Red }
        "WARN"      { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS"   { Write-Host $Message -ForegroundColor Green }
        default     { Write-Host $Message }
    }
}

# ---------------- KIỂM TRA HỆ ĐIỀU HÀNH ----------------
$CurrentOS = [System.Environment]::OSVersion.Version

function Test-OSGuard {
    param($Guard)

    if (-not $Guard) { return $true }

    try {
        $min = [version]$Guard.min
        $max = [version]$Guard.max
        return ($CurrentOS -ge $min -and $CurrentOS -le $max)
    } catch {
        return $false
    }
}

# ---------------- CẤU TRÚC SAO LƯU ----------------
$Global:Backup = @{
    timestamp = Get-Date
    registry  = @{}
    services  = @{}
    tasks     = @{}
}

function Backup-Registry {
    param($Path, $Name)

    try {
        $v = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        $Backup.registry["$Path|$Name"] = $v.$Name
    } catch {
        $Backup.registry["$Path|$Name"] = "__KHÔNG_TỒN_TẠI__"
    }
}

function Backup-Service {
    param($Name)

    $s = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($s) { $Backup.services[$Name] = $s.StartType }
}

function Backup-Task {
    param($Name)

    $t = Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue
    if ($t) { $Backup.tasks[$Name] = $t.State }
}

function Save-Backup {
    $file = Join-Path $BackupDir ("tweaks_backup_{0}.json" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    $Backup | ConvertTo-Json -Depth 6 | Out-File $file -Encoding UTF8
    Write-TweakLog "Đã lưu bản sao lưu: $file"
}

# ---------------- ÁP DỤNG TWEAK ----------------
function Apply-RegistryAction {
    param($A)

    Backup-Registry $A.path $A.name
    New-Item -Path $A.path -Force | Out-Null
    Set-ItemProperty -Path $A.path -Name $A.name -Value $A.value -Type $A.value_type
}

function Apply-ServiceAction {
    param($A)

    Backup-Service $A.name
    Set-Service -Name $A.name -StartupType $A.startup -ErrorAction SilentlyContinue
}

function Apply-TaskAction {
    param($A)

    if ($A.task) {
        Backup-Task $A.task
        if ($A.action -eq "Disable") {
            Disable-ScheduledTask -TaskName $A.task -ErrorAction SilentlyContinue
        } else {
            Enable-ScheduledTask -TaskName $A.task -ErrorAction SilentlyContinue
        }
    }

    if ($A.tasks) {
        foreach ($t in $A.tasks) {
            Backup-Task $t
            Disable-ScheduledTask -TaskName $t -ErrorAction SilentlyContinue
        }
    }
}

# ---------------- ÁP DỤNG 1 TWEAK ----------------
function Apply-Tweak {
    param($Tweak)

    if (-not (Test-OSGuard $Tweak.os_guard)) {
        Write-TweakLog "BỎ QUA (KHÔNG PHÙ HỢP OS): $($Tweak.id)" "WARN"
        return
    }

    if ($Tweak.level -eq "dangerous") {
        Write-TweakConsole "⚠ TWEAK NGUY HIỂM: $($Tweak.name)" "DANGEROUS"
    }

    Write-TweakLog "ÁP DỤNG TWEAK: $($Tweak.id)"

    foreach ($a in $Tweak.apply) {
        switch ($a.type) {
            "registry"       { Apply-RegistryAction $a }
            "service"        { Apply-ServiceAction $a }
            "scheduled_task" { Apply-TaskAction $a }
        }
    }
}

# ---------------- HOÀN TÁC (ROLLBACK) ----------------
function Restore-LastBackup {

    $last = Get-ChildItem $BackupDir -Filter "tweaks_backup_*.json" |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

    if (-not $last) { throw "Không tìm thấy bản sao lưu nào" }

    $data = Get-Content $last.FullName -Raw | ConvertFrom-Json
    Write-TweakLog "HOÀN TÁC từ $($last.Name)" "WARN"

    foreach ($k in $data.registry.Keys) {
        $p = $k.Split("|")
        if ($data.registry[$k] -eq "__KHÔNG_TỒN_TẠI__") {
            Remove-ItemProperty -Path $p[0] -Name $p[1] -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path $p[0] -Name $p[1] -Value $data.registry[$k]
        }
    }

    foreach ($s in $data.services.Keys) {
        Set-Service -Name $s -StartupType $data.services[$s] -ErrorAction SilentlyContinue
    }
}

# ---------------- PRESET TỐI ƯU ----------------
$PresetMap = @{
    Privacy = @("privacy","telemetry","ai")
    Gaming  = @("performance","ui")
    Office  = @("ui","update","security")
}

# ---------------- ENTRY POINT ----------------
function Invoke-Tweaks {
    param(
        [string[]]$Ids,
        [ValidateSet("Privacy","Gaming","Office")]
        [string]$Preset,
        [switch]$Rollback
    )

    if ($Rollback) {
        Restore-LastBackup
        return
    }

    if (-not (Test-Path $TweaksFile)) {
        throw "Không tìm thấy file tweaks.json"
    }

    $json = Get-Content $TweaksFile -Raw | ConvertFrom-Json
    $Tweaks = $json.tweaks

    Save-Backup

    if ($Preset) {
        $cats = $PresetMap[$Preset]
        $Tweaks = $Tweaks | Where-Object { $cats -contains $_.category }
        Write-TweakConsole "Đang áp dụng preset: $Preset" "SUCCESS"
    }

    if ($Ids) {
        $Tweaks = $Tweaks | Where-Object { $Ids -contains $_.id }
    }

    foreach ($t in $Tweaks) {
        Apply-Tweak $t
    }
}
