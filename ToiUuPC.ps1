# ==================================================
# ToiUuPC.ps1 - FINAL INTEGRATED & FIXED VERSION
# ==================================================

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ==================================================
# RESOLVE SCRIPT ROOT (IRM | IEX SAFE)
# ==================================================
if ($PSScriptRoot -and (Test-Path $PSScriptRoot)) {
    $ROOT = $PSScriptRoot
}
elseif ($MyInvocation.MyCommand.Path) {
    $ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
}
else {
    $ROOT = Get-Location
}

Set-Location $ROOT

# ==================================================
# PROJECT PATHS
# ==================================================
$FUNC = Join-Path $ROOT "functions"
$CFG  = Join-Path $ROOT "config"
$UI   = Join-Path $ROOT "ui"
$LOG  = Join-Path $ROOT "runtime\logs"

# ==================================================
# VALIDATE CORE STRUCTURE
# ==================================================
foreach ($p in @($FUNC, $CFG, $UI)) {
    if (-not (Test-Path $p)) {
        Write-Host "Missing required folder: $p" -ForegroundColor Red
        return
    }
}

# ==================================================
# LOAD FUNCTIONS (ORDER MATTERS)
# ==================================================
$functionOrder = @(
    "utils.ps1",
    "Show-PMKLogo.ps1",
    "tweaks.ps1",
    "install-apps.ps1",
    "dns-management.ps1",
    "clean-system.ps1",
    "dashboard-engine.ps1"
)

foreach ($file in $functionOrder) {
    $path = Join-Path $FUNC $file
    if (Test-Path $path) {
        . $path
    }
    else {
        Write-Host "Missing function file: $file" -ForegroundColor Red
        return
    }
}

# ==================================================
# INIT ENV + ADMIN
# ==================================================
Initialize-ToiUuPCEnvironment
Ensure-Admin

# ==================================================
# DASHBOARD (SAFE – NON BLOCKING – NO PARSE ERROR)
# ==================================================
function Show-Dashboard {

    try {
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName PresentationCore
        Add-Type -AssemblyName WindowsBase
    } catch {
        Write-Host "WPF not available" -ForegroundColor Red
        return
    }

    $xamlPath = Join-Path $UI "Dashboard.xaml"
    if (-not (Test-Path $xamlPath)) {
        Write-Host "Dashboard.xaml not found" -ForegroundColor Red
        return
    }

    [xml]$xaml = Get-Content $xamlPath -Raw
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $Window = [Windows.Markup.XamlReader]::Load($reader)

    # ===== Bind =====
    $CpuRing  = $Window.FindName("CpuRing")
    $CpuText  = $Window.FindName("CpuText")
    $CpuBar   = $Window.FindName("CpuBar")
    $RamBar   = $Window.FindName("RamBar")
    $RamText  = $Window.FindName("RamText")
    $DiskBar  = $Window.FindName("DiskBar")
    $DiskText = $Window.FindName("DiskText")
    $DiskWarn = $Window.FindName("DiskWarn")

    # ===== CPU Counter =====
    $cpuCounter = New-Object Diagnostics.PerformanceCounter(
        "Processor", "% Processor Time", "_Total"
    )
    $null = $cpuCounter.NextValue()

    function Set-BarColor($bar, [int]$p) {
        if ($p -ge 80) { $bar.Foreground = "Red" }
        elseif ($p -ge 60) { $bar.Foreground = "Gold" }
        else { $bar.Foreground = "LimeGreen" }
    }

    # ===== CPU Ring =====
    $cx = 65; $cy = 65; $r = 55
    $arc = New-Object Windows.Media.ArcSegment
    $arc.Size = New-Object Windows.Size($r, $r)
    $arc.SweepDirection = "Clockwise"

    $fig = New-Object Windows.Media.PathFigure
    $fig.StartPoint = New-Object Windows.Point($cx, $cy - $r)
    $fig.Segments.Add($arc)

    $geo = New-Object Windows.Media.PathGeometry
    $geo.Figures.Add($fig)
    $CpuRing.Data = $geo

    function Update-CpuRing([int]$p) {
        $angle = ($p / 100) * 360
        $rad = ($angle - 90) * [Math]::PI / 180
        $arc.Point = New-Object Windows.Point(
            $cx + $r * [Math]::Cos($rad),
            $cy + $r * [Math]::Sin($rad)
        )
        $arc.IsLargeArc = ($angle -gt 180)
    }

    # ===== TIMER (SAFE) =====
    $timer = New-Object Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)

    $timer.Add_Tick({
        try {
            # CPU
            $cpu = [Math]::Round($cpuCounter.NextValue(), 0)
            $CpuText.Text = "$cpu%"
            $CpuBar.Value = $cpu
            Set-BarColor $CpuBar $cpu
            Update-CpuRing $cpu

            # RAM
            $os = Get-CimInstance Win32_OperatingSystem
            $ramPercent = [Math]::Round(
                (
                    ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) /
                    $os.TotalVisibleMemorySize
                ) * 100, 0
            )
            $RamBar.Value = $ramPercent
            $RamText.Text = "$ramPercent%"
            Set-BarColor $RamBar $ramPercent

            # DISK
            $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
            $diskPercent = [Math]::Round(
                (($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 0
            )
            $DiskBar.Value = $diskPercent
            $DiskText.Text = "$diskPercent% used"
            Set-BarColor $DiskBar $diskPercent
            $DiskWarn.Visibility = if ($diskPercent -ge 85) { "Visible" } else { "Collapsed" }
        } catch {
            # ignore runtime dashboard errors
        }
    })

    $Window.Add_Closed({ $timer.Stop() })
    $timer.Start()

    # NON-BLOCKING
    $Window.Show() | Out-Null
}

# ==================================================
# MAIN MENU
# ==================================================
function Show-MainMenu {
    Clear-Host
    Show-PMKLogo
    Write-Host ""
    Write-Host "1. Apply Windows Tweaks"
    Write-Host "2. Install Applications"
    Write-Host "3. DNS Management"
    Write-Host "4. Clean System"
    Write-Host "5. Create Restore Point"
    Write-Host "6. Performance Dashboard"
    Write-Host "0. Exit"
    Write-Host ""
}

# ==================================================
# MAIN LOOP
# ==================================================
while ($true) {

    Show-MainMenu
    $c = Read-Host "Chon"

    switch ($c) {

        "1" {
            $p = Join-Path $CFG "tweaks.json"
            if (Test-Path $p) {
                Invoke-TweaksMenu (Get-Content $p -Raw | ConvertFrom-Json)
            }
            pause
        }

        "2" {
            $p = Join-Path $CFG "applications.json"
            if (Test-Path $p) {
                Invoke-AppMenu (Get-Content $p -Raw | ConvertFrom-Json)
            }
            pause
        }

        "3" {
            $p = Join-Path $CFG "dns.json"
            if (Test-Path $p) {
                Invoke-DnsMenu -ConfigPath $p
            }
            pause
        }

        "4" {
            Invoke-CleanMenu
            pause
        }

        "5" {
            New-RestorePoint
            pause
        }

        "6" {
            Show-Dashboard
        }

        "0" {
            break
        }
    }
}
