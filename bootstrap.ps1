# ==================================================
# bootstrap.ps1 – FINAL
# ==================================================

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

$Repo = "https://github.com/mkhai2589/toiuupc"
$Zip  = "$Repo/archive/refs/heads/main.zip"
$Dir  = Join-Path $env:TEMP "ToiUuPC"

if (-not (Test-Path $Dir)) {
    New-Item -ItemType Directory -Path $Dir | Out-Null
}

$zipFile = "$env:TEMP\toiuupc.zip"
Invoke-WebRequest $Zip -OutFile $zipFile -UseBasicParsing
Expand-Archive $zipFile "$env:TEMP\toiuupc_tmp" -Force
Copy-Item "$env:TEMP\toiuupc_tmp\*\*" $Dir -Recurse -Force

powershell.exe -ExecutionPolicy Bypass -File "$Dir\ToiUuPC.ps1"
