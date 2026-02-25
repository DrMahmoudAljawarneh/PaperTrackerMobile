# Paper Tracker — Deployment Guide

## Prerequisites

1. **Firebase CLI** installed and authenticated:
   ```powershell
   npm install -g firebase-tools
   firebase login
   ```
2. **Flutter SDK** configured with Android build tools
3. **Java 17** for Android builds

---

## Quick Deploy

Run the deploy script from the project root:

```powershell
# Deploy with current version
.\deploy.ps1

# Deploy with a version bump
.\deploy.ps1 -Version "0.2.0"
```

This will:
1. Build the release APK (`flutter build apk --release`)
2. Copy the APK to `hosting/app-release.apk`
3. Update `hosting/version.json` and `pubspec.yaml` (if `-Version` is provided)
4. Deploy to Firebase Hosting (`firebase deploy --only hosting`)

---

## Manual Deploy (Step by Step)

### 1. Update the Version

Edit `hosting/version.json`:
```json
{
  "version": "0.2.0",
  "apkUrl": "/app-release.apk",
  "releaseNotes": "Added collaboration feature and bug fixes"
}
```

Update `pubspec.yaml` to match:
```yaml
version: 0.2.0
```

### 2. Build the APK

```powershell
flutter build apk --release
```

The APK will be at: `build\app\outputs\flutter-apk\app-release.apk`

### 3. Copy APK to Hosting

```powershell
Copy-Item build\app\outputs\flutter-apk\app-release.apk hosting\app-release.apk
```

### 4. Deploy to Firebase

```powershell
firebase deploy --only hosting
```

---

## How Auto-Update Works

```
App opens → Dashboard loads
                ↓
    Fetches version.json from Firebase Hosting
                ↓
    Compares remote version vs local version
                ↓
    If remote > local → Shows update dialog
                ↓
    User taps "Download" → Opens APK download URL
```

- The update check runs every time the dashboard loads
- `version.json` is served with `no-cache` headers so the app always gets the latest version
- The version comparison is semantic (e.g., `0.2.0 > 0.1.0`)

---

## Project Structure

```
hosting/
├── index.html          ← Landing page (download button)
├── version.json        ← Version manifest
└── app-release.apk     ← Built APK (created by deploy script)

lib/services/
└── update_service.dart ← In-app update checker

deploy.ps1              ← One-command deploy script
firebase.json           ← Firebase Hosting configuration
```

---

## Configuration

The Firebase Hosting URL is set in `lib/services/update_service.dart`:
```dart
static const String _baseUrl = 'https://papertracker-99036.web.app';
```

If your Firebase project has a custom domain, update this URL.

---

## Pushing a New Update (Checklist)

1. ✅ Make your code changes
2. ✅ Pick a new version number (semantic: `MAJOR.MINOR.PATCH`)
3. ✅ Write release notes for `version.json`
4. ✅ Run `.\deploy.ps1 -Version "X.Y.Z"`
5. ✅ Verify at https://papertracker-99036.web.app
6. ✅ Existing users will see the update dialog on next app open
