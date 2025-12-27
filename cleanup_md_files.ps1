# Delete orphaned MD files (209 files without HTML/PDF pairs)
# Keeps: 14 paired files + NOTIFICATION_JOB_APPROVAL_FIXES.md

$rootPath = "C:\Users\Diane\OneDrive\Documents\GitHub\getJOBS-freelance-app"

# Files to KEEP (paired with HTML/PDF + consolidated problem file)
$keepFiles = @(
    "ADMIN_GUIDE_COMPLETE.md",
    "COMPREHENSIVE_APP_GUIDE.md",
    "COMPREHENSIVE_APP_GUIDE_INDEX.md",
    "COMPREHENSIVE_APP_GUIDE_SUMMARY.md",
    "FEATURE_GUIDE_BATCH1_JOBSEEKER.md",
    "FEATURE_GUIDE_BATCH2_EMPLOYER.md",
    "FEATURE_GUIDE_BATCH3_TRAINER.md",
    "FEATURE_GUIDE_BATCH4_ADMIN.md",
    "FEATURE_GUIDE_BATCH5_COMMON.md",
    "GETTING_STARTED_COMMON_FEATURES.md",
    "USER_MANUAL_EMPLOYERS.md",
    "USER_MANUAL_JOB_SEEKERS.md",
    "USER_MANUAL_TRAINERS.md",
    "USER_WORKFLOWS_GUIDE.md",
    "NOTIFICATION_JOB_APPROVAL_FIXES.md"
)

$mdFiles = Get-ChildItem -Path $rootPath -Filter "*.md" -File

$deleteCount = 0
$skipCount = 0

Write-Host "Starting cleanup of orphaned MD files..." -ForegroundColor Cyan
Write-Host ""

foreach ($mdFile in $mdFiles) {
    if ($keepFiles -contains $mdFile.Name) {
        Write-Host "KEEP: $($mdFile.Name)" -ForegroundColor Green
        $skipCount++
    } else {
        Remove-Item -Path $mdFile.FullName -Force
        Write-Host "DELETE: $($mdFile.Name)" -ForegroundColor Red
        $deleteCount++
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Cleanup Complete!" -ForegroundColor Green
Write-Host "Deleted: $deleteCount files" -ForegroundColor Red
Write-Host "Kept: $skipCount files" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
