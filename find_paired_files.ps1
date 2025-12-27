# Find MD files paired with HTML/PDF files

$rootPath = "C:\Users\Diane\OneDrive\Documents\GitHub\getJOBS-freelance-app"
$mdFiles = Get-ChildItem -Path $rootPath -Filter "*.md" -File

Write-Host "Checking MD files for HTML/PDF pairs..." -ForegroundColor Cyan
Write-Host ""

$paired = @()
$orphaned = @()

foreach ($mdFile in $mdFiles) {
    $baseName = $mdFile.BaseName
    
    # Check if HTML or PDF with same base name exists
    $htmlExists = Test-Path -Path "$rootPath\$baseName.html"
    $pdfExists = Test-Path -Path "$rootPath\$baseName.pdf"
    
    if ($htmlExists -or $pdfExists) {
        $pairWith = @()
        if ($htmlExists) { $pairWith += "HTML" }
        if ($pdfExists) { $pairWith += "PDF" }
        $paired += [PSCustomObject]@{
            MDFile = $mdFile.Name
            PairedWith = ($pairWith -join " + ")
        }
    } else {
        $orphaned += $mdFile.Name
    }
}

Write-Host "[PAIRED] MD FILES WITH HTML/PDF (KEEP THESE):" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ($paired.Count -gt 0) {
    $paired | Format-Table -AutoSize
    Write-Host "Total paired: $($paired.Count)" -ForegroundColor Green
} else {
    Write-Host "No paired files found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[ORPHANED] MD FILES (SAFE TO DELETE):" -ForegroundColor Red
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ($orphaned.Count -gt 0) {
    $orphaned | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Total orphaned: $($orphaned.Count)" -ForegroundColor Red
} else {
    Write-Host "No orphaned files found" -ForegroundColor Green
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Paired (keep): $($paired.Count)"
Write-Host "  Orphaned (can delete): $($orphaned.Count)"
Write-Host "  Total MD files: $($mdFiles.Count)"
