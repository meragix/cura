# Scoring Algorithm

## Overview

Cura calculates a **health score from 0-100** for each package, based on 4 weighted criteria:

```
Total Score = Vitality (40) + Technical Health (30) + Trust (20) + Maintenance (10)
```

## Detailed Breakdown

### 1. Vitality (40 points)

**Measures:** How actively maintained the package is

**Logic:**

```dart
int calculateVitality(DateTime lastPublished) {
  final daysSince = DateTime.now().difference(lastPublished).inDays;
  
  if (daysSince <= 30)   return 40;  // Updated this month
  if (daysSince <= 90)   return 35;  // Updated this quarter
  if (daysSince <= 180)  return 28;  // Updated this semester
  if (daysSince <= 365)  return 20;  // Updated this year
  if (daysSince <= 730)  return 10;  // Updated in last 2 years
  return 0;                          // Abandoned (>2 years)
}
```

**Example:**

- Package updated 45 days ago → **35 points**
- Package updated 400 days ago → **10 points**

**Special Cases:**

**Stable Package Exception:**
If a package has:

- Pana score > 130
- Popularity > 0.9
- Verified publisher

Then it receives **+5 bonus** points even if old, because it's proven stable.

---

### 2. Technical Health (30 points)

**Measures:** Code quality and platform support

**Components:**

#### a) Pana Score (15 points)

```dart
int panaPortion = (panaScore / 130 * 15).round();
```

Pana (Package Analysis) is pub.dev's official quality metric (0-130).

**Example:**

- Pana 130/130 → **15 points**
- Pana 100/130 → **11 points**
- Pana 50/130 → **5 points**

#### b) Null Safety (10 points)

```dart
if (isNullSafe) score += 10;
```

Packages supporting null safety get full 10 points.

#### c) Platform Support (5 points)

```dart
int platforms = supportedPlatforms.length.clamp(0, 5);
```

**Example:**

- Supports 5+ platforms (Android, iOS, Web, macOS, Windows) → **5 points**
- Supports 2 platforms → **2 points**

**Total Example:**

```
Pana 120/130  →  13 pts
Null Safe     →  10 pts
4 platforms   →   4 pts
────────────────────────
Total         =  27/30
```

---

### 3. Trust (20 points)

**Measures:** Community confidence and adoption

**Components:**

#### a) Likes (10 points)

```dart
int likeScore = (likes / 1000 * 10).round().clamp(0, 10);
```

**Scale:**

- 1000+ likes → **10 points**
- 500 likes → **5 points**
- 100 likes → **1 point**

#### b) Popularity (10 points)

```dart
int popScore = (popularity / 100 * 10).round().clamp(0, 10);
```

Popularity is pub.dev's download-based metric (0-100).

**Scale:**

- 100% popularity → **10 points**
- 50% popularity → **5 points**
- 10% popularity → **1 point**

**Total Example:**

```
3,200 likes        →  10 pts (capped)
98% popularity     →  10 pts
──────────────────────────
Total              =  20/20
```

---

### 4. Maintenance (10 points)

**Measures:** Official support and reliability

**Components:**

#### a) Verified Publisher (5 points)

```dart
if (publisherId != null && publisherId.isNotEmpty) {
  score += 5;
}
```

Packages from verified publishers (dart.dev, flutter.dev, etc.) get 5 points.

#### b) Flutter Favorite (5 points)

```dart
if (isFlutterFavorite) {
  score += 5;
}
```

Official Flutter Favorite badge grants 5 points.

**Total Example:**

```
Publisher: dart.dev     →  5 pts
Flutter Favorite: ✓     →  5 pts
─────────────────────────────
Total                   = 10/10

## Penalties

### Automatic Score of 0

The following conditions result in an **automatic score of 0**:

1. **Package is discontinued**
   ```yaml
   tags: ["is:discontinued"]
   ```

1. **Critical security vulnerability**
   - Detected via OSV.dev
   - Severity: CRITICAL or HIGH

**Rationale:** These are deal-breakers that override all other criteria.

---

## Grade Mapping

| Score Range | Grade | Badge | Meaning |
|-------------|-------|-------|---------|
| 90-100 | A+ | 🟢 | Excellent - Production ready |
| 80-89 | A | 🟢 | Very good - Highly recommended |
| 70-79 | B | 🟡 | Good - Safe to use |
| 60-69 | C | 🟡 | Fair - Use with caution |
| 50-59 | D | 🟠 | Poor - Consider alternatives |
| 0-49 | F | 🔴 | Critical - Avoid |

---

## Complete Example

**Package:** `riverpod` v2.4.9

### Raw Data

```yaml
last_published: 45 days ago
pana_score: 130/130
is_null_safe: true
platforms: [android, ios, web, macos, windows, linux]
likes: 1,250
popularity: 98%
publisher: riverpod.dev
is_flutter_favorite: false
```

### Calculation

```
Vitality:
  45 days ago → 35/40

Technical Health:
  Pana 130/130    → 15/15
  Null Safe       → 10/10
  6 platforms     →  5/5
  ────────────────────
  Total           = 30/30

Trust:
  1,250 likes     → 10/10
  98% popularity  → 10/10
  ────────────────────
  Total           = 20/20

Maintenance:
  Publisher ✓     →  5/5
  FF Badge ✗      →  0/5
  ────────────────────
  Total           =  5/10

═══════════════════════════
FINAL SCORE = 90/100 (A+)
```

---

## Customizing Weights

You can customize the scoring weights in your config:

```yaml
# ~/.cura/config.yaml
score_weights:
  vitality: 30           # -10 from default
  technical_health: 30   # same
  trust: 20              # same
  maintenance: 20        # +10 from default
```

**Rules:**

- Total must equal 100
- Each weight must be between 0 and 100

---

## Future Improvements

Planned enhancements to the algorithm:

- **Trend Analysis:** Score change over time
- **Breaking Changes Penalty:** Frequent major versions
- **Response Time:** Average time to close issues
- **Documentation Quality:** README completeness
- **Test Coverage:** From pub.dev analysis

**Vote on priorities:** [GitHub Discussions](https://github.com/your-org/cura/discussions)

---

## Related

- [Configuration](configuration.md) - Customize scoring weights
- [View Command](view.md) - See detailed score breakdown
