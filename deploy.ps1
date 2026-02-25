# Paper Tracker — Deploy Script
# Builds the APK and deploys to Firebase Hosting

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

    # Update version.json
    $versionData.version = $Version
    $versionData | ConvertTo-Json | Set-Content $versionFile
    Write-Host "   ✅ Updated hosting/version.json"

    # Update pubspec.yaml
    $pubspec = Get-Content "pubspec.yaml" -Raw
    $pubspec = $pubspec -replace "version: .*", "version: $Version"
    Set-Content "pubspec.yaml" $pubspec
    Write-Host "   ✅ Updated pubspec.yaml"

    $currentVersion = $Version
}

Write-Host "`n📦 Building APK (release mode)..." -ForegroundColor Yellow
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ APK built successfully"

# Step 3: Copy APK to hosting directory
$apkSource = "build\app\outputs\flutter-apk\app-release.apk"
$apkDest = "hosting\app-release.apk"
Copy-Item $apkSource $apkDest -Force
$apkSize = [math]::Round((Get-Item $apkDest).length / 1MB, 1)
Write-Host "   ✅ APK copied to hosting/ ($apkSize MB)"

# Step 4: Deploy to Firebase Hosting
Write-Host "`n🔥 Deploying to Firebase Hosting..." -ForegroundColor Yellow
firebase deploy --only hosting --debug
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Deploy failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Deploy complete!" -ForegroundColor Green
Write-Host "   Version: $currentVersion"
Write-Host "   URL: https://papertracker-99036.web.app"
Write-Host ""
