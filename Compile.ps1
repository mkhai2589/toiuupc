# =========================================================
# ToiUuPC – Compile Script (ADVANCED – FREEZE JSON)
# Author: PMK
# =========================================================

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

Write-Host "ToiUuPC Compile Tool – ADVANCED (Freeze JSON)"

# =========================================================
# CHECK POWERSHELL VERSION
# =========================================================
if ($PSVersionTable.PSVersion.Major -ne 5) {
    Write-Host "ERROR: Please run using Windows PowerShell 5.1"
    exit 1
}

# =========================================================
# PATHS
# =========================================================
$Root      = Split-Path -Parent $MyInvocation.MyCommand.Path
$MainFile  = Join-Path $Root "ToiUuPC.ps1"
$FuncDir   = Join-Path $Root "functions"
$UiDir     = Join-Path $Root "ui"
$ConfigDir = Join-Path $Root "config"

$BundledPS = Join-Path $Root "ToiUuPC-Bundled.ps1"
$OutputExe = Join-Path $Root "ToiUuPC.exe"

# =========================================================
# VALIDATE
# =========================================================
$required = @(
    $MainFile,
    "$FuncDir",
    "$UiDir",
    "$ConfigDir\applications.json",
    "$ConfigDir\dns.json",
    "$ConfigDir\tweaks.json"
)

foreach ($r in $required) {
    if (-not (Test-Path $r)) {
        Write-Host "ERROR: Missing $r" -ForegroundColor Red
        exit 1
    }
}

# =========================================================
# BUILD BUNDLE
# =========================================================
Write-Host "Bundling source..."

$bundle = New-Object System.Collections.Generic.List[string]

$bundle.Add("# =========================================================")
$bundle.Add("# ToiUuPC – AUTO GENERATED BUNDLE (FREEZE JSON)")
$bundle.Add("# =========================================================")
$bundle.Add("")
$bundle.Add("Set-StrictMode -Off")
$bundle.Add('$ErrorActionPreference = "Continue"')
$bundle.Add("")

# =========================================================
# EMBED JSON
# =========================================================
Write-Host "Embedding JSON..."

function Embed-Json {
    param($Name, $Path)
    Write-Host " + config\$Name"
    $content = (Get-Content $Path -Raw) -replace "@","@@"
    $bundle.Add("")
    $bundle.Add("# ----- EMBED JSON: $Name -----")
    $bundle.Add("`$Global:JSON_$($Name.Replace('.','_')) = @'")
    $bundle.Add($content)
    $bundle.Add("'@")
}

Embed-Json "applications.json" "$ConfigDir\applications.json"
Embed-Json "dns.json"          "$ConfigDir\dns.json"
Embed-Json "tweaks.json"       "$ConfigDir\tweaks.json"

# =========================================================
# EMBED FUNCTIONS
# =========================================================
$bundle.Add("")
$bundle.Add("# ================= FUNCTIONS =================")

Get-ChildItem $FuncDir -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
    Write-Host " + functions\$($_.Name)"
    $bundle.Add("")
    $bundle.Add("# ----- BEGIN $($_.Name) -----")
    $bundle.Add((Get-Content $_ -Raw))
    $bundle.Add("# ----- END $($_.Name) -----")
}

# =========================================================
# EMBED UI
# =========================================================
$bundle.Add("")
$bundle.Add("# ================= UI FILES =================")

Get-ChildItem $UiDir -Filter "*.xaml" | Sort-Object Name | ForEach-Object {
    Write-Host " + ui\$($_.Name)"
    $var = "UI_" + ($_.Name -replace '\.','_')
    $xaml = (Get-Content $_ -Raw) -replace "@","@@"
    $bundle.Add("")
    $bundle.Add("`$Global:$var = @'")
    $bundle.Add($xaml)
    $bundle.Add("'@")
}

# =========================================================
# MAIN
# =========================================================
$bundle.Add("")
$bundle.Add("# ================= MAIN SCRIPT =================")
$bundle.Add((Get-Content $MainFile -Raw))

# =========================================================
# WRITE FILE
# =========================================================
Set-Content $BundledPS $bundle -Encoding UTF8
Write-Host "Bundled script created."

# =========================================================
# COMPILE
# =========================================================
if (-not (Get-Module -ListAvailable ps2exe)) {
    Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber
}

Import-Module ps2exe

Invoke-ps2exe `
    -InputFile $BundledPS `
    -OutputFile $OutputExe `
    -RequireAdmin `
    -NoConsole:$false `
    -Title "ToiUuPC" `
    -Company "PMK" `
    -Product "ToiUuPC"

Write-Host "DONE"
