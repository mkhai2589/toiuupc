Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# =====================================================
# GLOBAL PATHS
# =====================================================
$Global:ToiUuPC_Root = Join-Path $env:TEMP "ToiUuPC"
$Global:RuntimeDir  = Join-Path $Global:ToiUuPC_Root "runtime"
$Global:LogDir      = Join-Path $Global:RuntimeDir "logs"
$Global:LogFile     = Join-Path $Global:LogDir "toiuupc.log"
$Global:BackupDir   = Join-Path $Global:RuntimeDir "backups"

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

    if (-not (Test-Path $Global:LogFile)) {
        New-Item -ItemType File -Path $Global:LogFile -Force | Out-Null
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
        try {
            Add-Type -AssemblyName PresentationFramework
            [System.Windows.MessageBox]::Show(
                "Vui long chay PowerShell bang quyen Administrator",
                "ToiUuPC",
                "OK",
                "Error"
            ) | Out-Null
        } catch {
            Write-Host "Vui long chay PowerShell bang quyen Administrator" -ForegroundColor Red
        }
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
        [string]$Level = "INFO"
    )

    Initialize-ToiUuPCEnvironment

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$timestamp [$Level] $Message"

    $line | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8

    switch ($Level) {
        "INFO"  { Write-Host $Message -ForegroundColor Gray }
        "WARN"  { Write-Host $Message -ForegroundColor Yellow }
        "ERROR" { Write-Host $Message -ForegroundColor Red }
    }
}


# =====================================================
# RESTORE POINT (SAFE)
# =====================================================
function New-RestorePoint {
    param(
        [string]$Description = "ToiUuPC Restore Point"
    )

    Write-Log "Creating restore point: $Description"

    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer `
            -Description $Description `
            -RestorePointType "MODIFY_SETTINGS" `
            -ErrorAction Stop
        Write-Log "Restore point created"
    } catch {
        Write-Log "Restore point skipped: $($_.Exception.Message)" "WARN"
    }
}

# =====================================================
# PROGRESS BAR (GUI SAFE)
# =====================================================
function Set-Progress {
    param(
        $ProgressBar,
        [int]$Current,
        [int]$Total
    )

    if (-not $ProgressBar) { return }
    if ($Total -le 0) { return }

    try {
        $ProgressBar.Value = [Math]::Min(
            100,
            [Math]::Round(($Current / $Total) * 100)
        )

        # GUI refresh
        if ([System.Windows.Forms.Application]::MessageLoop) {
            [System.Windows.Forms.Application]::DoEvents()
        }
    } catch {
        # ignore GUI errors
    }
}

# =====================================================
# SAFE EXECUTION WRAPPER
# =====================================================
function Invoke-Safe {
    param(
        [Parameter(Mandatory)][scriptblock]$Script,
        [string]$Name = "Task"
    )

    Write-Log "Start: $Name"

    try {
        & $Script
        Write-Log "Done: $Name"
    } catch {
        Write-Log "Failed: $Name | $($_.Exception.Message)" "ERROR"
    }
}
