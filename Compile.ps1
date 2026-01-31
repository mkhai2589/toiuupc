# =========================================================
# Compile.ps1 - COMPILE SCRIPT
# =========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     TOIUUPC COMPILE TOOL               " -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "[ERROR] Can PowerShell 5.1 tro len!" -ForegroundColor Red
    exit 1
}

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Paths = @{
    MainFile    = Join-Path $Root "ToiUuPC.ps1"
    FuncDir     = Join-Path $Root "functions"
    ConfigDir   = Join-Path $Root "config"
    OutputExe   = Join-Path $Root "ToiUuPC.exe"
    TempBundled = Join-Path $env:TEMP "ToiUuPC-Bundled.ps1"
}

Write-Host "[+] Kiem tra file can thiet..." -ForegroundColor Cyan

$required = @(
    $Paths.MainFile,
    $Paths.FuncDir,
    (Join-Path $Paths.ConfigDir "applications.json"),
    (Join-Path $Paths.ConfigDir "dns.json"),
    (Join-Path $Paths.ConfigDir "tweaks.json")
)

foreach ($r in $required) {
    if (Test-Path $r) {
        Write-Host "  [OK] $(Split-Path $r -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $(Split-Path $r -Leaf)" -ForegroundColor Red
        exit 1
    }
}

Write-Host "[+] Tao bundle script..." -ForegroundColor Cyan

$bundleContent = @"
# ========================================================
# TOIUUPC - AUTO GENERATED BUNDLE
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# ========================================================

Set-StrictMode -Off
`$ErrorActionPreference = "SilentlyContinue"

"@

function Add-JsonToBundle {
    param($Name, $Path)
    
    Write-Host "  Embedding: config\$Name" -ForegroundColor Gray
    
    try {
        $content = Get-Content $Path -Raw
        $varName = "JSON_$($Name.Replace('.','_'))"
        
        $bundleContent += @"

# === $Name ===
`$$varName = @'
$content
'@

"@
        return $true
    } catch {
        Write-Host "  [ERROR] embedding $Name" -ForegroundColor Red
        return $false
    }
}

Add-JsonToBundle -Name "applications.json" -Path (Join-Path $Paths.ConfigDir "applications.json")
Add-JsonToBundle -Name "dns.json" -Path (Join-Path $Paths.ConfigDir "dns.json")
Add-JsonToBundle -Name "tweaks.json" -Path (Join-Path $Paths.ConfigDir "tweaks.json")

Write-Host "[+] Embedding functions..." -ForegroundColor Cyan

Get-ChildItem $Paths.FuncDir -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
    Write-Host "  Embedding: functions\$($_.Name)" -ForegroundColor Gray
    
    try {
        $funcContent = Get-Content $_ -Raw
        $bundleContent += @"

# --- BEGIN $($_.Name) ---
$funcContent
# --- END $($_.Name) ---

"@
    } catch {
        Write-Host "  [ERROR] embedding $($_.Name)" -ForegroundColor Red
    }
}

Write-Host "[+] Embedding main script..." -ForegroundColor Cyan

try {
    $mainContent = Get-Content $Paths.MainFile -Raw
    $bundleContent += @"

# ========================================================
# MAIN SCRIPT
# ========================================================

$mainContent

"@
} catch {
    Write-Host "  [ERROR] embedding main script" -ForegroundColor Red
    exit 1
}

try {
    Set-Content -Path $Paths.TempBundled -Value $bundleContent -Encoding UTF8 -Force
    Write-Host "  [OK] Bundle created" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] writing bundle" -ForegroundColor Red
    exit 1
}

Write-Host "[+] Bien dich sang EXE..." -ForegroundColor Cyan

try {
    if (Get-Module -ListAvailable -Name ps2exe) {
        Import-Module ps2exe -Force
    } else {
        Write-Host "  Cai dat module ps2exe..." -ForegroundColor Yellow
        Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber
        Import-Module ps2exe -Force
    }
    
    Invoke-ps2exe -InputFile $Paths.TempBundled -OutputFile $Paths.OutputExe `
        -RequireAdmin -Title "PMK Toolbox" -Description "Toi Uu Windows" `
        -Product "PMK Toolbox" -Version "2.0.0"
    
    Write-Host "  [OK] Bien dich thanh cong!" -ForegroundColor Green
    
} catch {
    Write-Host "  [ERROR] bien dich" -ForegroundColor Red
    exit 1
}

if (Test-Path $Paths.TempBundled) {
    Remove-Item $Paths.TempBundled -Force
}

if (Test-Path $Paths.OutputExe) {
    $exeInfo = Get-Item $Paths.OutputExe
    $exeSize = [math]::Round($exeInfo.Length / 1MB, 2)
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "     BIEN DICH HOAN TAT!               " -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host " File da tao:" -ForegroundColor Cyan
    Write-Host "   $($Paths.OutputExe)" -ForegroundColor Gray
    Write-Host "   Kich thuoc: $exeSize MB" -ForegroundColor Gray
    Write-Host ""
}
