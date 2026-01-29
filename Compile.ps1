# Compile.ps1 - Build bundled one-file for one-liner
$Output = "ToiUuPC-Bundled.ps1"

if (Test-Path $Output) { Remove-Item $Output }

"# PMK Toolbox v3.3.2 Bundled" | Out-File $Output -Encoding utf8

Get-Content "functions\*.ps1" | Add-Content $Output

Get-Content "ToiUuPC.ps1" | Where-Object { $_ -notmatch '^\.' } | Add-Content $Output  # Skip dot-source

Write-Host "Built: $Output - Use for releases/one-liner."

# Auto append changelog (prompt note)
$changelogPath = "changelog.md"
if (Test-Path $changelogPath) {
    $note = Read-Host "Enter update note for changelog (or empty to skip)"
    if ($note) {
        "## $(Get-Date -Format 'yyyy-MM-dd') - v3.3.2`n- $note`n" | Add-Content $changelogPath
        Write-Host "Appended to $changelogPath"
    }
} else {
    Write-Warning "changelog.md not found! Create it first."
}