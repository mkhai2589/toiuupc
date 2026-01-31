# =========================================================
# Compile.ps1 - COMPILE SCRIPT (FIXED FINAL)
# =========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# =========================================================
# HEADER
# =========================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     TOIUUPC COMPILE TOOL               " -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Author: Minh Khai"
Write-Host "Purpose: Bundle and compile to EXE"
Write-Host ""

# =========================================================
# CHECK REQUIREMENTS
# =========================================================
Write-Host "[+] Kiem tra yeu cau..." -ForegroundColor Cyan

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "[ERROR] Can PowerShell 5.1 tro len!" -ForegroundColor Red
    Write-Host "  Hien tai: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    exit 1
}

Write-Host "   => PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Green

# =========================================================
# PATHS CONFIGURATION (UPDATED - NO BUNDLED FILE)
# =========================================================
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

$Paths = @{
    MainFile    = Join-Path $Root "ToiUuPC.ps1"
    FuncDir     = Join-Path $Root "functions"
    ConfigDir   = Join-Path $Root "config"
    OutputExe   = Join-Path $Root "ToiUuPC.exe"
    TempBundled = Join-Path $env:TEMP "ToiUuPC-Bundled_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"
}

Write-Host "[+] Thiet lap duong dan..." -ForegroundColor Cyan
foreach ($key in $Paths.Keys) {
    Write-Host "   => $key : $($Paths[$key])" -ForegroundColor Gray
}

# =========================================================
# VALIDATE REQUIRED FILES
# =========================================================
Write-Host "[+] Kiem tra file can thiet..." -ForegroundColor Cyan

$required = @(
    $Paths.MainFile,
    $Paths.FuncDir,
    (Join-Path $Paths.ConfigDir "applications.json"),
    (Join-Path $Paths.ConfigDir "dns.json"),
    (Join-Path $Paths.ConfigDir "tweaks.json")
)

$allFilesExist = $true
foreach ($r in $required) {
    if (Test-Path $r) {
        Write-Host "   => OK: $r" -ForegroundColor Green
    } else {
        Write-Host "   => MISSING: $r" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    Write-Host "[ERROR] Thieu file can thiet!" -ForegroundColor Red
    exit 1
}

# =========================================================
# BUILD BUNDLE
# =========================================================
Write-Host "[+] Tao bundle script..." -ForegroundColor Cyan

$bundleContent = New-Object System.Collections.Generic.List[string]

# Add header
$bundleContent.Add("# " + ("=" * 56))
$bundleContent.Add("# TOIUUPC - AUTO GENERATED BUNDLE")
$bundleContent.Add("# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$bundleContent.Add("# " + ("=" * 56))
$bundleContent.Add("")
$bundleContent.Add('Set-StrictMode -Off')
$bundleContent.Add('$ErrorActionPreference = "SilentlyContinue"')
$bundleContent.Add('$WarningPreference = "SilentlyContinue"')
$bundleContent.Add("")

# Embed JSON configurations
function Add-JsonToBundle {
    param($Name, $Path)
    
    Write-Host "   => Embedding: config\$Name" -ForegroundColor Gray
    
    try {
        $content = Get-Content $Path -Raw -Encoding UTF8
        $varName = "JSON_$($Name.Replace('.','_'))"
        
        $bundleContent.Add("")
        $bundleContent.Add("# === $Name ===")
        $bundleContent.Add("`$$varName = @'")
        $bundleContent.Add($content.Trim())
        $bundleContent.Add("'@")
        $bundleContent.Add("")
    } catch {
        Write-Host "   => ERROR embedding $Name: $_" -ForegroundColor Red
        return $false
    }
    
    return $true
}

Add-JsonToBundle -Name "applications.json" -Path (Join-Path $Paths.ConfigDir "applications.json")
Add-JsonToBundle -Name "dns.json" -Path (Join-Path $Paths.ConfigDir "dns.json")
Add-JsonToBundle -Name "tweaks.json" -Path (Join-Path $Paths.ConfigDir "tweaks.json")

# Embed all PowerShell functions
Write-Host "[+] Embedding functions..." -ForegroundColor Cyan

$bundleContent.Add("# " + ("=" * 56))
$bundleContent.Add("# FUNCTIONS")
$bundleContent.Add("# " + ("=" * 56))
$bundleContent.Add("")

Get-ChildItem $Paths.FuncDir -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
    Write-Host "   => Embedding: functions\$($_.Name)" -ForegroundColor Gray
    
    try {
        $funcContent = Get-Content $_ -Raw -Encoding UTF8
        $bundleContent.Add("")
        $bundleContent.Add("# --- BEGIN $($_.Name) ---")
        $bundleContent.Add($funcContent)
        $bundleContent.Add("# --- END $($_.Name) ---")
        $bundleContent.Add("")
    } catch {
        Write-Host "   => ERROR embedding $($_.Name)" -ForegroundColor Red
    }
}

# Embed main script
Write-Host "[+] Embedding main script..." -ForegroundColor Cyan

$bundleContent.Add("# " + ("=" * 56))
$bundleContent.Add("# MAIN SCRIPT")
$bundleContent.Add("# " + ("=" * 56))
$bundleContent.Add("")

try {
    $mainContent = Get-Content $Paths.MainFile -Raw -Encoding UTF8
    $bundleContent.Add($mainContent)
    Write-Host "   => Embedded main script" -ForegroundColor Green
} catch {
    Write-Host "   => ERROR embedding main script" -ForegroundColor Red
    exit 1
}

# Write bundled file to TEMP
Write-Host "[+] Ghi bundle file tam thoi..." -ForegroundColor Cyan

try {
    Set-Content -Path $Paths.TempBundled -Value $bundleContent -Encoding UTF8 -Force
    Write-Host "   => Bundle created: $($Paths.TempBundled)" -ForegroundColor Green
    Write-Host "   => Kich thuoc: $((Get-Item $Paths.TempBundled).Length / 1KB) KB" -ForegroundColor Gray
} catch {
    Write-Host "   => ERROR writing bundle: $_" -ForegroundColor Red
    exit 1
}

# =========================================================
# COMPILE TO EXE
# =========================================================
Write-Host "[+] Bien dich sang EXE..." -ForegroundColor Cyan

# Check if ps2exe module is available
$ps2exeModule = Get-Module -ListAvailable | Where-Object { $_.Name -eq "ps2exe" }

if (-not $ps2exeModule) {
    Write-Host "   => Cai dat module ps2exe..." -ForegroundColor Yellow
    
    try {
        Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        Write-Host "   => Cai dat thanh cong!" -ForegroundColor Green
    } catch {
        Write-Host "   => ERROR cai dat ps2exe: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Co the cai dat thu cong:" -ForegroundColor Yellow
        Write-Host "1. Mo PowerShell voi quyen Administrator" -ForegroundColor Gray
        Write-Host "2. Chay: Install-Module ps2exe -Force" -ForegroundColor Gray
        exit 1
    }
}

# Import module
try {
    Import-Module ps2exe -Force -ErrorAction Stop
    Write-Host "   => Import module ps2exe thanh cong" -ForegroundColor Green
} catch {
    Write-Host "   => ERROR import ps2exe: $_" -ForegroundColor Red
    exit 1
}

# Compile with ps2exe
Write-Host "   => Dang bien dich (co the mat vai giay)..." -ForegroundColor Gray

$compileParams = @{
    InputFile     = $Paths.TempBundled
    OutputFile    = $Paths.OutputExe
    RequireAdmin  = $true
    NoConsole     = $false
    Title         = "ToiUuPC"
    Description   = "PMK Toolbox - Toi Uu Windows"
    Company       = "PMK"
    Product       = "ToiUuPC"
    Version       = "1.0.0"
    IconFile      = $null  # Add icon path if you have one
}

try {
    Invoke-ps2exe @compileParams -ErrorAction Stop
    Write-Host "   => Bien dich thanh cong!" -ForegroundColor Green
} catch {
    Write-Host "   => ERROR bien dich: $_" -ForegroundColor Red
    # Clean up temp file
    if (Test-Path $Paths.TempBundled) {
        Remove-Item $Paths.TempBundled -Force -ErrorAction SilentlyContinue
    }
    exit 1
}

# Clean up temp bundled file
if (Test-Path $Paths.TempBundled) {
    Remove-Item $Paths.TempBundled -Force -ErrorAction SilentlyContinue
    Write-Host "   => Da xoa file tam thoi" -ForegroundColor Gray
}

# =========================================================
# FINAL VERIFICATION
# =========================================================
Write-Host ""
Write-Host "[+] Kiem tra ket qua..." -ForegroundColor Cyan

if (Test-Path $Paths.OutputExe) {
    $exeInfo = Get-Item $Paths.OutputExe
    $exeSize = [math]::Round($exeInfo.Length / 1MB, 2)
    
    Write-Host "   => File EXE: $($Paths.OutputExe)" -ForegroundColor Green
    Write-Host "   => Kich thuoc: $exeSize MB" -ForegroundColor Green
    Write-Host "   => Ngay tao: $($exeInfo.CreationTime)" -ForegroundColor Gray
} else {
    Write-Host "   => ERROR: File EXE khong duoc tao!" -ForegroundColor Red
    exit 1
}

# =========================================================
# COMPLETION
# =========================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "     BIEN DICH HOAN TAT!               " -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Cac file da tao:" -ForegroundColor Cyan
Write-Host "  1. $($Paths.OutputExe)" -ForegroundColor Gray
Write-Host ""
Write-Host "Ban co the:" -ForegroundColor Cyan
Write-Host "  - Chay ToiUuPC.exe de su dung" -ForegroundColor Gray
Write-Host "  - Chay ToiUuPC.ps1 de phat trien" -ForegroundColor Gray
Write-Host "  - Chay bootstrap.ps1 de tai va cap nhat" -ForegroundColor Gray
Write-Host ""
Write-Host "Cam on ban da su dung ToiUuPC!" -ForegroundColor Green
