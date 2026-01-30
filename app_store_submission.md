# Publishing Crossums to the App Store

A complete guide to submitting a Godot game to Apple's App Store.

**Sources:**
- [Apple App Store Submitting Guide](https://developer.apple.com/app-store/submitting/)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Apple Developer Program | **$99/year** — [enroll here](https://developer.apple.com/programs/) |
| App Store Connect access | Included with Developer Program |
| Xcode | For building release archive |
| iOS export working | See `ipad_export.md` |
| App icons (1024×1024) | Required for App Store listing |
| Screenshots | Required per device class |

---

## Overview: The Submission Pipeline

```
Godot → Xcode Project → Archive → App Store Connect → Review → Release
         (export)       (build)      (upload)        (~24h)
```

**Timeline estimate:** 2-5 days (mostly waiting for review)

---

## Step 1: Prepare App Store Assets

Before touching Xcode, gather these:

### Required Assets

| Asset | Specification |
|-------|---------------|
| **App Icon** | 1024×1024 PNG, no alpha, no rounded corners |
| **Screenshots** | See sizes below |
| **App Name** | Max 30 characters |
| **Subtitle** | Max 30 characters |
| **Description** | Max 4000 characters |
| **Keywords** | Max 100 characters (comma-separated) |
| **Support URL** | Required |
| **Privacy Policy URL** | Required if collecting any data |

### Screenshot Requirements

You need screenshots for each device class you support:

| Device | Size (portrait) |
|--------|-----------------|
| iPhone 6.9" | 1320 × 2868 |
| iPhone 6.5" | 1284 × 2778 |
| iPad Pro 13" | 2064 × 2752 |
| iPad Pro 12.9" | 2048 × 2732 |

**Tip:** You can use 6.9" screenshots for 6.5", and 13" for 12.9" — App Store Connect will accept them.

**Tip:** Capture directly from device/simulator, or create marketing images in Figma/Photoshop.

---

## Step 2: Configure App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)

2. Click **My Apps** → **+** → **New App**

3. Fill in:
   - **Platform:** iOS
   - **Name:** Crossums
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select your registered ID (e.g., `com.yourname.crossums`)
   - **SKU:** Unique identifier (e.g., `crossums-ios-001`)
   - **User Access:** Full Access

4. Click **Create**

---

## Step 3: Complete App Information

In App Store Connect, fill out each section:

### App Information Tab
- Category: **Games** → **Puzzle**
- Content Rights: Confirm you own/license all content
- Age Rating: Complete the questionnaire (likely 4+ for puzzle game)

### Pricing and Availability Tab
- Price: Free or select price tier
- Availability: Select countries

### App Privacy Tab
- **Data Collection:** Declare what data your app collects
- For a simple offline puzzle game: likely "Data Not Collected"
- If using analytics/crash reporting: declare appropriately

### Version Information (iOS App Section)
- Screenshots (upload for each device size)
- Promotional Text (optional, can change anytime)
- Description
- Keywords
- Support URL
- Marketing URL (optional)
- Version: `1.0.0`
- Copyright: `© 2026 Your Name`
- Routing App Coverage File: Skip unless location-based
- App Review Information:
  - Contact info
  - Demo account (if login required)
  - Notes for reviewer

---

## Step 4: Create Certificates & Provisioning (One-Time Setup)

### In Apple Developer Portal

1. Go to [Certificates, IDs & Profiles](https://developer.apple.com/account/resources/)

2. **Create App ID** (if not done):
   - Identifiers → + → App IDs → App
   - Description: Crossums
   - Bundle ID: Explicit → `com.yourname.crossums`
   - Capabilities: Enable what you need (Game Center, etc.)

3. **Create Distribution Certificate** (if not done):
   - Certificates → + → Apple Distribution
   - Follow CSR process with Keychain Access
   - Download and double-click to install

4. **Create Provisioning Profile**:
   - Profiles → + → App Store Connect
   - Select your App ID
   - Select your Distribution Certificate
   - Name it: `Crossums App Store`
   - Download and double-click to install

---

## Step 5: Build Release Archive in Xcode

1. Open your exported Xcode project:
   ```bash
   open ~/dv/crossums/godot_app/exports/ios/crossums.xcodeproj
   ```

2. Select **Generic iOS Device** (or "Any iOS Device") as build target

3. Configure signing:
   - Select project in navigator → **Signing & Capabilities**
   - Team: Your Apple Developer team
   - Provisioning Profile: Select your App Store profile
   - Or use "Automatically manage signing"

4. Set version numbers:
   - **Version:** `1.0.0` (matches App Store Connect)
   - **Build:** `1` (increment for each upload)

5. Build archive:
   - **Product → Archive**
   - Wait for build to complete
   - Organizer window opens automatically

---

## Step 6: Upload to App Store Connect

### Option A: Xcode Organizer (Easiest)

1. In Organizer, select your archive
2. Click **Distribute App**
3. Select **App Store Connect** → **Upload**
4. Follow prompts (signing, bitcode, symbols)
5. Click **Upload**

### Option B: Transporter App

1. Export archive as `.ipa` from Organizer
2. Open [Transporter](https://apps.apple.com/app/transporter/id1450874784) (free from Mac App Store)
3. Drag `.ipa` into Transporter
4. Click **Deliver**

### After Upload

- Build appears in App Store Connect within ~15-30 minutes
- Apple runs automated checks (may take a few hours)
- Status changes to "Ready to Submit" when processed

---

## Step 7: Submit for Review

1. In App Store Connect → Your App → iOS App section

2. Under **Build**, click **+** and select your uploaded build

3. Answer export compliance question:
   - "Does your app use encryption?" 
   - For most Godot games: **No** (unless you added custom encryption)
   - If yes (HTTPS counts as yes in some cases): You may need to provide documentation or select exemption

4. Review all sections have green checkmarks

5. Click **Add for Review**

6. Choose release option:
   - **Manually release** — You control when it goes live
   - **Automatically release** — Goes live immediately after approval

7. Click **Submit to App Review**

---

## Step 8: App Review Process

### Timeline
- **Typical:** 24-48 hours
- **First submission:** Sometimes longer
- **Rejections:** Add 1-3 days per rejection cycle

### Common Rejection Reasons for Games

| Issue | Solution |
|-------|----------|
| Crashes/bugs | Test thoroughly on real devices |
| Incomplete metadata | Fill all required fields |
| Placeholder content | Remove "lorem ipsum", test data |
| Missing privacy policy | Add URL even for offline games |
| Guideline 4.2 (Minimum Functionality) | Ensure game has enough content |
| Login issues | Provide demo account or make login optional |

### If Rejected

1. Read rejection reason carefully in Resolution Center
2. Fix the issue
3. Increment build number
4. Upload new build
5. Reply in Resolution Center explaining fix
6. Resubmit

---

## Step 9: Release

Once approved:

- **If manual release:** Click "Release This Version" in App Store Connect
- **If automatic:** Already live!

Your app appears on the App Store within ~24 hours of release.

---

## Post-Release

### Updates
1. Create new version in App Store Connect
2. Update "What's New" text
3. Build new archive (increment build number)
4. Upload and submit

### Monitoring
- **App Analytics:** Downloads, engagement, crashes
- **Ratings & Reviews:** Respond to user feedback
- **Crash Reports:** Fix and update

---

## Quick Checklist

```
□ Apple Developer Program enrolled ($99/year)
□ Bundle ID registered
□ Distribution certificate created
□ App Store provisioning profile created
□ App created in App Store Connect
□ App icon (1024×1024)
□ Screenshots for each device size
□ Description, keywords, URLs filled
□ Privacy declarations completed
□ Age rating questionnaire completed
□ Archive built in Xcode
□ Build uploaded to App Store Connect
□ Build selected in version
□ Export compliance answered
□ Submitted for review
□ Approved!
□ Released
```

---

## Estimated Costs

| Item | Cost |
|------|------|
| Apple Developer Program | $99/year |
| Godot Engine | Free |
| Xcode | Free |
| **Total** | **$99/year** |

---

## Resources

- [App Store Connect](https://appstoreconnect.apple.com/)
- [Apple Developer Account](https://developer.apple.com/account/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Marketing Guidelines](https://developer.apple.com/app-store/marketing/guidelines/)
- [Screenshot Specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/)
