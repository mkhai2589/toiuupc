$global:UI_Colors = @{
    Border      = 'DarkGray'
    Header      = 'Cyan'
    Title       = 'White'
    Menu        = 'Gray'
    Active      = 'Green'
    Success     = 'Green'
    Warning     = 'Yellow'
    Error       = 'Red'
    Info        = 'Cyan'
    Label       = 'DarkGray'
    Value       = 'White'
    Highlight   = 'Magenta'
    Dim         = 'DarkGray'
}

function Write-Status {
    param([string]$Message, [string]$Type = 'INFO')
    
    $color = switch ($Type) {
        'SUCCESS' { $global:UI_Colors.Success }
        'WARNING' { $global:UI_Colors.Warning }
        'ERROR'   { $global:UI_Colors.Error }
        default   { $global:UI_Colors.Info }
    }
    
    $prefix = switch ($Type) {
        'SUCCESS' { '[OK]' }
        'WARNING' { '[!]' }
        'ERROR'   { '[X]' }
        default   { '[...]' }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Get-SystemInfo {
    $info = @{}
    
    $info.User = $env:USERNAME
    $info.Computer = $env:COMPUTERNAME
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $info.OS = $os.Caption.Trim() -replace "Microsoft ", ""
        $info.Arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
        $info.Build = $os.BuildNumber
    } catch {
        $info.OS = "Windows"
        $info.Arch = "N/A"
        $info.Build = "N/A"
    }
    
    try {
        $adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
        $info.Network = if ($adapters) { "OK" } else { "NO" }
    } catch {
        $info.Network = "UNK"
    }
    
    $info.IsAdmin = if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { "YES" } else { "NO" }
    $info.LocalTime = Get-Date -Format "HH:mm:ss"
    $info.FullTime = "$($info.LocalTime) UTC+7"
    
    try {
        $cpu = Get-WmiObject Win32_Processor | Measure-Object LoadPercentage -Average
        $info.CPU = "$([math]::Round($cpu.Average))%"
    } catch {
        $info.CPU = "0%"
    }
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $ramUsed = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
        $ramPercent = [math]::Round(($ramUsed / $os.TotalVisibleMemorySize) * 100)
        $info.RAM = "$ramPercent%"
    } catch {
        $info.RAM = "0%"
    }
    
    try {
        $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
        if ($gpu -and $gpu.Name) {
            $gpuName = ($gpu.Name -split '\(R\)' | Select-Object -First 1).Trim()
            if ($gpuName.Length -gt 25) { $gpuName = $gpuName.Substring(0, 22) + "..." }
            $info.GPU = $gpuName
        } else {
            $info.GPU = "Integrated"
        }
    } catch {
        $info.GPU = "Unknown"
    }
    
    try {
        $driveC = Get-PSDrive C -ErrorAction SilentlyContinue
        if ($driveC) {
            $freeGB = [math]::Round($driveC.Free / 1GB, 1)
            $usedGB = [math]::Round($driveC.Used / 1GB, 1)
            $totalGB = $freeGB + $usedGB
            $percent = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100) } else { 0 }
            $info.DiskC = "$usedGB/$totalGB GB ($percent%)"
        } else {
            $info.DiskC = "N/A"
        }
    } catch {
        $info.DiskC = "Error"
    }
    
    return $info
}

function Show-Header {
    param([string]$Title = "PMK TOOLBOX")
    
    Clear-Host
    
    $info = Get-SystemInfo
    
    Write-Host "+======================================================================+" -ForegroundColor Cyan
    Write-Host "| USER: $($info.User.PadRight(8)) | OS: $($info.OS.PadRight(15)) | NET: $($info.Network.PadRight(3)) | ADMIN: $($info.IsAdmin.PadRight(3)) | TIME: $($info.FullTime.PadRight(13)) |" -ForegroundColor Cyan
    Write-Host "+======================================================================+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " PMK TOOLBOX - Toi Uu Windows" -ForegroundColor White
    Write-Host " Tac gia: MINH KHAI - 0333090930" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Menu {
    param([array]$Items, [string]$Title, [switch]$TwoColumn = $false)
    
    Show-Header -Title $Title
    
    Write-Host $Title.ToUpper() -ForegroundColor White
    Write-Host ("-" * 70) -ForegroundColor DarkGray
    Write-Host ""
    
    if ($TwoColumn) {
        $mid = [Math]::Ceiling($Items.Count / 2)
        for ($i = 0; $i -lt $mid; $i++) {
            $left = $Items[$i]
            $right = if (($i + $mid) -lt $Items.Count) { $Items[$i + $mid] } else { $null }
            
            $leftText = "  [$($left.Key)] $($left.Text)"
            Write-Host $leftText.PadRight(40) -NoNewline -ForegroundColor Gray
            
            if ($right) {
                Write-Host "[$($right.Key)] $($right.Text)" -ForegroundColor Gray
            } else {
                Write-Host ""
            }
        }
    } else {
        foreach ($item in $Items) {
            Write-Host "  [$($item.Key)] $($item.Text)" -ForegroundColor Gray
            Write-Host ""
        }
    }
    
    Write-Host ""
    Write-Host "-" * 70 -ForegroundColor DarkGray
    Write-Host ""
}

function Pause {
    Write-Host ""
    Write-Host "Nhan Enter de tiep tuc..." -ForegroundColor Yellow -NoNewline
    $null = Read-Host
}

function Load-JsonConfig {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Status "Khong tim thay file: $(Split-Path $Path -Leaf)" -Type 'ERROR'
        return $null
    }
    
    try {
        return Get-Content $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Write-Status "Loi doc file JSON: $(Split-Path $Path -Leaf)" -Type 'ERROR'
        return $null
    }
}
