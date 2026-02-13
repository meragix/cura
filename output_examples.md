# Cura --verbose Output Examples

## Example 1: Healthy Package (dio)

```bash
cura view dio --verbose
```

**Output:**

```
🔍 Analyzing package: dio
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[CACHE CHECK]
✅ Cache hit for 'dio'
   Cached at: 2026-01-30 10:15:32 UTC
   Age: 2 hours 14 minutes
   Status: VALID (< 24 hours)

[PACKAGE METADATA]
📦 Name:              dio
   Version:           5.4.0
   Published:         2024-01-15 10:00:00 UTC
   Days since update: 380 days
   
   Publisher:         dart.dev
   Publisher verified: YES ✅
   Trusted publisher:  YES ✅ (whitelisted)
   Flutter Favorite:   NO
   
   Repository:        https://github.com/cfug/dio
   Repository valid:   YES ✅
   
   Description:       "A powerful HTTP client for Dart/Flutter, which supports..."
   Description length: 1247 characters ✅

[PUB.DEV METRICS]
   Granted points:     135 / 140
   Health ratio:       96.4% ✅
   Popularity score:   0.99 ✅
   Likes:              2847

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[SCORING CALCULATION]

1️⃣ MAINTENANCE SCORE (Max: 40 points)
   Days since release: 380
   Threshold check:
   • < 180 days (6 months)?    NO
   • < 365 days (12 months)?   NO
   • Stability exception?      YES ✅
     └─ Granted points (135) >= 130 ✅
     └─ Popularity (0.99) > 0.7 ✅
   
   Calculation:
   • Base score: 0 (> 12 months)
   • Stability bonus: +40 (stable package detected)
   
   Final: 40/40 ✅

2️⃣ TRUST SCORE (Max: 30 points)
   Publisher: dart.dev
   Trusted whitelist: YES ✅
   
   Calculation:
   • Trusted publisher: 30 (auto-max)
   
   Final: 30/30 ✅

3️⃣ POPULARITY SCORE (Max: 20 points)
   Health ratio: 0.964 (135/140)
   Popularity: 0.99
   
   Calculation:
   • Trusted publisher: 20 (auto-max)
   
   Final: 20/20 ✅

4️⃣ PENALTIES (Max: -65 points)
   Trusted publisher: YES ✅
   
   Penalty checks:
   • No repository?              NO ✅
   • Minimal docs (<300 chars)?  NO ✅
   • Version 0.0.x (>12 months)? NO ✅
   
   Final: 0/0 ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[TOTAL SCORE]
   Maintenance:  40
   Trust:        30
   Popularity:   20
   Penalties:     0
   ─────────────────
   TOTAL:        90/100 ✅

   Status: HEALTHY (80-100 range)

[RED FLAGS]
   None detected ✅

[RECOMMENDATIONS]
   ✅ Recommended for production use
   ✅ Official dart.dev package - Safe to use
   ✅ Actively maintained and stable

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[API CALLS]
   Total requests: 0 (cache hit)
   Time taken: 45ms

✅ Analysis complete
```

---

## Example 2: Critical Package (Vibe Code)

```bash
cura view abandoned_test_pkg --verbose
```

**Output:**

```
🔍 Analyzing package: abandoned_test_pkg
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[CACHE CHECK]
❌ Cache miss for 'abandoned_test_pkg'
   Fetching from pub.dev API...

[API REQUEST]
   URL: https://pub.dev/api/packages/abandoned_test_pkg
   Method: GET
   Status: 200 OK
   Response time: 342ms

[PACKAGE METADATA]
📦 Name:              abandoned_test_pkg
   Version:           0.0.1
   Published:         2022-06-10 08:23:15 UTC
   Days since update: 965 days ⚠️
   
   Publisher:         null
   Publisher verified: NO ❌
   Trusted publisher:  NO ❌
   Flutter Favorite:   NO
   
   Repository:        null
   Repository valid:   NO ❌
   
   Description:       "A test package"
   Description length: 45 characters ⚠️ (< 300 threshold)

[PUB.DEV METRICS]
   Granted points:     35 / 140
   Health ratio:       25.0% ❌
   Popularity score:   0.02 ❌
   Likes:              1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[SCORING CALCULATION]

1️⃣ MAINTENANCE SCORE (Max: 40 points)
   Days since release: 965
   Threshold check:
   • < 180 days (6 months)?    NO ❌
   • < 365 days (12 months)?   NO ❌
   • Stability exception?      NO ❌
     └─ Granted points (35) < 130 ❌
     └─ Popularity (0.02) < 0.7 ❌
   
   Calculation:
   • Base score: 0 (> 18 months = LEGACY)
   
   Final: 0/40 ❌

2️⃣ TRUST SCORE (Max: 30 points)
   Publisher: null
   Trusted whitelist: NO ❌
   
   Calculation:
   • Verified publisher: 0 (null)
   • Flutter Favorite: 0 (not awarded)
   
   Final: 0/30 ❌

3️⃣ POPULARITY SCORE (Max: 20 points)
   Health ratio: 0.250 (35/140)
   Popularity: 0.02
   
   Calculation:
   • Formula: healthRatio × popularity × 20
   • Score: 0.250 × 0.02 × 20 = 0.1
   • Rounded: 0
   
   Final: 0/20 ❌

4️⃣ PENALTIES (Max: -65 points)
   Trusted publisher: NO ❌
   
   Penalty checks:
   
   ⚠️  PENALTY 1: Minimal documentation + Unverified publisher
       • Description length: 45 < 300
       • Publisher: null (unverified)
       • Penalty: -30 points
   
   ⚠️  PENALTY 2: No repository link
       • Repository: null
       • Cannot audit source code
       • Penalty: -30 points
   
   ⚠️  PENALTY 3: Experimental version (0.0.x) stale
       • Version: 0.0.1
       • Days since release: 965 > 365
       • Likely abandoned test package
       • Penalty: -20 points
   
   Total penalties: -80
   Clamped to max: -65
   
   Final: -65/0 ❌

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[TOTAL SCORE]
   Maintenance:   0
   Trust:         0
   Popularity:    0
   Penalties:   -65
   ─────────────────
   TOTAL:        0/100 ❌ (clamped from -65)

   Status: CRITICAL (0-49 range)

[RED FLAGS] 🚨
   🚨 VIBE CODE PROBABLE - Package suspect
      └─ 3+ red flags detected with unverified publisher
   
   ⚠️  No release in 32+ months (LEGACY)
      └─ 965 days since last update
   
   🔓 Unverified publisher
      └─ Publisher field is null
   
   🚫 No repository link
      └─ Cannot audit source code
   
   📄 Minimal documentation
      └─ README only 45 characters (threshold: 300)
   
   🧪 Experimental version (0.0.1)
      └─ Never reached stable release

[RECOMMENDATIONS]
   ❌ AVOID: Likely test/experimental package
   🔍 Seek maintained alternative with verified publisher
   ⚠️  This package shows all signs of "vibe code"
   💡 Check pub.dev for similar packages with higher scores

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[API CALLS]
   Total requests: 1
   Time taken: 387ms
   Cached: YES (expires in 24 hours)

❌ Analysis complete - AVOID this package
```

---

## Example 3: Warning Package (Borderline)

```bash
cura view some_old_lib --verbose
```

**Output:**

```
🔍 Analyzing package: some_old_lib
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[CACHE CHECK]
✅ Cache hit for 'some_old_lib'
   Cached at: 2026-01-29 16:42:18 UTC
   Age: 17 hours 33 minutes
   Status: VALID (< 24 hours)

[PACKAGE METADATA]
📦 Name:              some_old_lib
   Version:           2.1.0
   Published:         2023-08-20 14:30:00 UTC
   Days since update: 528 days ⚠️
   
   Publisher:         developer.io
   Publisher verified: YES ✅
   Trusted publisher:  NO ❌
   Flutter Favorite:   NO
   
   Repository:        https://github.com/dev/some_old_lib
   Repository valid:   YES ✅
   
   Description:       "A library for doing X, Y, and Z with Flutter apps"
   Description length: 185 characters ⚠️ (< 300 threshold)

[PUB.DEV METRICS]
   Granted points:     95 / 140
   Health ratio:       67.9% ⚠️
   Popularity score:   0.55 ⚠️
   Likes:              342

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[SCORING CALCULATION]

1️⃣ MAINTENANCE SCORE (Max: 40 points)
   Days since release: 528
   Threshold check:
   • < 180 days (6 months)?    NO ❌
   • < 365 days (12 months)?   NO ❌
   • Stability exception?      NO ❌
     └─ Granted points (95) < 130 ❌
     └─ Popularity (0.55) < 0.7 ❌
   
   Calculation:
   • Base score: 0 (> 12 months, not stable)
   
   Final: 0/40 ❌
   
   ⚠️  NOTE: Close to 18-month legacy threshold (12 days away)

2️⃣ TRUST SCORE (Max: 30 points)
   Publisher: developer.io
   Trusted whitelist: NO
   
   Calculation:
   • Verified publisher: +20
   • Flutter Favorite: 0 (not awarded)
   
   Final: 20/30 ⚠️

3️⃣ POPULARITY SCORE (Max: 20 points)
   Health ratio: 0.679 (95/140)
   Popularity: 0.55
   
   Calculation:
   • Formula: healthRatio × popularity × 20
   • Score: 0.679 × 0.55 × 20 = 7.47
   • Rounded: 7
   
   Final: 7/20 ⚠️

4️⃣ PENALTIES (Max: -65 points)
   Trusted publisher: NO
   
   Penalty checks:
   
   ⚠️  PENALTY: Minimal documentation (verified publisher)
       • Description length: 185 < 300
       • Publisher IS verified: -15 (lighter penalty)
       • Penalty: -15 points
   
   ✅ No repository penalty (link exists)
   ✅ No experimental version penalty (v2.1.0 is stable)
   
   Total penalties: -15
   
   Final: -15/0 ⚠️

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[TOTAL SCORE]
   Maintenance:   0
   Trust:        20
   Popularity:    7
   Penalties:   -15
   ─────────────────
   TOTAL:        12/100 ⚠️

   Status: CRITICAL (0-49 range)

[RED FLAGS]
   ⚠️  No release in 17+ months
      └─ 528 days since last update
      └─ Approaching legacy threshold (540 days)
   
   🔓 Unverified publisher (but verified account exists)
   
   📄 Minimal documentation
      └─ README only 185 characters

[RECOMMENDATIONS]
   ⚠️  Use with caution - Package may be abandoned
   🔍 Check repository for recent activity (commits, issues, PRs)
   💡 Consider alternatives with more recent updates
   📧 Contact maintainer if this is critical to your project

[ADDITIONAL INFO]
   ⚠️  STABILITY WARNING:
       This package scored low (12/100) but has a verified publisher.
       
       Before avoiding completely:
       • Check GitHub: https://github.com/dev/some_old_lib
       • Look for recent commits/activity
       • Review open issues (any blocking bugs?)
       • Check if maintainer is responsive
       
       Package may be:
       • Stable and feature-complete (no updates needed)
       • Quietly abandoned (maintainer moved on)
       
       Decision: Your call based on repository investigation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[API CALLS]
   Total requests: 0 (cache hit)
   Time taken: 38ms

⚠️  Analysis complete - Exercise caution
```

---

## Example 4: Stable Old Package (path_provider)

```bash
cura view path_provider --verbose
```

**Output:**

```
🔍 Analyzing package: path_provider
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[CACHE CHECK]
❌ Cache miss for 'path_provider'
   Fetching from pub.dev API...

[API REQUEST]
   URL: https://pub.dev/api/packages/path_provider
   Method: GET
   Status: 200 OK
   Response time: 278ms

[PACKAGE METADATA]
📦 Name:              path_provider
   Version:           2.1.1
   Published:         2023-05-12 09:15:00 UTC
   Days since update: 628 days ⚠️
   
   Publisher:         flutter.dev
   Publisher verified: YES ✅
   Trusted publisher:  YES ✅ (whitelisted)
   Flutter Favorite:   YES ✅
   
   Repository:        https://github.com/flutter/packages/tree/main/packages/path_provider
   Repository valid:   YES ✅
   
   Description:       "Flutter plugin for getting commonly used locations on host platform file systems..."
   Description length: 892 characters ✅

[PUB.DEV METRICS]
   Granted points:     138 / 140
   Health ratio:       98.6% ✅
   Popularity score:   0.98 ✅
   Likes:              5243

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[SCORING CALCULATION]

1️⃣ MAINTENANCE SCORE (Max: 40 points)
   Days since release: 628
   Threshold check:
   • < 180 days (6 months)?    NO ❌
   • < 365 days (12 months)?   NO ❌
   • Stability exception?      YES ✅
     └─ Granted points (138) >= 130 ✅
     └─ Popularity (0.98) > 0.7 ✅
   
   Calculation:
   • Base score: 0 (> 18 months normally)
   • Stability bonus: +40 (STABLE PACKAGE DETECTED)
   
   🎯 STABILITY REASONING:
      This package is mature and feature-complete.
      High pub points (138/140) + high popularity (0.98) indicate:
      • Well-maintained codebase
      • Comprehensive tests
      • Good documentation
      • Wide adoption
      
      Lack of recent updates is NOT a red flag here.
      It means the package is STABLE, not DEAD.
   
   Final: 40/40 ✅

2️⃣ TRUST SCORE (Max: 30 points)
   Publisher: flutter.dev
   Trusted whitelist: YES ✅
   
   Calculation:
   • Trusted publisher: 30 (auto-max)
   • Flutter Favorite: Already included
   
   Final: 30/30 ✅

3️⃣ POPULARITY SCORE (Max: 20 points)
   Health ratio: 0.986 (138/140)
   Popularity: 0.98
   
   Calculation:
   • Trusted publisher: 20 (auto-max)
   
   Final: 20/20 ✅

4️⃣ PENALTIES (Max: -65 points)
   Trusted publisher: YES ✅
   
   Penalty checks: SKIPPED
   └─ Trusted publishers exempt from penalties
   
   Final: 0/0 ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[TOTAL SCORE]
   Maintenance:  40 ✅ (stability exception applied)
   Trust:        30 ✅ (official Flutter package)
   Popularity:   20 ✅ (auto-max for trusted)
   Penalties:     0 ✅ (exempt)
   ─────────────────
   TOTAL:        90/100 ✅

   Status: HEALTHY (80-100 range)

[RED FLAGS]
   None detected ✅
   
   Note: 628 days without update is NORMAL for this package.
         It's a sign of maturity, not abandonment.

[RECOMMENDATIONS]
   ✅ HIGHLY RECOMMENDED for production use
   ✅ Official Flutter package (flutter.dev)
   ✅ Stable, mature, and widely adopted
   ✅ Part of Flutter's official plugin ecosystem
   
   💡 This is an example of a "stable" package:
      • No recent updates = No bugs to fix
      • High quality maintained over time
      • Trusted by millions of Flutter apps

[ADDITIONAL INFO]
   🎓 LEARNING MOMENT:
      
      This package demonstrates why Cura uses STABILITY DETECTION:
      
      Without it:
      • 628 days old → 0/40 maintenance score
      • Total score: 50/100 (WARNING)
      • FALSE NEGATIVE ❌
      
      With stability detection:
      • High pub points (138) + High popularity (0.98)
      • Recognized as mature, not dead
      • Total score: 90/100 (HEALTHY) ✅
      
      Lesson: Age ≠ Abandonment for high-quality packages

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[API CALLS]
   Total requests: 1
   Time taken: 315ms
   Cached: YES (expires in 24 hours)

✅ Analysis complete - Safe to use
```

---

## Key Elements in --verbose Mode

### 1. **Cache Information**

- Hit/Miss status
- Age of cached data
- Validity check

### 2. **Detailed Metadata**

- All package properties
- Calculated thresholds
- Boolean checks with emojis

### 3. **Step-by-Step Scoring**

- Each category broken down
- Formula shown
- Intermediate calculations
- Reasoning for exceptions

### 4. **Penalty Breakdown**

- Each penalty listed separately
- Amount per penalty
- Total and clamping shown

### 5. **Educational Content**

- "Learning moments" for edge cases
- Reasoning behind decisions
- Context for scores

### 6. **Performance Metrics**

- API calls made
- Time taken
- Cache status

This verbose mode is designed for:

- Debugging false positives/negatives
- Understanding scoring logic
- Educating users on package health
- Transparency in decision-making
