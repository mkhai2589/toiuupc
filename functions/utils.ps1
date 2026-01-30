# =====================================================
# utils.ps1
# PMK TOOLBOX – Core Utilities (FINAL)
# Author: Minh Khai
# Compatible: Windows 10 / Windows 11 (PowerShell 5.1)
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
# UI CONFIG (FIXED WIDTH + COLOR RULE)
# =====================================================
$Global:UI = @{
    Width   = 70
    Border  = 'DarkGray'
    Header  = 'Gray'
    Title   = 'Cyan'
    Menu    = 'Gray'
    Active  = 'Green'
    Warn    = 'Yellow'
    Error   = 'Red'
    Value   = 'Green'
}

# =====================================================
# INITIALIZE ENVIRONMENT
# =====================================================
function Initialize-ToiUuPCEnvironment {

    chcp 65001 | Out-Null
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    try {
        $size = $Host.UI.RawUI.WindowSize
        if ($size.Width -lt $Global:UI.Width) {
            $size.Width = $Global:UI.Width
            $Host.UI.RawUI.WindowSize = $size
        }
    } catch {}

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
# NETWORK CHECK
# =====================================================
function Test-Network {
    try {
        Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction Stop
    } catch {
        return $false
    }
}

# =====================================================
# SYSTEM INFO (USED BY HEADER)
# =====================================================
function Get-SystemInfo {

    $os  = Get-CimInstance Win32_OperatingSystem
    $ver = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

    return @{
        User     = $env:USERNAME
        Computer = $env:COMPUTERNAME
        OS       = $os.Caption.Trim()
        Version  = $ver.DisplayVersion
        Build    = $os.BuildNumber
        Admin    = if (Test-IsAdmin) { "YES" } else { "NO" }
        Net      = if (Test-Network) { "OK" } else { "OFF" }
        Time     = (Get-Date).ToString("HH:mm:ss")
    }
}

# =====================================================
# HEADER RENDER (FIXED WIDTH – NO SIDE EFFECT)
# =====================================================
function Show-Header {

    $i = Get-SystemInfo
    $w = $Global:UI.Width

    $line = "+" + ("=" * $w) + "+"

    Write-Host $line -ForegroundColor $Global:UI.Border

    $text = "USER: $($i.User) | PC: $($i.Computer) | OS: $($i.OS) $($i.Version) ($($i.Build)) | NET: $($i.Net) | ADMIN: $($i.Admin) | TIME: $($i.Time)"

    if ($text.Length -gt $w) {
        $text = $text.Substring(0, $w)
    }

    Write-Host ("|{0,-$w}|" -f $text) -ForegroundColor $Global:UI.Header
    Write-Host $line -ForegroundColor $Global:UI.Border
    Write-Host ""
}

# =====================================================
# SAFE CLEAR (HEADER AWARE)
# =====================================================
function Clear-Screen {
    Clear-Host
    Show-Header
}

# =====================================================
# JSON LOADER (USED BY ALL MODULES)
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
# INPUT / KEY / PAUSE
# =====================================================
function Pause {
    Write-Host ""
    Read-Host "Press ENTER to continue"
}

function Read-Key {
    return [Console]::ReadKey($true)
}

# =====================================================
# REGISTRY HELPER
# =====================================================
function Ensure-RegistryPath {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

# =====================================================
# BOOTSTRAP INIT
# =====================================================
Initialize-ToiUuPCEnvironment
