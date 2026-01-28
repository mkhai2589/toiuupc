# Compile.ps1 - Build monolithic ToiUuPC-OneFile.ps1 cho remote run

$OutputFile = "ToiUuPC-OneFile.ps1"

# Xóa file cũ nếu có
if (Test-Path $OutputFile) { Remove-Item $OutputFile }

# Header
@'
# ToiUuPC - PMK Toolbox v3.0 (Bundled One-File)
# Generated from modular sources
Clear-Host
'@ | Out-File $OutputFile -Encoding utf8

# Ghép logo & utils
Get-Content "functions\Show-PMKLogo.ps1" -ErrorAction SilentlyContinue | Add-Content $OutputFile
Get-Content "functions\utils.ps1" -ErrorAction SilentlyContinue | Add-Content $OutputFile
Get-Content "functions\install-apps.ps1" -ErrorAction SilentlyContinue | Add-Content $OutputFile
Get-Content "functions\dns-management.ps1" -ErrorAction SilentlyContinue | Add-Content $OutputFile
Get-Content "functions\tweaks.ps1" -ErrorAction SilentlyContinue | Add-Content $OutputFile

# Ghép phần chính (loại bỏ dot-sourcing)
Get-Content "ToiUuPC.ps1" | Where-Object { $_ -notmatch '^\.' } | Add-Content $OutputFile

Write-Host "Build hoàn tất: $OutputFile" -ForegroundColor Green
Write-Host "Upload file này lên GitHub Releases hoặc dùng cho one-liner." -ForegroundColor Cyan
