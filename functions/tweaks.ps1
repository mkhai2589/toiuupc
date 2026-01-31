# ============================================================
# tweaks.ps1 - WINDOWS TWEAKS ENGINE (FINAL VERSION)
# ============================================================
# Author: Minh Khai
# Version: 2.0.0
# Description: Windows tweaks and optimizations
# ============================================================

Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# CORE TWEAK FUNCTIONS
# ============================================================

function Test-OSVersion {
    param([string]$min, [string]$max)
    
    $os = [System.Environment]::OSVersion.Version
    $current = "$($os.Major).$($os.Minor)"
    
    try {
        $currentVer = [version]$current
        $minVer = [version]$min
        $maxVer = [version]$max
        
        return ($currentVer -ge $minVer -and $currentVer -le $maxVer)
    } catch {
        return $false
    }
}

function Apply-RegistryTweak {
    param($t)
    
    try {
        # Tao registry path neu khong ton tai
        if (-not (Test-Path $t.path)) {
            New-Item -Path $t.path -Force | Out-Null
            Write-Status "Tao registry path: $($t.path)" -Type 'INFO'
        }
        
        # Dat gia tri registry
        Set-ItemProperty -Path $t.path -Name $t.nameReg -Value $t.value -Type $t.regType -Force
        Write-Status "Set registry: $($t.nameReg) = $($t.value)" -Type 'SUCCESS'
        return $true
    } catch {
        Write-Status "Registry error: $_" -Type 'ERROR'
        return $false
    }
}

function Apply-ServiceTweak {
    param($t)
    
    try {
        $svc = Get-Service -Name $t.serviceName -ErrorAction SilentlyContinue
        if (-not $svc) {
            Write-Status "Service not found: $($t.serviceName)" -Type 'WARNING'
            return $true
        }
        
        # Dung service neu dang chay
        try {
            Stop-Service $t.serviceName -Force -ErrorAction SilentlyContinue | Out-Null
        } catch {}
        
        # Dat startup type
        Set-Service -Name $t.serviceName -StartupType $t.startup -ErrorAction Stop
        Write-Status "Service configured: $($t.serviceName) -> $($t.startup)" -Type 'SUCCESS'
        
        return $true
    } catch {
        Write-Status "Service error: $_" -Type 'ERROR'
        return $false
    }
}

function Apply-ScheduledTaskTweak {
    param($t)
    
    try {
        # Vo hieu hoa task theo ten
        if ($t.taskName) {
            Disable-ScheduledTask -TaskName $t.taskName -ErrorAction SilentlyContinue
            Write-Status "Task disabled: $($t.taskName)" -Type 'SUCCESS'
        }
        
        # Vo hieu hoa nhieu tasks
        if ($t.tasks) {
            foreach ($task in $t.tasks) {
                Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
                Write-Status "Task disabled: $task" -Type 'SUCCESS'
            }
        }
        
        return $true
    } catch {
        Write-Status "Task error: $_" -Type 'ERROR'
        return $false
    }
}

function Execute-Tweak {
    param($t)
    
    Write-Host ""
    Write-Host " THONG TIN TWEAK:" -ForegroundColor $global:UI_Colors.Title
    Write-Host "   Ten: $($t.name)" -ForegroundColor $global:UI_Colors.Value
    Write-Host "   Mo ta: $($t.description)" -ForegroundColor $global:UI_Colors.Label
    Write-Host "   Loai: $($t.category) | Muc do: $($t.level)" -ForegroundColor $global:UI_Colors.Label
    
    if ($t.level -eq "dangerous") {
        Write-Host "   CANH BAO: Tweak nay co the anh huong den tinh nang he thong!" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Kiem tra OS compatibility
    if ($t.os_guard) {
        if (-not (Test-OSVersion -min $t.os_guard.min -max $t.os_guard.max)) {
            Write-Status "Khong tuong thich voi Windows hien tai" -Type 'WARNING'
            Write-Host "   Yeu cau: $($t.os_guard.min) to $($t.os_guard.max)" -ForegroundColor $global:UI_Colors.Label
            if ($t.os_guard.edition_note) {
                Write-Host "   Ghi chu: $($t.os_guard.edition_note)" -ForegroundColor $global:UI_Colors.Warning
            }
            Write-Host ""
            return $false
        }
    }
    
    Write-Status "Dang ap dung tweak..." -Type 'INFO'
    Write-Host ""
    
    $result = $false
    switch ($t.type) {
        "registry"        { $result = Apply-RegistryTweak $t }
        "service"         { $result = Apply-ServiceTweak $t }
        "scheduled_task"  { $result = Apply-ScheduledTaskTweak $t }
        default { Write-Status "Khong ho tro loai tweak: $($t.type)" -Type 'ERROR' }
    }
    
    Write-Host ""
    if ($t.reboot_required) {
        Write-Status "CAN KHOI DONG LAI MAY" -Type 'WARNING'
        Write-Host "   De thay doi co hieu luc day du, vui long khoi dong lai may." -ForegroundColor $global:UI_Colors.Warning
    }
    
    Write-Host ""
    return $result
}

# ============================================================
# TWEAKS MENU (FIXED DISPLAY)
# ============================================================

function Show-TweaksMenu {
    param($Config)
    
    if (-not $Config -or -not $Config.tweaks) {
        Write-Status "Cau hinh tweaks.json khong hop le!" -Type 'ERROR'
        Pause
        return
    }
    
    while ($true) {
        # Xay dung menu items tu tweaks
        $menuItems = @()
        $index = 1
        
        foreach ($tweak in $Config.tweaks) {
            $displayName = $tweak.name
            if ($displayName.Length -gt 35) {
                $displayName = $displayName.Substring(0, 32) + "..."
            }
            
            $menuItems += @{ 
                Key = "$index"; 
                Text = $displayName
            }
            $index++
        }
        
        $menuItems += @{ Key = "0"; Text = "Quay lai Menu Chinh" }
        
        # Hien thi menu voi hai cot
        Show-Menu -MenuItems $menuItems -Title "WINDOWS TWEAKS" -TwoColumn -Prompt "Chon tweak de ap dung (0 de quay lai): "
        
        $choice = Read-Host
        
        if ($choice -eq "0") {
            return
        }
        
        $tweakIndex = [int]$choice - 1
        if ($tweakIndex -ge 0 -and $tweakIndex -lt $Config.tweaks.Count) {
            $selectedTweak = $Config.tweaks[$tweakIndex]
            
            # Hien thi header
            Show-Header -Title "AP DUNG TWEAK"
            
            # Hien thi xac nhan
            Write-Host "Ban co chac muon ap dung tweak nay?" -ForegroundColor $global:UI_Colors.Title
            Write-Host "   Ten: $($selectedTweak.name)" -ForegroundColor $global:UI_Colors.Value
            Write-Host ""
            $confirm = Read-Host "Nhap 'YES' de xac nhan hoac Enter de huy: "
            
            if ($confirm -eq "YES") {
                # Thuc thi tweak
                $success = Execute-Tweak -t $selectedTweak
                
                Write-Host ""
                if ($success) {
                    Write-Status "Hoan thanh!" -Type 'SUCCESS'
                } else {
                    Write-Status "Co loi xay ra!" -Type 'ERROR'
                }
            } else {
                Write-Status "Da huy!" -Type 'INFO'
            }
            
            Write-Host ""
            Pause
        } else {
            Write-Status "Lua chon khong hop le!" -Type 'WARNING'
            Pause
        }
    }
}
