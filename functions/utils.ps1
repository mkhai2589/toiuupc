function Show-SystemHeader {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId

    Write-Host "==================================================================================" -ForegroundColor $BORDER_COLOR
    Write-Host "PMK TOOLBOX v3.3.2" -ForegroundColor $HEADER_COLOR
    Write-Host "User: $($env:USERNAME) | PC: $($env:COMPUTERNAME) | OS: $($os.Caption) Build $build" -ForegroundColor $TEXT_COLOR
    Write-Host "CPU: $($cpu.Name.Split('@')[0].Trim()) | RAM: $ram GB" -ForegroundColor $TEXT_COLOR
    Write-Host "Author: Minh Khải (PMK) - https://www.facebook.com/khaiitcntt" -ForegroundColor $HEADER_COLOR
    Write-Host "==================================================================================" -ForegroundColor $BORDER_COLOR
    Write-Host ""
}

