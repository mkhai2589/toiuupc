# =========================================
# ToiUuPC - Complete Fixed Version
# All-in-one script, no external dependencies
# =========================================

# UTF-8 Fix
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ---------- ADMIN CHECK ----------
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "❌ Run PowerShell as Administrator" -ForegroundColor Red
    Write-Host "   Right-click PowerShell -> Run as Administrator" -ForegroundColor Yellow
    pause
    exit 1
}

# ---------- GITHUB REPO ----------
$RepoRaw = "https://raw.githubusercontent.com/mkhai2589/toiuupc/main"

# ---------- PATH ----------
$ROOT = Join-Path $env:TEMP "ToiUuPC"
$FUNC = Join-Path $ROOT "functions"
$CFG  = Join-Path $ROOT "config"
$RUN  = Join-Path $ROOT "runtime"
$BK   = Join-Path $RUN  "backup"

# Create directories
foreach ($dir in @($ROOT, $FUNC, $CFG, $RUN, $BK)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# =========================================
# CORE FUNCTIONS (Embedded in this file)
# =========================================

# ---------- LOGGING ----------
function Write-ToiUuPCLog {
    param([string]$Message, [string]$Level = "INFO")
    
    $logFile = Join-Path $RUN "toiuupc.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Out-File $logFile -Append -Encoding UTF8
}

# ---------- DOWNLOAD HELPER ----------
function Download-File {
    param(
        [string]$Url,
        [string]$OutFile
    )
    
    Write-Host "  Downloading: $(Split-Path $Url -Leaf)" -ForegroundColor DarkGray
    Write-ToiUuPCLog "Download attempt: $Url -> $OutFile"
    
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
        Write-ToiUuPCLog "Download success: $Url"
        return $true
    } catch {
        Write-Host "  ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-ToiUuPCLog "Download failed: $Url - $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ---------- RESTORE POINT ----------
function New-RestorePoint {
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "ToiUuPC Restore Point" -RestorePointType "MODIFY_SETTINGS"
        Write-Host "  ✅ Created system restore point" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  ⚠ Could not create restore point (service may be disabled)" -ForegroundColor Yellow
        return $false
    }
}

# ---------- TWEAKS ENGINE ----------
function Invoke-SystemTweaks {
    param(
        [object]$Config,
        [string[]]$SelectedIds,
        [string]$BackupPath
    )
    
    Write-Host "`n🔧 Applying tweaks..." -ForegroundColor Cyan
    Write-ToiUuPCLog "Invoke-SystemTweaks START - IDs: $($SelectedIds -join ',')"
    
    $applyList = $Config.tweaks | Where-Object { $_.id -in $SelectedIds }
    
    if ($applyList.Count -eq 0) {
        Write-Host "  No tweaks selected" -ForegroundColor Yellow
        return
    }
    
    foreach ($t in $applyList) {
        Write-Host "  Applying: $($t.name)" -ForegroundColor Cyan
        
        switch ($t.type) {
            "registry" {
                # Create registry path if it doesn't exist
                if (-not (Test-Path $t.path)) {
                    New-Item -Path $t.path -Force | Out-Null
                }
                
                # Apply registry change
                Set-ItemProperty -Path $t.path -Name $t.nameReg -Value $t.value -Type $t.regType
                Write-ToiUuPCLog "Applied registry: $($t.path)\$($t.nameReg) = $($t.value)"
            }
            
            "service" {
                $svc = Get-Service -Name $t.serviceName -ErrorAction SilentlyContinue
                if ($svc) {
                    Set-Service -Name $t.serviceName -StartupType $t.startup
                    Stop-Service -Name $t.serviceName -Force -ErrorAction SilentlyContinue
                    Write-ToiUuPCLog "Modified service: $($t.serviceName) -> $($t.startup)"
                }
            }
            
            "service_multiple" {
                foreach ($s in $t.services) {
                    $svc = Get-Service -Name $s.name -ErrorAction SilentlyContinue
                    if ($svc) {
                        Set-Service -Name $s.name -StartupType $s.startup
                        Stop-Service -Name $s.name -Force -ErrorAction SilentlyContinue
                    }
                }
            }
            
            "scheduled_task" {
                if ($t.taskName) {
                    Get-ScheduledTask -TaskName $t.taskName -ErrorAction SilentlyContinue |
                        Disable-ScheduledTask
                }
                if ($t.tasks) {
                    foreach ($name in $t.tasks) {
                        Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue |
                            Disable-ScheduledTask
                    }
                }
            }
        }
    }
    
    Write-Host "  ✅ Applied $($applyList.Count) tweaks" -ForegroundColor Green
    Write-ToiUuPCLog "Invoke-SystemTweaks END - Applied: $($applyList.Count)"
}

function Undo-SystemTweaks {
    param([string]$BackupPath)
    
    Write-Host "`n↩ Undoing tweaks..." -ForegroundColor Yellow
    Write-ToiUuPCLog "Undo-SystemTweaks START"
    
    if (-not (Test-Path $BackupPath)) {
        Write-Host "  No backup found" -ForegroundColor Red
        return
    }
    
    Write-Host "  Backup found in: $BackupPath" -ForegroundColor Cyan
    Write-Host "  Note: Manual undo not implemented in this version" -ForegroundColor Yellow
    Write-ToiUuPCLog "Undo-SystemTweaks - Manual undo required"
}

# ---------- APPS INSTALL ENGINE ----------
function Invoke-AppInstaller {
    param(
        [object]$Config,
        [string[]]$SelectedIds
    )
    
    Write-Host "`n📦 Installing applications..." -ForegroundColor Cyan
    Write-ToiUuPCLog "Invoke-AppInstaller START - IDs: $($SelectedIds -join ',')"
    
    # Check if winget is available
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "  ❌ Winget not found!" -ForegroundColor Red
        Write-Host "  Requires Windows 10 1809+ or Windows 11" -ForegroundColor Yellow
        Write-ToiUuPCLog "Winget not found" "ERROR"
        return
    }
    
    $apps = $Config.applications | Where-Object { $_.id -in $SelectedIds }
    
    if ($apps.Count -eq 0) {
        Write-Host "  No applications selected" -ForegroundColor Yellow
        return
    }
    
    $successCount = 0
    $failCount = 0
    
    foreach ($app in $apps) {
        Write-Host "  Installing: $($app.name)" -ForegroundColor Cyan
        
        $args = @(
            "install",
            "--id", $app.packageId,
            "-e",
            "--source", $app.source
        )
        
        if ($app.silent) {
            $args += "--silent"
            $args += "--accept-package-agreements"
            $args += "--accept-source-agreements"
        }
        
        try {
            $process = Start-Process winget -ArgumentList $args -Wait -NoNewWindow -PassThru -ErrorAction Stop
            
            if ($process.ExitCode -eq 0) {
                Write-Host "    ✅ Success" -ForegroundColor Green
                $successCount++
                Write-ToiUuPCLog "App installed: $($app.name) ($($app.packageId))"
            } else {
                Write-Host "    ⚠ Exit code: $($process.ExitCode)" -ForegroundColor Yellow
                $failCount++
                Write-ToiUuPCLog "App install failed: $($app.name) - Exit code: $($process.ExitCode)" "WARN"
            }
        } catch {
            Write-Host "    ❌ Error: $_" -ForegroundColor Red
            $failCount++
            Write-ToiUuPCLog "App install error: $($app.name) - $_" "ERROR"
        }
    }
    
    Write-Host "`n  📊 Results: $successCount successful, $failCount failed" -ForegroundColor Cyan
    Write-ToiUuPCLog "Invoke-AppInstaller END - Success: $successCount, Failed: $failCount"
}

# ---------- CLEAN ENGINE ----------
function Invoke-CleanSystem {
    param([string]$Mode = "All")
    
    Write-Host "`n🧹 Cleaning system..." -ForegroundColor Cyan
    Write-ToiUuPCLog "Invoke-CleanSystem START - Mode: $Mode"
    
    # Temp files
    if ($Mode -eq "All" -or $Mode -eq "Temp") {
        Write-Host "  Cleaning temp files..." -ForegroundColor DarkGray
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-ToiUuPCLog "Cleaned temp files"
    }
    
    # Browser cache
    if ($Mode -eq "All" -or $Mode -eq "Browser") {
        Write-Host "  Cleaning browser cache..." -ForegroundColor DarkGray
        Remove-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-ToiUuPCLog "Cleaned browser cache"
    }
    
    # Recycle Bin
    if ($Mode -eq "All" -or $Mode -eq "Recycle") {
        Write-Host "  Clearing recycle bin..." -ForegroundColor DarkGray
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-ToiUuPCLog "Cleared recycle bin"
    }
    
    Write-Host "  ✅ System cleaned" -ForegroundColor Green
    Write-ToiUuPCLog "Invoke-CleanSystem END"
}

# ---------- SIMPLE DNS FUNCTIONS ----------
function Set-DnsProfile {
    param([string]$ProfileName)
    
    Write-Host "`n🌐 Setting DNS: $ProfileName" -ForegroundColor Cyan
    Write-ToiUuPCLog "Set-DnsProfile: $ProfileName"
    
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    if ($adapters.Count -eq 0) {
        Write-Host "  ❌ No active network adapters found" -ForegroundColor Red
        return
    }
    
    foreach ($adapter in $adapters) {
        Write-Host "  Configuring: $($adapter.Name)" -ForegroundColor DarkGray
        
        if ($ProfileName -eq "google") {
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses 8.8.8.8,8.8.4.4
        } elseif ($ProfileName -eq "cloudflare") {
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses 1.1.1.1,1.0.0.1
        }
    }
    
    Write-Host "  ✅ Applied $ProfileName DNS" -ForegroundColor Green
}

function Reset-DnsProfile {
    Write-Host "`n🌐 Resetting DNS to DHCP..." -ForegroundColor Cyan
    Write-ToiUuPCLog "Reset-DnsProfile"
    
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    foreach ($adapter in $adapters) {
        Write-Host "  Resetting: $($adapter.Name)" -ForegroundColor DarkGray
        Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ResetServerAddresses
    }
    
    Write-Host "  ✅ DNS reset to DHCP" -ForegroundColor Green
}

# ---------- SELECTION HELPER ----------
function Select-Multi {
    param($Items, [string]$Title)
    
    if (-not $Items -or $Items.Count -eq 0) {
        Write-Host "  No items available" -ForegroundColor Red
        return @()
    }
    
    Clear-Host
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host ""
    
    $map = @{}
    $i = 1
    foreach ($it in $Items) {
        $displayName = $it.name
        if ($displayName.Length -gt 50) {
            $displayName = $displayName.Substring(0, 47) + "..."
        }
        Write-Host "$i. $displayName"
        $map[$i] = $it.id
        $i++
    }
    
    Write-Host ""
    Write-Host "0. Back to main menu"
    Write-Host ""
    $raw = Read-Host "Enter numbers (e.g., 1,3,5 or 1-5)"
    
    if ($raw -eq "0") { 
        return @() 
    }
    
    $selected = @()
    
    # Support both comma and range (e.g., "1,3,5" or "1-5")
    if ($raw -match '^\d+-\d+$') {
        # Range selection (e.g., 1-5)
        $range = $raw -split '-'
        $start = [int]$range[0]
        $end = [int]$range[1]
        
        for ($i = $start; $i -le $end; $i++) {
            if ($map[$i]) {
                $selected += $map[$i]
            }
        }
    } else {
        # Comma-separated selection
        $raw -split ',' | ForEach-Object {
            $num = $_.Trim()
            if ($num -match '^\d+$' -and $map[[int]$num]) {
                $selected += $map[[int]$num]
            }
        }
    }
    
    return $selected
}

# =========================================
# DOWNLOAD AND SETUP
# =========================================

Write-Host "`n🚀 ToiUuPC - Windows Optimization Tool" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor DarkGray
Write-ToiUuPCLog "ToiUuPC START"

# ---------- DOWNLOAD FILES ----------
Write-Host "`n📥 Downloading required files..." -ForegroundColor Cyan

# Download function files
$functions = @(
    "utils.ps1",
    "Show-PMKLogo.ps1", 
    "tweaks.ps1",
    "install-apps.ps1",
    "clean-system.ps1"
)

$functionSuccess = 0
foreach ($f in $functions) {
    $outPath = Join-Path $FUNC $f
    if (Download-File "$RepoRaw/functions/$f" $outPath) {
        $functionSuccess++
        
        # Fix Show-PMKLogo.ps1 immediately after download
        if ($f -eq "Show-PMKLogo.ps1") {
            $content = Get-Content $outPath -Raw
            if (-not ($content -match '\$HEADER_COLOR')) {
                $fixedContent = "`$HEADER_COLOR = 'Cyan'`n`n$content"
                Set-Content $outPath $fixedContent -Encoding UTF8
            }
        }
    }
}

# Download config files
$configs = @("tweaks.json", "applications.json", "dns.json")
$configSuccess = 0
foreach ($c in $configs) {
    $outPath = Join-Path $CFG $c
    if (Download-File "$RepoRaw/config/$c" $outPath) {
        $configSuccess++
    }
}

# Check download results
if ($functionSuccess -eq 0) {
    Write-Host "`n❌ Failed to download function files" -ForegroundColor Red
    Write-Host "   Check internet connection" -ForegroundColor Yellow
    Write-ToiUuPCLog "Download failed - no function files" "ERROR"
    pause
    exit 1
}

if ($configSuccess -eq 0) {
    Write-Host "`n⚠ Some config files failed to download" -ForegroundColor Yellow
    Write-Host "   Some features may not work" -ForegroundColor Yellow
}

Write-Host "`n✅ Downloaded $functionSuccess functions, $configSuccess configs" -ForegroundColor Green

# ---------- LOAD CONFIGURATIONS ----------
$TweaksJson = $null
$AppsJson = $null
$DnsJson = $null

try {
    if (Test-Path "$CFG\tweaks.json") {
        $TweaksJson = Get-Content "$CFG\tweaks.json" -Raw | ConvertFrom-Json
        Write-ToiUuPCLog "Loaded tweaks.json - $($TweaksJson.tweaks.Count) tweaks"
    }
} catch { 
    Write-Host "❌ Error loading tweaks.json" -ForegroundColor Red 
    Write-ToiUuPCLog "Error loading tweaks.json" "ERROR"
}

try {
    if (Test-Path "$CFG\applications.json") {
        $AppsJson = Get-Content "$CFG\applications.json" -Raw | ConvertFrom-Json
        Write-ToiUuPCLog "Loaded applications.json - $($AppsJson.applications.Count) apps"
    }
} catch { 
    Write-Host "❌ Error loading applications.json" -ForegroundColor Red 
    Write-ToiUuPCLog "Error loading applications.json" "ERROR"
}

try {
    if (Test-Path "$CFG\dns.json") {
        $DnsJson = Get-Content "$CFG\dns.json" -Raw | ConvertFrom-Json
        Write-ToiUuPCLog "Loaded dns.json"
    }
} catch { 
    Write-Host "⚠ Error loading dns.json (using built-in DNS)" -ForegroundColor Yellow 
}

# =========================================
# MAIN MENU
# =========================================

function Show-MainMenu {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║             TOI UU PC v1.0                  ║" -ForegroundColor Cyan
    Write-Host "║      Windows Optimization Toolkit           ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════╣" -ForegroundColor DarkGray
    
    # Show status
    $tweakCount = if ($TweaksJson -and $TweaksJson.tweaks) { $TweaksJson.tweaks.Count } else { 0 }
    $appCount = if ($AppsJson -and $AppsJson.applications) { $AppsJson.applications.Count } else { 0 }
    
    Write-Host "║ Tweaks: $tweakCount available" -ForegroundColor White
    Write-Host "║ Apps: $appCount available" -ForegroundColor White
    Write-Host "║ Logs: $RUN\toiuupc.log" -ForegroundColor DarkGray
    Write-Host "╠══════════════════════════════════════════════╣" -ForegroundColor DarkGray
    
    # Menu options
    Write-Host "║ 1. Apply Windows tweaks" -ForegroundColor White
    Write-Host "║ 2. Undo tweaks (restore)" -ForegroundColor White
    Write-Host "║ 3. Install applications" -ForegroundColor White
    Write-Host "║ 4. Configure DNS" -ForegroundColor White
    Write-Host "║ 5. Clean system" -ForegroundColor White
    Write-Host "║" -ForegroundColor DarkGray
    Write-Host "║ 0. Exit" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# =========================================
# MAIN LOOP
# =========================================

Write-ToiUuPCLog "Entering main menu loop"

do {
    Show-MainMenu
    $choice = Read-Host "Select option (0-5)"
    
    switch ($choice) {
        "1" {  # Apply tweaks
            if ($TweaksJson -and $TweaksJson.tweaks) {
                $selected = Select-Multi $TweaksJson.tweaks "SELECT TWEAKS TO APPLY"
                
                if ($selected.Count -gt 0) {
                    Write-Host "`nSelected $($selected.Count) tweaks" -ForegroundColor Cyan
                    
                    # Ask about restore point
                    Write-Host "`nCreate system restore point before applying?" -ForegroundColor Yellow
                    $createRestore = Read-Host "(Y/N, default: Y)"
                    
                    if ($createRestore -ne "N" -and $createRestore -ne "n") {
                        New-RestorePoint
                    }
                    
                    # Apply tweaks
                    Invoke-SystemTweaks `
                        -Config $TweaksJson `
                        -SelectedIds $selected `
                        -BackupPath $BK
                }
            } else {
                Write-Host "❌ No tweaks configuration available" -ForegroundColor Red
                Write-Host "   Check if tweaks.json downloaded correctly" -ForegroundColor Yellow
            }
            
            pause
        }
        
        "2" {  # Undo tweaks
            Undo-SystemTweaks -BackupPath $BK
            pause
        }
        
        "3" {  # Install apps
            if ($AppsJson -and $AppsJson.applications) {
                $selected = Select-Multi $AppsJson.applications "SELECT APPLICATIONS"
                
                if ($selected.Count -gt 0) {
                    Write-Host "`nSelected $($selected.Count) applications" -ForegroundColor Cyan
                    
                    # Confirm installation
                    Write-Host "`nProceed with installation?" -ForegroundColor Yellow
                    $confirm = Read-Host "(Y/N)"
                    
                    if ($confirm -eq "Y" -or $confirm -eq "y") {
                        Invoke-AppInstaller `
                            -Config $AppsJson `
                            -SelectedIds $selected
                    } else {
                        Write-Host "Installation cancelled" -ForegroundColor Yellow
                    }
                }
            } else {
                Write-Host "❌ No applications configuration available" -ForegroundColor Red
            }
            
            pause
        }
        
        "4" {  # Configure DNS
            Clear-Host
            Write-Host "=== DNS CONFIGURATION ===" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "1. Google DNS (8.8.8.8, 8.8.4.4)" -ForegroundColor White
            Write-Host "2. Cloudflare DNS (1.1.1.1, 1.0.0.1)" -ForegroundColor White
            Write-Host "3. Reset to DHCP (automatic)" -ForegroundColor White
            Write-Host ""
            Write-Host "0. Back to main menu" -ForegroundColor Yellow
            Write-Host ""
            
            $dnsChoice = Read-Host "Select DNS option"
            
            switch ($dnsChoice) {
                "1" { 
                    Set-DnsProfile "google"
                    pause
                }
                "2" { 
                    Set-DnsProfile "cloudflare"
                    pause
                }
                "3" { 
                    Reset-DnsProfile
                    pause
                }
                "0" { break }
                default { 
                    Write-Host "Invalid choice" -ForegroundColor Red
                    pause
                }
            }
        }
        
        "5" {  # Clean system
            Clear-Host
            Write-Host "=== CLEAN SYSTEM ===" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "1. Clean temporary files" -ForegroundColor White
            Write-Host "2. Clean browser cache" -ForegroundColor White
            Write-Host "3. Clean recycle bin" -ForegroundColor White
            Write-Host "4. Clean ALL (recommended)" -ForegroundColor White
            Write-Host ""
            Write-Host "0. Back to main menu" -ForegroundColor Yellow
            Write-Host ""
            
            $cleanChoice = Read-Host "Select cleaning option"
            
            switch ($cleanChoice) {
                "1" { 
                    Invoke-CleanSystem -Mode "Temp"
                    pause
                }
                "2" { 
                    Invoke-CleanSystem -Mode "Browser"
                    pause
                }
                "3" { 
                    Invoke-CleanSystem -Mode "Recycle"
                    pause
                }
                "4" { 
                    Invoke-CleanSystem -Mode "All"
                    pause
                }
                "0" { break }
                default { 
                    Write-Host "Invalid choice" -ForegroundColor Red
                    pause
                }
            }
        }
        
        "0" {  # Exit
            Write-Host "`n👋 Thank you for using ToiUuPC!" -ForegroundColor Green
            Write-Host "   Log file: $RUN\toiuupc.log" -ForegroundColor DarkGray
            Write-ToiUuPCLog "ToiUuPC EXIT"
            break
        }
        
        default {
            Write-Host "Invalid option. Please choose 0-5." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
    
} while ($choice -ne "0")
