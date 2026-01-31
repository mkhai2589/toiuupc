Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "    PMK TOOLBOX - BOOTSTRAP INSTALLER            " -ForegroundColor White
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

$tempDir = Join-Path $env:TEMP "ToiUuPC"
$projectUrl = "https://github.com/minhkhai179/toiuupc/archive/refs/heads/main.zip"

try {
    $adminTest = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $adminTest) {
        Write-Host "[ERROR] Vui long chay voi quyen Administrator!" -ForegroundColor Red
        Write-Host "Hay chuot phai vao file va chon 'Run as Administrator'" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Nhan Enter de thoat"
        exit 1
    }
    
    Write-Host "[INFO] Kiem tra ket noi Internet..." -ForegroundColor Cyan
    try {
        Test-NetConnection -ComputerName 8.8.8.8 -Port 53 -ErrorAction Stop | Out-Null
        Write-Host "[INFO] Ket noi Internet: OK" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Khong co ket noi Internet!" -ForegroundColor Yellow
        $choice = Read-Host "Nhap 'YES' de tiep tuc: "
        if ($choice -ne "YES") { exit 1 }
    }
    
    Write-Host "[INFO] Tao thu muc lam viec..." -ForegroundColor Cyan
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    Write-Host "[INFO] Tai du an tu GitHub..." -ForegroundColor Cyan
    $zipPath = Join-Path $tempDir "toiuupc.zip"
    
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $projectUrl -OutFile $zipPath -UseBasicParsing
    
    Write-Host "[INFO] Giai nen file..." -ForegroundColor Cyan
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempDir)
    
    $sourceDir = Get-ChildItem -Path $tempDir -Directory -Filter "toiuupc*" | Select-Object -First 1
    if ($sourceDir) {
        Get-ChildItem -Path $sourceDir.FullName | Move-Item -Destination $tempDir -Force
        Remove-Item $sourceDir.FullName -Recurse -Force
    }
    
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    
    Write-Host "[INFO] Khoi dong PMK Toolbox..." -ForegroundColor Green
    Write-Host ""
    
    $mainScript = Join-Path $tempDir "ToiUuPC.ps1"
    if (Test-Path $mainScript) {
        Set-Location $tempDir
        Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$mainScript`"" -Verb RunAs
    } else {
        Write-Host "[ERROR] Khong tim thay file chinh!" -ForegroundColor Red
        Read-Host "Nhan Enter de thoat"
    }
}
catch {
    Write-Host "[ERROR] Co loi xay ra: $_" -ForegroundColor Red
    Write-Host ""
    Read-Host "Nhan Enter de thoat"
    exit 1
}
