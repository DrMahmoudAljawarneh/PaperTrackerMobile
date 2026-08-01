# Paper Tracker — Deploy Script
# Builds APK, creates GitHub Release, deploys landing page to Firebase Hosting
#
# Usage:
#   .\deploy.ps1                # re-deploy current version
#   .\deploy.ps1 -Version 2.4.1 # bump version, build, release, deploy

param(
    [string]$Version = ""
)

# "Stop" here previously made native-command stderr (e.g. gh "release already
# exists") kill the whole script before the fallback could run. We use
# "Continue" and check $LASTEXITCODE explicitly instead.
$ErrorActionPreference = "Continue"

# Global safety net for unexpected terminating errors.
trap {
    Write-Host ""
    Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Builds are cached, so re-running should be fast." -ForegroundColor DarkGray
    exit 1
}

function Fail {
    param([string]$Message)
    Write-Host ""
    Write-Host "❌ $Message" -ForegroundColor Red
    exit 1
}

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host $Message -ForegroundColor Yellow
}

# Runs a native command, relaying stdout+stderr to the host, and returns the
# exit code. Never lets stderr terminate the script.
function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(ValueFromRemainingArguments = $true)][object[]]$ArgumentList = @()
    )
    $output = & $Command @ArgumentList 2>&1
    $code = $LASTEXITCODE
    foreach ($line in $output) {
        if ($line -is [System.Management.Automation.ErrorRecord]) {
            Write-Host $line.ToString() -ForegroundColor DarkGray
        } else {
            Write-Host $line
        }
    }
    return $code
}

# Writes a file as UTF-8 without BOM (ConvertTo-Json/Set-Content can otherwise
# mangle non-ASCII release notes).
function Set-ContentUtf8 {
    param([string]$Path, [string]$Value)
    [System.IO.File]::WriteAllText($Path, $Value + "`n", [System.Text.UTF8Encoding]::new($false))
}

Write-Host ""
Write-Host "🚀 Paper Tracker Deploy Script" -ForegroundColor Cyan
Write-Host "================================"

# --- Pre-flight checks ----------------------------------------------------
$required = @("flutter", "gh", "git", "firebase")
foreach ($tool in $required) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Fail "'$tool' was not found on PATH. Install it and re-run."
    }
}

# --- Step 1: read current version -----------------------------------------
$versionFile = "web/version.json"
try {
    $versionData = Get-Content $versionFile -Raw | ConvertFrom-Json
    $currentVersion = $versionData.version
} catch {
    Fail "Could not read $versionFile. $($_.Exception.Message)"
}
Write-Host "📌 Current version: $currentVersion"

# --- Step 2: bump version if requested -------------------------------------
if ($Version -ne "") {
    Write-Host "📝 Bumping to version: $Version" -ForegroundColor Yellow
    $versionData.version = $Version
    $versionData.apkUrl = "https://github.com/DrMahmoudAljawarneh/PaperTrackerMobile/releases/download/v$Version/app-release.apk"
    Set-ContentUtf8 $versionFile ($versionData | ConvertTo-Json)

    $pubspec = Get-Content "pubspec.yaml" -Raw
    $pubspec = $pubspec -replace "version: .*", "version: $Version"
    Set-ContentUtf8 "pubspec.yaml" $pubspec

    $currentVersion = $Version
} else {
    $versionData.apkUrl = "https://github.com/DrMahmoudAljawarneh/PaperTrackerMobile/releases/download/v$currentVersion/app-release.apk"
    Set-ContentUtf8 $versionFile ($versionData | ConvertTo-Json)
}

# --- Step 3: build APK ------------------------------------------------------
Write-Step "📦 Building APK (release mode)..."
$code = Invoke-Native flutter build apk --release
if ($code -ne 0) { Fail "APK build failed." }
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) { Fail "APK not found at $apkPath" }
$apkSize = [math]::Round((Get-Item $apkPath).length / 1MB, 1)
Write-Host "   ✅ APK built ($apkSize MB)"

# --- Step 4: build web -------------------------------------------------------
Write-Step "🌐 Building Flutter Web (release mode)..."
$code = Invoke-Native flutter build web --release
if ($code -ne 0) { Fail "Web build failed." }
Write-Host "   ✅ Web build successful"

# --- Step 5: git commit and push ---------------------------------------------
Write-Step "📤 Committing and pushing to GitHub..."
git add . 2>&1 | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) { Fail "git add failed." }

$staged = git status --porcelain
if ($LASTEXITCODE -ne 0) { Fail "git status failed." }
if (-not $staged) {
    Write-Host "   ℹ️ No changes to commit."
} else {
    git commit -m "Release v$currentVersion" 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) { Fail "git commit failed." }
}

git push origin master 2>&1 | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) { Fail "git push failed." }

# --- Step 6: create GitHub release --------------------------------------------
Write-Step "🏷️  Creating GitHub Release v$currentVersion..."
$releaseNotes = $versionData.releaseNotes
$notesFile = Join-Path $env:TEMP "paper_tracker_release_$currentVersion.md"
[System.IO.File]::WriteAllText($notesFile, [string]$releaseNotes, [System.Text.UTF8Encoding]::new($false))

$code = Invoke-Native gh release create "v$currentVersion" $apkPath --title "v$currentVersion" --notes-file $notesFile
if ($code -ne 0) {
    Write-Host ""
    Write-Host "⚠️  Release create failed (it may already exist). Uploading APK to the existing release..." -ForegroundColor Yellow
    $code = Invoke-Native gh release upload "v$currentVersion" $apkPath --clobber
    if ($code -ne 0) {
        Write-Host ""
        Write-Host "   ❌ Could not create or update the GitHub release. Upload it manually:" -ForegroundColor Red
        Write-Host "      gh release upload v$currentVersion $apkPath --clobber" -ForegroundColor Red
    }
}

# --- Step 7: deploy to Firebase Hosting ---------------------------------------
Write-Step "🔥 Deploying Web app to Firebase Hosting..."
$code = Invoke-Native firebase deploy --only hosting
if ($code -ne 0) {
    Write-Host ""
    Write-Host "   ⚠️  Firebase deploy had issues, but the GitHub release is up." -ForegroundColor Yellow
}

# --- Done -----------------------------------------------------------------------
Write-Host ""
Write-Host "✅ Deploy complete!" -ForegroundColor Green
Write-Host "   Version:  $currentVersion"
Write-Host "   Landing:  https://papercheck-2026.web.app"
Write-Host "   Release:  https://github.com/DrMahmoudAljawarneh/PaperTrackerMobile/releases/tag/v$currentVersion"
Write-Host "   APK:      https://github.com/DrMahmoudAljawarneh/PaperTrackerMobile/releases/download/v$currentVersion/app-release.apk"
Write-Host ""
