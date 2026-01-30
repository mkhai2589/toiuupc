# =====================================================
# utils.ps1
# PMK TOOLBOX – Core Utilities
# Author: Minh Khai
# =====================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# =====================================================
# GLOBAL PATHS
# =====================================================
$Global:ToiUuPC_Root   = Join-Path $env:TEMP "ToiUuPC"
$Global:RuntimeDir    = Join-Path $Global:ToiUuPC_Root "runtime"
$Global:LogDir        = Join-Path $Global:RuntimeDir "logs"
$Global:BackupDir     = Join-Path $Global:RuntimeDir "backups"

$Global:LogFile_Main  = Join-Path $Global:LogDir "toiuupc.log"
$Global:LogFile_Tweak = Join-Path $Global:LogDir "tweaks.log"
$Global:LogFile_App   = Join-Path $Global:LogDir "apps.log"

# =====================================================
# INITIALIZE ENVIRONMENT
# =====================================================
function Initialize-ToiUuPCEnvironment {

    foreach ($dir in @(
        $Global:ToiUuPC_Root,
        $Global:RuntimeDir,
        $Global:LogDir,
        $Global:BackupDir
    )) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    foreach ($file in @(
        $Global:LogFile_Main,
        $Global:LogFile_Tweak,
        $Global:LogFile_App
    )) {
        if (-not (Test-Path $file)) {
            New-Item -ItemType File -Path $file -Force | Out-Null
        }
    }
}

# =====================================================
# ADMIN CHECK
# =====================================================
function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p  = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Ensure-Admin {
    if (-not (Test-IsAdmin)) {
        Write-Host "ERROR: Please run PowerShell as Administrator." -ForegroundColor Red
        exit 1
    }
}

# =====================================================
# LOGGING
# =====================================================
function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level = "INFO",
        [ValidateSet("MAIN","TWEAK","APP")]
        [string]$Channel = "MAIN"
    )

    Initialize-ToiUuPCEnvironment

    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    switch ($Channel) {
        "TWEAK" { $file = $Global:LogFile_Tweak }
        "APP"   { $file = $Global:LogFile_App }
        default { $file = $Global:LogFile_Main }
    }

    "$ts [$Level] $Message" |
        Out-File -FilePath $file -Append -Encoding UTF8
}

# =====================================================
# SYSTEM INFO (HEADER)
# =====================================================
function Get-SystemHeaderInfo {

    $user     = $env:USERNAME
    $computer = $env:COMPUTERNAME

    $os = Get-CimInstance Win32_OperatingSystem
    $osName = $os.Caption.Trim()
    $osVer  = $os.Version

    $isAdmin = if (Test-IsAdmin) { "YES" } else { "NO" }

    $netOk = try {
        Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction Stop
    } catch { $false }

    $netStatus = if ($netOk) { "OK" } else { "NO" }

    $tz = (Get-TimeZone).BaseUtcOffset.TotalHours
    if ($tz -ge 0) {
        $tzText = "UTC+$tz"
    } else {
        $tzText = "UTC$tz"
    }

    return [PSCustomObject]@{
        User       = $user
        Computer  = $computer
        OS        = "$osName ($osVer)"
        Net       = $netStatus
        Admin     = $isAdmin
        TimeZone  = $tzText
    }
}

# =====================================================
# HEADER RENDER
# =====================================================
function Show-Header {

    $info = Get-SystemHeaderInfo

    $line = "+======================================================================+"
    Write-Host $line -ForegroundColor DarkGray
    Write-Host ("| USER: {0,-10} | PC: {1,-12} | OS: {2,-22} | ADMIN: {3,-3} | {4,-7} |" -f `
        $info.User,
        $info.Computer,
        $info.OS.Substring(0,[Math]::Min(22,$info.OS.Length)),
        $info.Admin,
        $info.TimeZone
    ) -ForegroundColor Gray
    Write-Host $line -ForegroundColor DarkGray
    Write-Host ""
}

# =====================================================
# JSON LOADER
# =====================================================
function Load-JsonFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Host "ERROR: Missing config file: $Path" -ForegroundColor Red
        return $null
    }

    try {
        return Get-Content $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Write-Host "ERROR: Invalid JSON: $Path" -ForegroundColor Red
        return $null
    }
}

# =====================================================
# MENU HELPERS
# =====================================================
function Pause {
    Write-Host ""
    Read-Host "Press ENTER to continue"
}

function Read-Choice {
    param([string]$Prompt = "Select option")

    Write-Host ""
    return Read-Host $Prompt
}

# =====================================================
# SAFE CLEAR
# =====================================================
function Clear-Screen {
    Clear-Host
    Show-Header
}

# =====================================================
# BOOTSTRAP CALL
# =====================================================
Initialize-ToiUuPCEnvironment
