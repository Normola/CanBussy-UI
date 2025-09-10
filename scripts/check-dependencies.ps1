# Local Dependency Update Script
# Alternative to Dependabot for local development

param(
    [switch]$DryRun,
    [switch]$MajorUpdates,
    [switch]$AutoUpdate
)

Write-Host "🔍 CanBussy-UI Dependency Checker" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Check Flutter dependencies
Write-Host "`n📦 Checking Flutter/Dart dependencies..." -ForegroundColor Yellow
flutter pub outdated

if ($DryRun) {
    Write-Host "`n🧪 Dry run - showing what would be upgraded:" -ForegroundColor Blue
    flutter pub upgrade --dry-run
}

if ($MajorUpdates) {
    Write-Host "`n⚠️  Checking for major version updates:" -ForegroundColor Magenta
    flutter pub outdated --show-all
    
    if ($AutoUpdate) {
        Write-Host "`n🚀 Applying major version updates..." -ForegroundColor Green
        flutter pub upgrade --major-versions
    } else {
        Write-Host "`n💡 To apply major updates, run: flutter pub upgrade --major-versions" -ForegroundColor Gray
    }
} elseif ($AutoUpdate) {
    Write-Host "`n🔄 Applying safe dependency updates..." -ForegroundColor Green
    flutter pub upgrade
    
    Write-Host "`n🧹 Cleaning up..." -ForegroundColor Blue
    flutter clean
    flutter pub get
    
    Write-Host "`n✅ Dependencies updated successfully!" -ForegroundColor Green
}

# Check for GitHub Actions updates (if .github/workflows exists)
if (Test-Path ".github/workflows") {
    Write-Host "`n🔧 GitHub Actions workflows found:" -ForegroundColor Yellow
    Get-ChildItem ".github/workflows" -Filter "*.yml" | ForEach-Object {
        Write-Host "   - $($_.Name)" -ForegroundColor Gray
    }
    Write-Host "   💡 Check manually for action updates at: https://github.com/marketplace/actions" -ForegroundColor Gray
}

# Check Android Gradle dependencies (if android folder exists)
if (Test-Path "android") {
    Write-Host "`n🤖 Android Gradle dependencies:" -ForegroundColor Yellow
    Write-Host "   📍 Location: android/build.gradle & android/app/build.gradle" -ForegroundColor Gray
    Write-Host "   💡 Run './gradlew dependencyUpdates' in android/ for Gradle updates" -ForegroundColor Gray
}

Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "   - Use this script with -DryRun to preview changes" -ForegroundColor White
Write-Host "   - Use -MajorUpdates to check for breaking changes" -ForegroundColor White
Write-Host "   - Use -AutoUpdate to apply safe updates automatically" -ForegroundColor White
Write-Host "   - Dependabot will handle this automatically in GitHub" -ForegroundColor White

Write-Host "`nExample usage:" -ForegroundColor Green
Write-Host "   .\scripts\check-dependencies.ps1 -DryRun" -ForegroundColor Gray
Write-Host "   .\scripts\check-dependencies.ps1 -AutoUpdate" -ForegroundColor Gray
Write-Host "   .\scripts\check-dependencies.ps1 -MajorUpdates -AutoUpdate" -ForegroundColor Gray
