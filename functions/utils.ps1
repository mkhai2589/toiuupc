# utils.ps1 - Sửa lỗi load đỏ và bổ sung hàm cần thiết
Set-StrictMode -Off
# Đặt chế độ xử lý lỗi toàn cục: tiếp tục nhưng không hiển thị lỗi đỏ
$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'

# Các đường dẫn toàn cục
$Global:ToiUuPC_Root   = Join-Path $env:TEMP "ToiUuPC"
$Global:RuntimeDir    = Join-Path $Global:ToiUuPC_Root "runtime"
$Global:LogDir        = Join-Path $Global:RuntimeDir "logs"
$Global:BackupDir     = Join-Path $Global:RuntimeDir "backups"

$Global:LogFile_Main  = Join-Path $Global:LogDir "toiuupc.log"
$Global:LogFile_Tweak = Join-Path $Global:LogDir "tweaks.log"
$Global:LogFile_App   = Join-Path $Global:LogDir "apps.log"

# Hàm khởi tạo môi trường
function Initialize-ToiUuPCEnvironment {
    # Thiết lập encoding UTF-8
    chcp 65001 | Out-Null
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    # Tạo các thư mục cần thiết
    foreach ($dir in @($Global:ToiUuPC_Root, $Global:RuntimeDir, $Global:LogDir, $Global:BackupDir)) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
}

# Hàm kiểm tra quyền Admin
function Test-IsAdmin {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

# Hàm đảm bảo chạy với quyền Admin (nếu không thì thoát)
function Ensure-Admin {
    if (-not (Test-IsAdmin)) {
        Write-Host "Vui long chay PowerShell voi quyen Administrator!" -ForegroundColor Red
        Read-Host "Nhan Enter de thoat"
        exit 1
    }
}

# Hàm load JSON (có cache trong phiên)
function Load-JsonFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Host "ERROR: Missing config file: $Path" -ForegroundColor Red
        return $null
    }

    try {
        return Get-Content $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Write-Host "ERROR: Invalid JSON format in $Path" -ForegroundColor Red
        return $null
    }
}

# Khởi tạo môi trường
Initialize-ToiUuPCEnvironment
