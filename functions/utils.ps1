# ==================================================
# utils.ps1
# Common helpers
# ==================================================

$Global:LogDir = Join-Path $PSScriptRoot "..\runtime\logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$Global:LogFile = Join-Path $LogDir ("run_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

function Write-Log {
    param([string]$Message)
    Add-Content -Path $LogFile -Value "[{0}] {1}" -f (Get-Date), $Message
}

function Step {
    param(
        [int]$Index,
        [string]$Text
    )
    Write-Host ("[{0}] {1}" -f $Index, $Text) -ForegroundColor Cyan
    Write-Log "$Index - $Text"
}

function Info {
    param([string]$Text)
    Write-Host "  $Text"
    Write-Log $Text
}

function Success {
    param([string]$Text)
    Write-Host "  OK: $Text" -ForegroundColor Green
    Write-Log "OK: $Text"
}

function Fail {
    param([string]$Text)
    Write-Host "  FAIL: $Text" -ForegroundColor Red
    Write-Log "FAIL: $Text"
}
