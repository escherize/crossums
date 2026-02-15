# App Store MVP Analysis

> What do we need to ship Crossums on the iOS App Store?
> Synthesized from: mvp.md, GTM_STRATEGY.md, MASTER_TODO.md, ipad_export.md

---

## Current State Summary

**What's Ready:**
- ✅ Core game loop works
- ✅ 9 operators implemented (counter, row/col master, circlicious, elite_delete, purist, gimme, sum_sight, safety_net)
- ✅ Shop system works
- ✅ 8-stage progression
- ✅ Basic sound effects
- ✅ iOS export templates installed
- ✅ Godot 4.5 (supports iOS export)

**What's Missing:**
- ⚠️ xcode-select not pointing to Xcode.app
- ⚠️ No Apple Developer Program membership ($99/year)
- ⚠️ No app icons (1024x1024 + all required sizes)
- ⚠️ No screenshots for App Store listing
- ⚠️ No App Store Connect setup
- ⚠️ No privacy policy URL
- ⚠️ Score animation not polished
- ⚠️ 10 operator minimum not met (have 9, need 1 more)

---

## Actionable Steps (In Order)

### Phase 1: Technical Prerequisites (Day 1)

#### 1.1 Fix Xcode Command Line Tools
```bash
sudo xcode-select -switch /Applications/Xcode.app
xcode-select -p  # Should show: /Applications/Xcode.app/Contents/Developer
```
**Time:** 2 minutes
**Status:** Not done

#### 1.2 Apple Developer Program
- Enroll at [developer.apple.com](https://developer.apple.com/programs/enroll/)
- Cost: $99/year
- Requires: Apple ID with 2FA
- Processing time: Usually instant, sometimes 24-48 hours

**Time:** 30 minutes + wait
**Status:** Not done

#### 1.3 Get Team ID
- After enrollment: [developer.apple.com/account](https://developer.apple.com/account)
- Team ID is 10-character alphanumeric (e.g., `ABCDE12XYZ`)
- Found in Membership section or certificate list

**Time:** 5 minutes
**Status:** Blocked by 1.2

---

### Phase 2: App Identity (Day 1-2)

#### 2.1 Choose Bundle ID
- Format: `com.yourname.crossums`
- Must be unique on App Store
- Cannot be changed after first upload
- **Recommendation:** `com.crossums.app` or `com.yourname.crossums`

**Time:** 5 minutes
**Status:** Not done

#### 2.2 Create App Icons
Required sizes for iOS:
```
1024x1024  - App Store (REQUIRED)
180x180    - iPhone 60pt @3x
167x167    - iPad Pro 83.5pt @2x
152x152    - iPad 76pt @2x
120x120    - iPhone 60pt @2x / iPhone 40pt @3x
87x87      - iPhone 29pt @3x
80x80      - iPhone 40pt @2x / iPad 40pt @2x
76x76      - iPad 76pt @1x
60x60      - iPhone 60pt @1x
58x58      - iPhone 29pt @2x / iPad 29pt @2x
40x40      - iPad 40pt @1x
29x29      - iPhone 29pt @1x / iPad 29pt @1x
20x20      - iPad 20pt @1x
```

**Approach:**
1. Create 1024x1024 source icon
2. Use tool like [appicon.co](https://appicon.co) to generate all sizes
3. Place in Godot iOS export preset or Xcode project

**Design direction:**
- Grid of numbers (3x3 or stylized)
- Bold, clean, readable at small sizes
- Color: Purple/blue from game theme
- Hint of math/puzzle vibes

**Time:** 1-2 hours (including design iteration)
**Status:** Not done

---

### Phase 3: Godot Export Setup (Day 2)

#### 3.1 Configure iOS Export Preset

In Godot: **Project → Export → Add → iOS**

Required fields:
```
Application:
  App Store Team ID: [Your Team ID]
  Bundle Identifier: com.yourname.crossums
  App Name: Crossums
  Version: 1.0.0

Icons:
  [Upload each size OR use automatic generation]

Capabilities:
  [None required for this game]
```

**Time:** 15 minutes
**Status:** Not done

#### 3.2 Test Export to Xcode

```bash
cd ~/dv/crossums/godot_app
mkdir -p exports/ios
godot --headless --export-release "iOS" exports/ios/crossums
```

Or via GUI: Export dialog → Export Project → Save to exports/ios/

**Time:** 10 minutes
**Status:** Not done

#### 3.3 Test on Real Device

1. Open `exports/ios/crossums.xcodeproj` in Xcode
2. Connect iPad/iPhone
3. Select device from dropdown
4. Sign with your developer account
5. Build and run
6. Trust certificate on device (Settings → General → VPN & Device Management)

**Critical checks:**
- [ ] Touch controls work
- [ ] Sound plays
- [ ] All screens render correctly
- [ ] No crashes
- [ ] Performance acceptable (60fps)
- [ ] Notch/safe areas handled

**Time:** 30 minutes
**Status:** Not done

---

### Phase 4: App Store Connect Setup (Day 2-3)

#### 4.1 Create App Record

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. My Apps → + → New App
3. Fill in:
   - Platform: iOS
   - Name: Crossums
   - Primary Language: English (U.S.)
   - Bundle ID: [Select from dropdown - matches Godot config]
   - SKU: crossums-1 (internal reference)

**Time:** 10 minutes
**Status:** Not done

#### 4.2 Prepare App Information

**Required:**
- App icon (1024x1024)
- Privacy Policy URL
- Support URL
- Marketing URL (optional)
- Age Rating (questionnaire)
- Categories: Games → Puzzle, Strategy
- Price: Free or Paid (recommend $2.99-4.99)

**Privacy Policy:**
- If no data collected: Simple "We don't collect any data" page
- Host on: GitHub Pages, Notion, personal site
- Must be publicly accessible URL

**Time:** 1-2 hours
**Status:** Not done

#### 4.3 App Store Listing Content

**Required:**
- Name: Crossums (30 char max)
- Subtitle: "A number puzzle roguelike" (30 char max)
- Description: 4000 char max
- Keywords: 100 char max, comma-separated
- What's New: For updates
- Support URL

**Recommended description structure:**
```
Crossums is a roguelike number puzzle game inspired by Balatro.

Delete numbers from a grid so each row and column sums to its target.
Keep more numbers for higher scores. Collect Operators that change
the rules. How far can you go?

FEATURES:
• 8 challenging stages with increasing difficulty
• 10+ unique Operators with game-changing effects
• Roguelike progression: build your strategy each run
• No timers, no pressure - play at your pace
• One-handed play perfect for commuting

"Balatro meets Sudoku" - that's Crossums.
```

**Keywords suggestion:**
`puzzle,roguelike,number,math,balatro,logic,strategy,brain,indie,singleplayer`

**Time:** 1-2 hours
**Status:** Not done

---

### Phase 5: Screenshots & Media (Day 3)

#### 5.1 Required Screenshot Sizes

**iPhone:**
- 6.7" (1290 × 2796) - iPhone 15 Pro Max - REQUIRED
- 6.5" (1242 × 2688) - iPhone 11 Pro Max - REQUIRED
- 5.5" (1242 × 2208) - iPhone 8 Plus

**iPad:**
- 12.9" (2048 × 2732) - iPad Pro - REQUIRED
- 11" (1668 × 2388) - iPad Pro 11"

**Minimum:** 3 screenshots per device class
**Maximum:** 10 screenshots

#### 5.2 Screenshot Content Plan

1. **Title/Hero shot** - Puzzle grid mid-solve, showing core loop
2. **Operators** - Shop or operator display showing variety
3. **Score explosion** - High score moment with breakdown visible
4. **Stage progression** - Map or stage indicator showing journey
5. **Clean UI** - Simple puzzle demonstrating "easy to learn"

**Tools:**
- Take screenshots on device with Xcode (Window → Devices → Screenshots)
- Or use Simulator for perfect sizes
- Add text overlays with Figma/Canva

**Time:** 2-4 hours
**Status:** Not done

---

### Phase 6: Build & Submit (Day 4)

#### 6.1 Archive Build

In Xcode:
1. Select "Any iOS Device (arm64)" as target
2. Product → Archive
3. Wait for archive to complete
4. Window → Organizer opens automatically

**Time:** 10-20 minutes (build time)
**Status:** Not done

#### 6.2 Upload to App Store Connect

1. In Organizer, select archive
2. Click "Distribute App"
3. Choose "App Store Connect"
4. Follow wizard (automatic signing recommended)
5. Upload

**Time:** 10-30 minutes (upload time varies)
**Status:** Not done

#### 6.3 Submit for Review

1. In App Store Connect, go to your app
2. Select the build you uploaded
3. Fill in any missing metadata
4. Answer export compliance (No encryption? → "No")
5. Submit for Review

**Time:** 15 minutes
**Status:** Not done

---

### Phase 7: Review & Launch (Day 5-7)

#### 7.1 Review Timeline

- **First submission:** 24-48 hours typical
- **Rejections:** Common reasons
  - Crashes
  - Incomplete metadata
  - Privacy issues
  - Guidelines violations

#### 7.2 Common Rejection Fixes

| Rejection Reason | Fix |
|-----------------|-----|
| Crashes on launch | Test on real device before submit |
| Missing privacy policy | Add valid URL |
| Placeholder content | Remove "TODO" or "Lorem ipsum" |
| Guideline 2.1 (Performance) | Optimize, fix memory leaks |
| Guideline 4.2 (Minimum Functionality) | Ensure enough content |

#### 7.3 After Approval

1. Choose release option: Manual or Automatic
2. Monitor initial reviews
3. Track downloads in App Store Connect
4. Prepare first update (bug fixes from feedback)

---

## Complete Checklist

### Prerequisites
- [ ] xcode-select points to Xcode.app
- [ ] Apple Developer Program enrolled ($99)
- [ ] Team ID obtained
- [ ] Bundle ID chosen

### Assets
- [ ] App icon 1024x1024 created
- [ ] All icon sizes generated
- [ ] 3+ iPhone screenshots (6.7" and 6.5")
- [ ] 3+ iPad screenshots (12.9")
- [ ] Privacy policy URL live

### Godot Setup
- [ ] iOS export preset configured
- [ ] Team ID entered
- [ ] Bundle ID entered
- [ ] App name set
- [ ] Icons configured

### Testing
- [ ] Export to Xcode works
- [ ] Runs on real iPhone/iPad
- [ ] Touch controls work
- [ ] Sound works
- [ ] No crashes
- [ ] Performance acceptable

### App Store Connect
- [ ] App record created
- [ ] Description written
- [ ] Keywords set
- [ ] Categories selected
- [ ] Price set
- [ ] Age rating completed
- [ ] Screenshots uploaded

### Submission
- [ ] Archive built
- [ ] Build uploaded
- [ ] Review submitted

---

## Timeline Summary

| Day | Tasks | Hours |
|-----|-------|-------|
| 1 | Prerequisites, Developer enrollment, Icons start | 3-4 |
| 2 | Godot export, Device testing, Icons finish | 3-4 |
| 3 | App Store Connect setup, Screenshots | 4-6 |
| 4 | Build, Upload, Submit | 2-3 |
| 5-7 | Wait for review, fix if rejected | Variable |

**Total effort:** ~15-20 hours active work
**Total calendar time:** 5-7 days (including review)

---

## Cost Summary

| Item | Cost | Notes |
|------|------|-------|
| Apple Developer Program | $99/year | Required |
| Icon design (DIY) | $0 | Use existing tools |
| Icon design (professional) | $50-200 | Optional |
| Screenshot tools | $0 | Figma free tier |
| **Total (minimum)** | **$99** | |

---

## Post-Launch

After approval:
1. **Announce** on social media
2. **Request reviews** from early players
3. **Monitor** crash reports in App Store Connect
4. **Update** with fixes based on feedback
5. **Iterate** based on analytics

---

## Files Updated By This Analysis

This analysis consolidates and extends:
- `mvp.md` - MVP feature requirements
- `GTM_STRATEGY.md` - Launch strategy
- `MASTER_TODO.md` - Distribution checklist
- `ipad_export.md` - Technical export guide

Next step: Start with **Phase 1.1** - fix xcode-select.
