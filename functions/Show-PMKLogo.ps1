# =====================================================
# Show-PMKLogo.ps1 - SIMPLE LOGO (ASCII ONLY)
# =====================================================

function Show-PMKLogo {
    Clear-Host
    $logo = @(
        "",
        "  +=====================================================+",
        "  |                                                      |",
        "  |                PMK TOOLBOX v1.0                      |",
        "  |             Toi Uu He Thong Windows                  |",
        "  |                                                      |",
        "  +=====================================================+",
        "",
        "  Tac gia: Minh Khai - 0333090930",
        ""
    )
    
    foreach ($line in $logo) {
        Write-Host $line -ForegroundColor Cyan
    }
}
