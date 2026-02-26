# Paper Tracker — Deployment Guide

## Architecture

```
Firebase Hosting (free)  →  Landing page + version.json
GitHub Releases  (free)  →  APK file downloads
In-app checker           →  Fetches version.json, prompts user to update
```

---

## Quick Deploy

```powershell
# Deploy with a version bump
.\deploy.ps1 -Version "0.2.0"

# Deploy with current version
.\deploy.ps1
```

The script will:
1. Update `hosting/version.json` and `pubspec.yaml` (if `-Version` provided)
2. Build the release APK
3. Commit and push to GitHub
4. Create a GitHub Release with the APK attached
5. Deploy the landing page to Firebase Hosting

---

## Links

| Resource | URL |
|---|---|
| **Landing Page** | https://papercheck-2026.web.app |
| **GitHub Repo** | https://github.com/DrMahmoudAljawarneh/PaperTrackerMobile |
| **Latest Release** | https://github.com/DrMahmoudAljawarneh/PaperTrackerMobile/releases |

---

## Manual Deploy (Step by Step)

### 1. Update the Version

Edit `hosting/version.json`:
```json
{
  "version": "0.2.0",
  "apkUrl": "https://github.com/DrMahmoudAljawarneh/PaperTrackerMobile/releases/download/v0.2.0/app-release.apk",
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

### 3. Commit and Push

```powershell
git add .
git commit -m "Release v0.2.0"
git push origin master
```

### 4. Create GitHub Release

```powershell
gh release create v0.2.0 build\app\outputs\flutter-apk\app-release.apk --title "v0.2.0" --notes "Release notes here"
```

### 5. Deploy Landing Page

```powershell
firebase use papercheck-2026
firebase deploy --only hosting
```

---

## How Auto-Update Works

```
App opens → Dashboard loads
        ↓
Fetches version.json from Firebase Hosting
        ↓
Compares remote version vs local app version
        ↓
If remote > local → Shows "Update Available" dialog
        ↓
User taps "Download" → Opens GitHub Release APK URL
```

- The check runs every time the dashboard loads
- `version.json` has `no-cache` headers so the app always gets the latest
- Version comparison is semantic (e.g., `0.2.0 > 0.1.0`)

---

## Project Structure

```
hosting/
├── index.html          ← Landing page with download button
└── version.json        ← Version manifest (points to GitHub Release)

lib/services/
└── update_service.dart ← In-app update checker

deploy.ps1              ← One-command build + deploy script
firebase.json           ← Firebase Hosting config
```

---

## Pushing a New Update (Checklist)

1. ✅ Make your code changes
2. ✅ Write release notes in `hosting/version.json`
3. ✅ Run `.\deploy.ps1 -Version "X.Y.Z"`
4. ✅ Verify at https://papercheck-2026.web.app
5. ✅ Existing users see the update dialog on next app open
