# ==================================================
# utils.ps1 – CORE UTILITIES (FINAL)
# ==================================================

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ---------- COLORS ----------
$Global:COLOR_INFO  = "Cyan"
$Global:COLOR_OK    = "Green"
$Global:COLOR_WARN  = "Yellow"
$Global:COLOR_ERR   = "Red"

# ---------- LOG ----------
function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "HH:mm:ss"
    Write-Host "[$ts] $Message"
}

function Write-Step {
    param(
        [int]$Step,
        [string]$Text
    )
    Write-Host "`n[$Step] $Text" -ForegroundColor $Global:COLOR_INFO
}

function Write-OK {
    param([string]$Text)
    Write-Host "  -> $Text" -ForegroundColor $Global:COLOR_OK
}

function Write-Warn {
    param([string]$Text)
    Write-Host "  !  $Text" -ForegroundColor $Global:COLOR_WARN
}

function Write-Err {
    param([string]$Text)
    Write-Host "  X  $Text" -ForegroundColor $Global:COLOR_ERR
}

# ---------- PAUSE ----------
function Pause-Tool {
    Write-Host ""
    Read-Host "Press ENTER to continue"
}

# ---------- CONFIRM ----------
function Confirm-Action {
    param([string]$Message)
    $r = Read-Host "$Message (y/n)"
    return ($r -eq "y")
}

# ---------- ADMIN ----------
function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Err "Run PowerShell as Administrator"
        exit 1
    }
}
