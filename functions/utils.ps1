function Test-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-RegistryTweak {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord",
        [switch]$CreatePath
    )
    # Giữ nguyên logic từ file cũ của bạn
    # ...
}

# Thêm các hàm khác: Remove-WindowsApp, Test-Winget, v.v.
