function Invoke-AppInstaller {
    param(
        [object]$Config,
        [string[]]$SelectedIds,
        $ProgressBar
    )

    $apps = $Config.applications | Where-Object { $_.id -in $SelectedIds }
    $total = $apps.Count
    $i = 0

    foreach ($app in $apps) {
        $i++
        Set-Progress $ProgressBar $i $total

        Write-Log "Install app: $($app.name)"

        $args = @(
            "install",
            "--id", $app.packageId,
            "-e",
            "--source", $app.source
        )

        if ($app.silent) {
            $args += "--silent"
            $args += "--accept-package-agreements"
            $args += "--accept-source-agreements"
        }

        Start-Process winget -ArgumentList $args -Wait -NoNewWindow
    }
}
