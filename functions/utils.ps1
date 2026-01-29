# utils.ps1
# Core helpers

Set-StrictMode -Off

$Script:Root = Resolve-Path "$PSScriptRoot\.."
$Script:LogDir = Join-Path $Script:Root "runtime\logs"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

function Write-Log {
    param(
        [string]$Type,
        [string]$Message
    )

    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$time | $Type | $Message"

    $file = Join-Path $LogDir "$Type.log"
    $line | Out-File -FilePath $file -Append -Encoding UTF8
}

function Require-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "Please run PowerShell as Administrator"
        exit 1
    }
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "Config not found: $Path"
    }
    Get-Content $Path -Raw | ConvertFrom-Json
}
