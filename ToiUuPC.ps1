# =========================================
# ToiUuPC - Controller (FIXED VERSION)
# =========================================

# UTF-8 Fix
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

# ---------- ADMIN ----------
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "❌ Run PowerShell as Administrator" -ForegroundColor Red
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

# Tạo thư mục
foreach ($dir in @($ROOT, $FUNC, $CFG, $RUN, $BK)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# ---------- DOWNLOAD FILES ----------
function Download-File {
    param($Url, $OutFile)
    
    Write-Host "⬇ $(Split-Path $Url -Leaf)" -ForegroundColor DarkGray
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
        return $true
    } catch {
        Write-Host "  ❌ Failed to download" -ForegroundColor Red
        return $false
    }
}

Write-Host "`n🔄 Downloading ToiUuPC files..." -ForegroundColor Cyan

# Download function files
$functions = @(
    "utils.ps1",
    "Show-PMKLogo.ps1", 
    "tweaks.ps1",
    "install-apps.ps1",
    # "dns-management.ps1"  # BỎ QUA vì bị lỗi
    "clean-system.ps1"
)

$functionSuccess = 0
foreach ($f in $functions) {
    $outPath = Join-Path $FUNC $f
    if (Download-File "$RepoRaw/functions/$f" $outPath) {
        $functionSuccess++
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

# Check if downloads were successful
if ($functionSuccess -eq 0 -or $configSuccess -eq 0) {
    Write-Host "`n❌ Failed to download required files" -ForegroundColor Red
    Write-Host "Check internet connection and try again" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "`n✅ Downloaded: $functionSuccess functions, $configSuccess configs" -ForegroundColor Green

# ---------- FIX SHOW-PMKLogo.ps1 ----------
$logoFile = Join-Path $FUNC "Show-PMKLogo.ps1"
if (Test-Path $logoFile) {
    $content = Get-Content $logoFile -Raw
    if (-not ($content -match '\$HEADER_COLOR')) {
        $fixedContent = "`$HEADER_COLOR = 'Cyan'`n`n$content"
        Set-Content $logoFile $fixedContent -Encoding UTF8
        Write-Host "✓ Fixed Show-PMKLogo.ps1" -ForegroundColor Green
    }
}

# ---------- LOAD FUNCTIONS ----------
Write-Host "`n📦 Loading modules..." -ForegroundColor Cyan

$loadedFunctions = 0
foreach ($file in (Get-ChildItem $FUNC -Filter "*.ps1")) {
    if ($file.Name -eq "dns-management.ps1") {
        Write-Host "  ⚠ Skipping $($file.Name) (known issues)" -ForegroundColor Yellow
        continue
    }
    
    try {
        . $file.FullName
        Write-Host "  ✓ $($file.Name)" -ForegroundColor DarkGray
        $loadedFunctions++
    } catch {
        Write-Host "  ❌ Error loading $($file.Name)" -ForegroundColor Red
    }
}

if ($loadedFunctions -eq 0) {
    Write-Host "`n❌ No functions loaded successfully" -ForegroundColor Red
    pause
    exit 1
}

# ---------- LOAD JSON ----------
$TweaksJson = $null
$AppsJson = $null
$DnsJson = $null

try {
    if (Test-Path "$CFG\tweaks.json") {
        $TweaksJson = Get-Content "$CFG\tweaks.json" -Raw | ConvertFrom-Json
        Write-Host "✓ Loaded tweaks.json" -ForegroundColor DarkGray
    }
} catch { Write-Host "❌ Error loading tweaks.json" -ForegroundColor Red }

try {
    if (Test-Path "$CFG\applications.json") {
        $AppsJson = Get-Content "$CFG\applications.json" -Raw | ConvertFrom-Json
        Write-Host "✓ Loaded applications.json" -ForegroundColor DarkGray
    }
} catch { Write-Host "❌ Error loading applications.json" -ForegroundColor Red }

try {
    if (Test-Path "$CFG\dns.json") {
        $DnsJson = Get-Content "$CFG\dns.json" -Raw | ConvertFrom-Json
        Write-Host "✓ Loaded dns.json" -ForegroundColor DarkGray
    }
} catch { Write-Host "❌ Error loading dns.json" -ForegroundColor Red }

# ---------- SIMPLE DNS FUNCTION ----------
function Set-DnsProfile {
    param([string]$ProfileName)
    
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    foreach ($adapter in $adapters) {
        if ($ProfileName -eq "google") {
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses 8.8.8.8,8.8.4.4
        } elseif ($ProfileName -eq "cloudflare") {
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses 1.1.1.1,1.0.0.1
        }
    }
    
    Write-Host "✅ Applied $ProfileName DNS" -ForegroundColor Green
}

function Reset-DnsProfile {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    foreach ($adapter in $adapters) {
        Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ResetServerAddresses
    }
    
    Write-Host "✅ Reset DNS to DHCP" -ForegroundColor Green
}

# ---------- HELPERS ----------
function Select-Multi {
    param($Items, [string]$Title)
    
    if (-not $Items) {
        Write-Host "No items available" -ForegroundColor Red
        return @()
    }
    
    Clear-Host
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    
    $map = @{}
    $i = 1
    foreach ($it in $Items) {
        Write-Host "$i. $($it.name)"
        $map[$i] = $it.id
        $i++
    }
    
    Write-Host "0. Back"
    Write-Host ""
    $raw = Read-Host "Enter numbers (e.g., 1,3,5)"
    
    if ($raw -eq "0") { return @() }
    
    $selected = @()
    $raw -split "," | ForEach-Object {
        $num = $_.Trim()
        if ($num -match '^\d+$' -and $map[[int]$num]) {
            $selected += $map[[int]$num]
        }
    }
    
    return $selected
}

# ---------- MENU ----------
function Show-Menu {
    Clear-Host
    Write-Host "=========== TOI UU PC ===========" -ForegroundColor Cyan
    Write-Host "1. Windows tweaks"
    Write-Host "2. Undo tweaks"
    Write-Host "3. Install apps"
    Write-Host "4. DNS"
    Write-Host "5. Clean system"
    Write-Host "0. Exit"
    Write-Host "================================"
}

# ---------- MAIN ----------
do {
    Show-Menu
    $choice = Read-Host "`nSelect option"
    
    switch ($choice) {
        "1" {
            if ($TweaksJson -and $TweaksJson.tweaks) {
                $selected = Select-Multi $TweaksJson.tweaks "SELECT TWEAKS"
                if ($selected.Count -gt 0) {
                    if (Get-Command Invoke-SystemTweaks -ErrorAction SilentlyContinue) {
                        Invoke-SystemTweaks `
                            -Config $TweaksJson `
                            -SelectedIds $selected `
                            -BackupPath $BK
                    } else {
                        Write-Host "Tweaks function not available" -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "No tweaks configuration loaded" -ForegroundColor Red
            }
        }
        
        "2" {
            if (Get-Command Undo-SystemTweaks -ErrorAction SilentlyContinue) {
                Undo-SystemTweaks -BackupPath $BK
            } else {
                Write-Host "Undo function not available" -ForegroundColor Red
            }
        }
        
        "3" {
            if ($AppsJson -and $AppsJson.applications) {
                $selected = Select-Multi $AppsJson.applications "SELECT APPS"
                if ($selected.Count -gt 0) {
                    if (Get-Command Invoke-AppInstaller -ErrorAction SilentlyContinue) {
                        Invoke-AppInstaller `
                            -Config $AppsJson `
                            -SelectedIds $selected
                    } else {
                        Write-Host "Apps function not available" -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "No apps configuration loaded" -ForegroundColor Red
            }
        }
        
        "4" {
            Write-Host "`n=== DNS OPTIONS ===" -ForegroundColor Cyan
            Write-Host "1. Google DNS (8.8.8.8)"
            Write-Host "2. Cloudflare DNS (1.1.1.1)"
            Write-Host "3. Reset to DHCP"
            Write-Host "0. Back"
            
            $dnsChoice = Read-Host "`nSelect DNS option"
            
            switch ($dnsChoice) {
                "1" { Set-DnsProfile "google" }
                "2" { Set-DnsProfile "cloudflare" }
                "3" { Reset-DnsProfile }
                "0" { break }
                default { Write-Host "Invalid choice" -ForegroundColor Red }
            }
        }
        
        "5" {
            if (Get-Command Invoke-CleanSystem -ErrorAction SilentlyContinue) {
                Invoke-CleanSystem -Mode "All"
            } else {
                Write-Host "Clean function not available" -ForegroundColor Red
            }
        }
        
        "0" { 
            Write-Host "`n👋 Goodbye!" -ForegroundColor Green
            break 
        }
        
        default { 
            Write-Host "Invalid choice" -ForegroundColor Red 
        }
    }
    
    if ($choice -ne "0") { 
        Write-Host "`nPress any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
} while ($choice -ne "0")
