# ==================================================
# bootstrap.ps1 - BOOTSTRAP SCRIPT
# ==================================================

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

try {
    chcp 65001 | Out-Null
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "INFO" { "Cyan" }
        default { "White" }
    })
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Relaunch-AsAdmin {
    Write-Host "[!] Can quyen Administrator" -ForegroundColor Yellow
    $currentScript = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$currentScript`""
    exit 0
}

function Initialize-WorkingDirectory {
    param([string]$Path)
    
    try {
        Write-Log "Creating working directory: $Path" -Level "INFO"
        
        if (Test-Path $Path) {
            Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Removed old directory" -Level "INFO"
        }
        
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Log "Directory created successfully" -Level "INFO"
        return $true
    } catch {
        Write-Log "Failed to create directory" -Level "ERROR"
        return $false
    }
}

function Download-Project {
    param([string]$TargetDir)
    
    $tempZip = Join-Path $env:TEMP "toiuupc_temp.zip"
    $extractDir = Join-Path $env:TEMP "toiuupc_extract"
    
    try {
        Write-Log "Downloading project..." -Level "INFO"
        
        # Download từ GitHub
        $zipUrl = "https://github.com/mkhai2589/toiuupc/archive/refs/heads/main.zip"
        Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing
        
        Write-Log "Extracting files..." -Level "INFO"
        Expand-Archive -Path $tempZip -DestinationPath $extractDir -Force
        
        $mainExtractedDir = Get-ChildItem $extractDir -Directory -Filter "toiuupc*" | Select-Object -First 1
        
        if ($mainExtractedDir) {
            Write-Log "Found project directory: $($mainExtractedDir.FullName)" -Level "INFO"
            
            # Copy files
            Copy-Item "$($mainExtractedDir.FullName)\*" $TargetDir -Recurse -Force
            Write-Log "Files copied successfully" -Level "INFO"
            return $true
        }
        
        return $false
        
    } catch {
        Write-Log "Download error" -Level "ERROR"
        return $false
    } finally {
        if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
        if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
    }
}

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    PMK TOOLBOX - BOOTSTRAP             " -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Checking administrator rights..." -Level "INFO"
if (-not (Test-IsAdmin)) {
    Relaunch-AsAdmin
}

Write-Host "[INFO] Administrator: OK" -ForegroundColor Green

$BaseDir = Join-Path $env:TEMP "ToiUuPC"
$MainFile = Join-Path $BaseDir "ToiUuPC.ps1"

Write-Host "[INFO] Creating working directory: $BaseDir" -ForegroundColor Cyan
if (-not (Initialize-WorkingDirectory -Path $BaseDir)) {
    Write-Host "[ERROR] Failed to create directory!" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Downloading project..." -ForegroundColor Cyan
if (-not (Download-Project -TargetDir $BaseDir)) {
    Write-Host "[ERROR] Failed to download project!" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Project downloaded successfully" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "     LAUNCHING PMK TOOLBOX              " -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Set-Location $BaseDir

if (Test-Path $MainFile) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $MainFile
} else {
    Write-Host "[ERROR] Main file not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Bootstrap completed." -ForegroundColor Green
Read-Host "Press Enter to exit..."
