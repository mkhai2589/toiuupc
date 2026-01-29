# utils.ps1 - Common helpers (fixed syntax for remote load)

$global:TEXT_COLOR     = "White"
$global:HEADER_COLOR   = "Cyan"
$global:SUCCESS_COLOR  = "Green"
$global:ERROR_COLOR    = "Red"
$global:BORDER_COLOR   = "DarkGray"
$global:WARNING_COLOR  = "Yellow"

function Reset-ConsoleStyle {
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = $TEXT_COLOR
    Clear-Host
}

function Show-SystemHeader {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId

    Write-Host "==================================================================================" -ForegroundColor $BORDER_COLOR
    Write-Host "PMK TOOLBOX v3.3.2" -ForegroundColor $HEADER_COLOR
    Write-Host "User: $($env:USERNAME) | PC: $($env:COMPUTERNAME) | OS: $($os.Caption) Build $build" -ForegroundColor $TEXT_COLOR
    Write-Host "CPU: $($cpu.Name.Split('@')[0].Trim()) | RAM: $ram GB" -ForegroundColor $TEXT_COLOR
    Write-Host "Author: Minh Khải (PMK) - https://www.facebook.com/khaiitcntt" -ForegroundColor $HEADER_COLOR
    Write-Host "==================================================================================" -ForegroundColor $BORDER_COLOR
    Write-Host ""
}

function Set-RegistryTweak {
    param (
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord",
        [switch]$CreatePath
    )
    try {
        if ($CreatePath -and -not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        Write-Verbose "Set $Path\$Name = $Value"
    } catch {
        Write-Warning "Failed to set ${Path}\${Name}: $($_.Exception.Message)"
    }
}

function Create-RestorePoint {
    try {
        Checkpoint-Computer -Description "PMK Toolbox Restore" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host "Đã tạo điểm khôi phục hệ thống" -ForegroundColor $SUCCESS_COLOR
    } catch {
        Write-Warning "Không tạo được điểm khôi phục: $($_.Exception.Message)"
    }
}

function Remove-WindowsApp {
    param([string]$Pattern)
    try {
        Get-AppxPackage "*$Pattern*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction Stop
        Write-Verbose "Removed apps matching $Pattern"
    } catch {
       Write-Warning "Failed to remove ${Pattern}: $($_.Exception.Message)"
    }
}