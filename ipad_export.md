# Exporting Crossums to iPad

This guide covers how to build and run the Crossums Godot project on an iPad.

**Source:** [Godot Docs - Exporting for iOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)

---

## Prerequisites

| Requirement | Status |
|-------------|--------|
| macOS with Xcode | ✅ Xcode.app installed |
| Godot 4.x | ✅ 4.5.1.stable |
| iOS Export Templates | ✅ `ios.zip` present in templates |
| Apple Developer Account | ⚠️ **Required** — need Team ID |
| xcode-select pointing to Xcode | ⚠️ **Fix needed** (see below) |

### Fix xcode-select (Required)

Currently `xcode-select` points to `/Library/Developer/CommandLineTools`, but it needs to point to the full Xcode install for iOS export:

```bash
sudo xcode-select -switch /Applications/Xcode.app
```

Verify:
```bash
xcode-select -p
# Should output: /Applications/Xcode.app/Contents/Developer
```

---

## Step 1: Configure iOS Export Preset

1. Open the project in Godot:
   ```bash
   cd ~/dv/crossums/godot_app
   godot project.godot
   ```

2. Go to **Project → Export** (or `Cmd+Shift+E`)

3. Click **Add...** → Select **iOS**

4. Fill in **required** fields in the Application section:
   - **App Store Team ID**: Your 10-character code (e.g., `ABCDE12XYZ`)
     - Find it at [developer.apple.com](https://developer.apple.com/account/resources/certificates/list) → top right corner
   - **Bundle Identifier**: e.g., `com.yourname.crossums`

5. Optional but recommended:
   - **App Name**: Crossums
   - **Version**: 1.0.0
   - Set an app icon

---

## Step 2: Export to Xcode Project

1. In the Export dialog, click **Export Project**

2. Choose export location:
   - **Path**: `~/dv/crossums/godot_app/exports/ios/` (create folder if needed)
   - **File**: `crossums` (no spaces!)

3. Click **Save** — this generates an Xcode project

Output will include:
```
exports/ios/
├── crossums.xcodeproj
├── crossums/
├── crossums.pck
└── ...
```

---

## Step 3: Build & Run in Xcode

1. Open the Xcode project:
   ```bash
   open ~/dv/crossums/godot_app/exports/ios/crossums.xcodeproj
   ```

2. Connect your iPad via USB (or use wireless debugging if configured)

3. In Xcode:
   - Select your iPad from the device dropdown (top bar)
   - Select **crossums** target
   - Sign the app: Xcode → Signing & Capabilities → Select your Team

4. Click **Run** (▶️) or press `Cmd+R`

5. First run: Your iPad will prompt to trust the developer certificate:
   - On iPad: **Settings → General → VPN & Device Management → [Your Dev Account] → Trust**

---

## Alternative: Development Workflow (Live Linking)

For faster iteration (avoid re-exporting on every change):

1. Export once (as above)

2. In Xcode, drag `~/dv/crossums/godot_app` folder into the project navigator

3. In the dialog:
   - Action: **Reference files in place**
   - Groups: **Create folders**
   - Uncheck target membership

4. Select the folder in navigator → File Inspector:
   - Location: **Relative to Project**
   - Add to **Target Membership**

5. Delete `crossums.pck` from Xcode project

6. Edit `crossums-Info.plist` — add string:
   - Key: `godot_path`
   - Value: `godot_app` (your project folder name)

Now you can edit in Godot and just rebuild in Xcode without re-exporting.

---

## Troubleshooting

### "JSON text did not start with array or object..."
→ Your Team ID is wrong. Use the 10-character code, not your name.

### Export fails with clang/SDK errors
→ Run: `sudo xcode-select -switch /Applications/Xcode.app`

### App won't launch on iPad
→ Trust the developer certificate in iPad Settings

### Simulator not supported
Note: iOS Simulator export is [not currently supported](https://github.com/godotengine/godot/issues/102149). However, Apple Silicon Macs can run iOS apps natively — you can test directly on your Mac.

---

## Quick Reference Commands

```bash
# Open project in Godot
cd ~/dv/crossums/godot_app && godot project.godot

# Export via CLI (after preset configured)
godot --headless --export-release "iOS" exports/ios/crossums

# Open Xcode project
open ~/dv/crossums/godot_app/exports/ios/crossums.xcodeproj

# Fix xcode-select
sudo xcode-select -switch /Applications/Xcode.app
```

---

## Summary

1. Fix `xcode-select` to point to Xcode.app
2. Add iOS export preset in Godot with Team ID + Bundle ID
3. Export to Xcode project
4. Open in Xcode, select iPad, sign & run
5. Trust certificate on iPad if prompted

**Time estimate:** ~15 min first time, ~2 min for subsequent exports.
