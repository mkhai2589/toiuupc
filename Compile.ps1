# =========================================================
# ToiUuPC – Compile Script
# Bundle PowerShell to EXE (WPF SAFE)
# Author: PMK
# =========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

Write-Host "ToiUuPC Compile Tool"

# =========================================================
# CHECK POWERSHELL VERSION
# =========================================================
if ($PSVersionTable.PSVersion.Major -ne 5) {
    Write-Host "ERROR: Please run this script using Windows PowerShell 5.1"
    Write-Host "PowerShell 7 is not supported for WPF compilation"
    exit 1
}

# =========================================================
# PATH DEFINITIONS
# =========================================================
$Root      = Split-Path -Parent $MyInvocation.MyCommand.Path
$MainFile  = Join-Path $Root "ToiUuPC.ps1"
$FuncDir   = Join-Path $Root "functions"
$UiDir     = Join-Path $Root "ui"

$BundledPS = Join-Path $Root "ToiUuPC-Bundled.ps1"
$OutputExe = Join-Path $Root "ToiUuPC.exe"

# =========================================================
# VALIDATION
# =========================================================
if (-not (Test-Path $MainFile)) {
    Write-Host "ERROR: Missing ToiUuPC.ps1"
    exit 1
}

if (-not (Test-Path $FuncDir)) {
    Write-Host "ERROR: Missing functions directory"
    exit 1
}

if (-not (Test-Path $UiDir)) {
    Write-Host "ERROR: Missing ui directory"
    exit 1
}

# =========================================================
# BUILD BUNDLED SCRIPT
# =========================================================
Write-Host "Bundling source files..."

$bundle = New-Object System.Collections.Generic.List[string]

$bundle.Add("# =========================================================")
$bundle.Add("# ToiUuPC – AUTO GENERATED BUNDLE")
$bundle.Add("# DO NOT EDIT MANUALLY")
$bundle.Add("# =========================================================")
$bundle.Add("")
$bundle.Add("Set-StrictMode -Off")
$bundle.Add('$ErrorActionPreference = "Continue"')
$bundle.Add("")

# =========================================================
# EMBED FUNCTIONS
# =========================================================
$bundle.Add("# ================= FUNCTIONS =================")

Get-ChildItem $FuncDir -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
    Write-Host " + functions\$($_.Name)"
    $bundle.Add("")
    $bundle.Add("# ----- BEGIN $($_.Name) -----")
    $bundle.Add((Get-Content $_ -Raw))
    $bundle.Add("# ----- END $($_.Name) -----")
}

# =========================================================
# EMBED XAML FILES
# =========================================================
$bundle.Add("")
$bundle.Add("# ================= UI FILES =================")

Get-ChildItem $UiDir -Filter "*.xaml" | Sort-Object Name | ForEach-Object {
    Write-Host " + ui\$($_.Name)"
    $varName = "UI_" + ($_.Name -replace '\.', '_')
    $content = (Get-Content $_ -Raw) -replace "@","@@"
    $bundle.Add("")
    $bundle.Add("`$Global:$varName = @'")
    $bundle.Add($content)
    $bundle.Add("'@")
}

# =========================================================
# MAIN SCRIPT
# =========================================================
$bundle.Add("")
$bundle.Add("# ================= MAIN SCRIPT =================")
$bundle.Add((Get-Content $MainFile -Raw))

# =========================================================
# WRITE BUNDLE FILE
# =========================================================
Set-Content -Path $BundledPS -Value $bundle -Encoding UTF8
Write-Host "Bundled script created: ToiUuPC-Bundled.ps1"

# =========================================================
# ENSURE PS2EXE
# =========================================================
if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "Installing ps2exe module..."
    Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber
}

Import-Module ps2exe -ErrorAction Stop

# =========================================================
# COMPILE TO EXE
# =========================================================
Write-Host "Compiling EXE..."

Invoke-ps2exe `
    -InputFile $BundledPS `
    -OutputFile $OutputExe `
    -RequireAdmin `
    -NoConsole:$false `
    -Title "ToiUuPC - Windows Optimizer" `
    -Description "Windows optimization and monitoring toolkit" `
    -Company "PMK" `
    -Product "ToiUuPC"

# =========================================================
# DONE
# =========================================================
if (Test-Path $OutputExe) {
    Write-Host "BUILD SUCCESS"
    Write-Host $OutputExe
} else {
    Write-Host "BUILD FAILED"
}
