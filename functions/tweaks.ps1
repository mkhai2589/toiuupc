function Invoke-SystemTweaks {
    param(
        [array]$Tweaks,
        [string[]]$SelectedIds,
        [string]$BackupPath,
        $ProgressBar
    )

    $applyList = $Tweaks | Where-Object { $_.id -in $SelectedIds }
    $total = $applyList.Count
    $i = 0

    foreach ($t in $applyList) {
        $i++
        Set-Progress $ProgressBar $i $total

        Write-Log "Apply tweak: $($t.id)"

        switch ($t.type) {

            "registry" {
                if (-not (Test-Path $t.path)) {
                    New-Item -Path $t.path -Force | Out-Null
                }

                # backup
                $bkFile = Join-Path $BackupPath "$($t.id).json"
                if (-not (Test-Path $bkFile)) {
                    $old = Get-ItemProperty -Path $t.path -Name $t.nameReg -ErrorAction SilentlyContinue
                    $old | ConvertTo-Json | Out-File $bkFile -Encoding UTF8
                }

                Set-ItemProperty `
                    -Path $t.path `
                    -Name $t.nameReg `
                    -Value $t.value `
                    -Type $t.regType
            }

            "service" {
                $svc = Get-Service -Name $t.serviceName -ErrorAction SilentlyContinue
                if ($svc) {
                    sc.exe config $t.serviceName start= $t.startup | Out-Null
                    Stop-Service $t.serviceName -Force -ErrorAction SilentlyContinue
                }
            }

            "service_multiple" {
                foreach ($s in $t.services) {
                    $svc = Get-Service -Name $s.name -ErrorAction SilentlyContinue
                    if ($svc) {
                        sc.exe config $s.name start= $s.startup | Out-Null
                        Stop-Service $s.name -Force -ErrorAction SilentlyContinue
                    }
                }
            }

            "scheduled_task" {
                if ($t.taskName) {
                    Get-ScheduledTask -TaskName $t.taskName -ErrorAction SilentlyContinue |
                        Disable-ScheduledTask
                }
                if ($t.tasks) {
                    foreach ($name in $t.tasks) {
                        Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue |
                            Disable-ScheduledTask
                    }
                }
            }
        }
    }
}

function Undo-SystemTweaks {
    param(
        [string]$BackupPath
    )

    Get-ChildItem $BackupPath -Filter "*.json" | ForEach-Object {
        $data = Get-Content $_.FullName | ConvertFrom-Json
        if ($data.PSPath -and $data.PSChildName) {
            Set-ItemProperty `
                -Path $data.PSPath `
                -Name $data.PSChildName `
                -Value $data.$($data.PSChildName)
        }
    }
}
