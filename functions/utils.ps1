Set-StrictMode -Version Latest

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Admin {
    if (-not (Test-IsAdmin)) {
        [System.Windows.MessageBox]::Show(
            "Vui long chay PowerShell bang quyen Administrator",
            "ToiUuPC",
            "OK",
            "Error"
        ) | Out-Null
        exit 1
    }
}

function New-RestorePoint {
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "ToiUuPC Restore Point" -RestorePointType "MODIFY_SETTINGS"
    } catch {
        # Neu service bi disable thi bo qua, KHONG stop tool
    }
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts][$Level] $Message"
}

function Set-Progress {
    param(
        $ProgressBar,
        [int]$Current,
        [int]$Total
    )

    if ($ProgressBar -and $Total -gt 0) {
        $ProgressBar.Value = [Math]::Round(($Current / $Total) * 100)
        [System.Windows.Forms.Application]::DoEvents()
    }
}
