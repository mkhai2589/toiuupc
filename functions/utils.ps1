# =====================================================
# utils.ps1
# PMK TOOLBOX – Core Utilities (SIMPLE VERSION)
# Author: Minh Khai
# =====================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# =====================================================
# GLOBAL PATHS (Giữ nguyên để tương thích)
# =====================================================
$Global:ToiUuPC_Root   = Join-Path $env:TEMP "ToiUuPC"
$Global:RuntimeDir    = Join-Path $Global:ToiUuPC_Root "runtime"
$Global:LogDir        = Join-Path $Global:RuntimeDir "logs"
$Global:BackupDir     = Join-Path $Global:RuntimeDir "backups"

$Global:LogFile_Main  = Join-Path $Global:LogDir "toiuupc.log"
$Global:LogFile_Tweak = Join-Path $Global:LogDir "tweaks.log"
$Global:LogFile_App   = Join-Path $Global:LogDir "apps.log"

# =====================================================
# UI CONFIG (Có thể không dùng, nhưng giữ để tương thích)
# =====================================================
$Global:UI = @{
    Width   = 70
    Border  = 'DarkGray'
    Header  = 'Gray'
    Title   = 'Cyan'
    Menu    = 'Gray'
    Active  = 'Green'
    Warn    = 'Yellow'
    Error   = 'Red'
    Value   = 'Green'
}

# =====================================================
# INITIALIZE ENVIRONMENT (Đơn giản hóa)
# =====================================================
function Initialize-ToiUuPCEnvironment {
    chcp 65001 | Out-Null
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    # Tạo các thư mục nếu chưa có
    foreach ($dir in @($Global:ToiUuPC_Root, $Global:RuntimeDir, $Global:LogDir, $Global:BackupDir)) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
}

# =====================================================
# HÀM PAUSE (Dùng chung)
# =====================================================
function Pause {
    Write-Host ""
    Read-Host "Nhan Enter de tiep tuc"
}

# =====================================================
# HÀM ĐỌC JSON (Đơn giản, không cache)
# =====================================================
function Load-JsonFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Host "LOI: Khong tim thay file: $Path" -ForegroundColor Red
        return $null
    }

    try {
        $content = Get-Content $Path -Raw -Encoding UTF8
        return $content | ConvertFrom-Json
    } catch {
        Write-Host "LOI: Dinh dang JSON khong hop le trong file: $Path" -ForegroundColor Red
        return $null
    }
}

# =====================================================
# KIỂM TRA QUYỀN ADMIN
# =====================================================
function Test-IsAdmin {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Ensure-Admin {
    if (-not (Test-IsAdmin)) {
        Write-Host "LOI: Vui long chay chuong trinh voi quyen Administrator!" -ForegroundColor Red
        Pause
        exit 1
    }
}

# =====================================================
# KIỂM TRA MẠNG (Đơn giản hóa)
# =====================================================
function Test-Network {
    try {
        $result = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        return $result.TcpTestSucceeded
    } catch {
        return $false
    }
}

# =====================================================
# HÀM HIỂN THỊ LOGO (Nếu cần, có thể gọi từ Show-PMKLogo.ps1)
# =====================================================
function Show-PMKLogo {
    # Nếu file Show-PMKLogo.ps1 được load, hàm này có thể bị ghi đè.
    # Để tránh lỗi, ta định nghĩa một phiên bản mặc định.
    # Tuy nhiên, nên dùng file riêng.
    Write-Host "PMK TOOLBOX - TOI UU WINDOWS" -ForegroundColor Cyan
}

# =====================================================
# KHỞI TẠO MÔI TRƯỜNG
# =====================================================
Initialize-ToiUuPCEnvironment
