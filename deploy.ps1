# Paper Tracker — Deploy Script
# Builds APK, creates GitHub Release, deploys landing page to Firebase Hosting

param(
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

Write-Host "`n🚀 Paper Tracker Deploy Script" -ForegroundColor Cyan
Write-Host "================================`n"

# Step 1: Read current version from version.json
$versionFile = "hosting/version.json"
$versionData = Get-Content $versionFile | ConvertFrom-Json
$currentVersion = $versionData.version
Write-Host "📌 Current version: $currentVersion"

# Step 2: If new version provided, update version.json and pubspec.yaml
if ($Version -ne "") {
    Write-Host "📝 Bumping to version: $Version" -ForegroundColor Yellow

    # Update version.json with GitHub Release URL
    $versionData.version = $Version
    $versionData.apkUrl = "https://github.com/DrMahmoudAljawarneh/PaperTrackerMobile/releases/download/v$Version/app-release.apk"
    $versionData | ConvertTo-Json | Set-Content $versionFile
    Write-Host "   ✅ Updated hosting/version.json"

    # Update pubspec.yaml
    $pubspec = Get-Content "pubspec.yaml" -Raw
    $pubspec = $pubspec -replace "version: .*", "version: $Version"
    Set-Content "pubspec.yaml" $pubspec
    Write-Host "   ✅ Updated pubspec.yaml"

    $currentVersion = $Version
}
else {
    # Ensure apkUrl points to GitHub
    $versionData.apkUrl = "https://github.com/DrMahmoudAljawarneh/PaperTrackerMobile/releases/download/v$currentVersion/app-release.apk"
    $versionData | ConvertTo-Json | Set-Content $versionFile
}

Write-Host "`n📦 Building APK (release mode)..." -ForegroundColor Yellow
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ APK built successfully"

$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
$apkSize = [math]::Round((Get-Item $apkPath).length / 1MB, 1)
Write-Host "   📦 APK size: $apkSize MB"

# Step 3: Git commit and push
Write-Host "`n📤 Committing and pushing to GitHub..." -ForegroundColor Yellow
git add .
git commit -m "Release v$currentVersion" 2>$null
git push origin master

# Step 4: Create GitHub Release with APK
Write-Host "`n🏷️  Creating GitHub Release v$currentVersion..." -ForegroundColor Yellow
$releaseNotes = $versionData.releaseNotes
gh release create "v$currentVersion" $apkPath --title "v$currentVersion" --notes "$releaseNotes" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Release may already exist. Trying to upload APK to existing release..." -ForegroundColor Yellow
    gh release upload "v$currentVersion" $apkPath --clobber 2>&1
}

# Step 5: Deploy landing page to Firebase Hosting
Write-Host "`n🔥 Deploying landing page to Firebase Hosting..." -ForegroundColor Yellow
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Firebase deploy had issues, but GitHub Release is up." -ForegroundColor Yellow
}

Write-Host "`n✅ Deploy complete!" -ForegroundColor Green
Write-Host "   Version:  $currentVersion"
Write-Host "   Landing:  https://papertracker-99036.web.app"
Write-Host "   Release:  https://github.com/DrMahmoudAljawarneh/PaperTrackerMobile/releases/tag/v$currentVersion"
Write-Host "   APK:      https://github.com/DrMahmoudAljawarneh/PaperTrackerMobile/releases/download/v$currentVersion/app-release.apk"
Write-Host ""
