# =========================================================
# utils.ps1 – Common Helpers (ToiUuPC)
# Author: PMK
# =========================================================

Set-StrictMode -Version Latest

# ---------------- GLOBAL COLORS ----------------
$global:COLOR_TEXT     = "White"
$global:COLOR_HEADER   = "Cyan"
$global:COLOR_SUCCESS  = "Green"
$global:COLOR_ERROR    = "Red"
$global:COLOR_WARN     = "Yellow"
$global:COLOR_BORDER   = "DarkGray"
$global:COLOR_DANGER   = "Red"

# ---------------- PATHS ----------------
$global:ROOT_DIR = Split-Path -Parent $PSScriptRoot
$global:LOG_DIR  = Join-Path $ROOT_DIR "logs"

if (-not (Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR | Out-Null
}

# ---------------- CONSOLE ----------------
function Reset-Console {
    try {
        $Host.UI.RawUI.BackgroundColor = "Black"
        $Host.UI.RawUI.ForegroundColor = $COLOR_TEXT
        Clear-Host
    } catch {}
}

function Write-Color {
    param(
        [string]$Message,
        [string]$Color = $COLOR_TEXT
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)

    Write-Host "==================================================" -ForegroundColor $COLOR_BORDER
    Write-Host " $Title" -ForegroundColor $COLOR_HEADER
    Write-Host "==================================================" -ForegroundColor $COLOR_BORDER
}

# ---------------- SYSTEM INFO ----------------
function Show-SystemHeader {

    $os  = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)

    $build = (Get-ItemProperty `
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild

    Write-Host "==================================================" -ForegroundColor $COLOR_BORDER
    Write-Host " ToiUuPC – Windows Optimization Toolkit" -ForegroundColor $COLOR_HEADER
    Write-Host "--------------------------------------------------" -ForegroundColor $COLOR_BORDER
    Write-Host " User : $env:USERNAME" -ForegroundColor $COLOR_TEXT
    Write-Host " PC   : $env:COMPUTERNAME" -ForegroundColor $COLOR_TEXT
    Write-Host " OS   : $($os.Caption) (Build $build)" -ForegroundColor $COLOR_TEXT
    Write-Host " CPU  : $($cpu.Name.Split('@')[0].Trim())" -ForegroundColor $COLOR_TEXT
    Write-Host " RAM  : $ram GB" -ForegroundColor $COLOR_TEXT
    Write-Host "--------------------------------------------------" -ForegroundColor $COLOR_BORDER
    Write-Host " Author: Phạm Minh Khải (PMK)" -ForegroundColor $COLOR_HEADER
    Write-Host "==================================================" -ForegroundColor $COLOR_BORDER
    Write-Host ""
}

# ---------------- LOGGING ----------------
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$File = "general.log"
    )

    $path = Join-Path $LOG_DIR $File
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time [$Level] $Message" | Add-Content -Path $path -Encoding UTF8
}

# ---------------- ADMIN CHECK ----------------
function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Color "❌ Vui lòng chạy PowerShell với quyền Administrator" $COLOR_ERROR
        Pause
        exit 1
    }
}

# ---------------- REGISTRY HELPERS ----------------
function Set-RegistryValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object]$Value,
        [ValidateSet("String","ExpandString","DWord","QWord","Binary","MultiString")]
        [string]$Type = "DWord",
        [switch]$CreatePath
    )

    try {
        if ($CreatePath -and -not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }

        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
        Write-Log "Set registry: $Path\$Name = $Value"
    }
    catch {
        Write-Log "Registry error $Path\$Name : $_" "ERROR"
    }
}

function Remove-RegistryValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name
    )

    try {
        Remove-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        Write-Log "Removed registry: $Path\$Name"
    }
    catch {}
}

# ---------------- SERVICE ----------------
function Set-ServiceStartupSafe {
    param(
        [string]$Name,
        [ValidateSet("Automatic","Manual","Disabled")]
        [string]$Startup
    )

    try {
        Set-Service -Name $Name -StartupType $Startup -ErrorAction Stop
        Write-Log "Service $Name → $Startup"
    }
    catch {
        Write-Log "Service error $Name : $_" "WARN"
    }
}

# ---------------- TASK ----------------
function Set-ScheduledTaskStateSafe {
    param(
        [string]$TaskName,
        [ValidateSet("Enable","Disable")]
        [string]$Action
    )

    try {
        if ($Action -eq "Disable") {
            Disable-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        } else {
            Enable-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        }
        Write-Log "Task $TaskName → $Action"
    }
    catch {
        Write-Log "Task error $TaskName : $_" "WARN"
    }
}

# ---------------- RESTORE POINT ----------------
function Create-SystemRestorePoint {
    try {
        Checkpoint-Computer `
            -Description "ToiUuPC Backup" `
            -RestorePointType "MODIFY_SETTINGS" `
            -ErrorAction Stop

        Write-Color "✅ Đã tạo điểm khôi phục hệ thống" $COLOR_SUCCESS
        Write-Log "System restore point created"
    }
    catch {
        Write-Color "⚠ Không tạo được điểm khôi phục" $COLOR_WARN
        Write-Log "Restore point failed: $_" "WARN"
    }
}

# ---------------- WINDOWS APPX ----------------
function Remove-WindowsStoreApp {
    param([string]$Pattern)

    try {
        Get-AppxPackage "*$Pattern*" -AllUsers |
            Remove-AppxPackage -AllUsers -ErrorAction Stop

        Write-Log "Removed Appx: $Pattern"
    }
    catch {
        Write-Log "Remove Appx failed $Pattern : $_" "WARN"
    }
}

# ---------------- CONFIRM DANGEROUS ----------------
function Confirm-DangerousAction {
    param([string]$Message)

    Write-Host ""
    Write-Color "⚠ CẢNH BÁO: $Message" $COLOR_DANGER
    $c = Read-Host "Nhập YES để tiếp tục"

    return ($c -eq "YES")
}
