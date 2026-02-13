
# Understanding Scores

Deep dive into Cura's scoring algorithm.

## Scoring Formula

```
Total Score = Maintenance + Trust + Popularity + Penalties
            = (0-40)      + (0-30) + (0-20)     + (-65 to 0)
            = 0-100 (clamped)
```

---

## 1. Maintenance Score (0-40 points)

### Algorithm

```dart
int calculateMaintenanceScore(PackageInfo pkg) {
  final days = daysSinceLastRelease;
  
  // Exception: Stable packages
  if (isStable(pkg)) return 40;
  
  // Normal scoring
  if (days < 180) return 40;   // < 6 months
  if (days < 365) return 20;   // < 12 months
  return 0;                     // 18+ months
}

bool isStable(PackageInfo pkg) {
  return pkg.grantedPoints >= 130 &&
         pkg.popularityScore > 0.7;
}
```

### Examples

| Package | Days Since Release | Pub Points | Popularity | Score | Reason |
|---------|-------------------|------------|------------|-------|--------|
| `dio` | 15 | 135 | 0.99 | 40 | Recent update |
| `path_provider` | 620 | 138 | 0.98 | 40 | Stable exception |
| `old_pkg` | 400 | 85 | 0.45 | 20 | Not stable, moderate age |
| `dead_pkg` | 650 | 50 | 0.20 | 0 | Abandoned |

---

## 2. Trust Score (0-30 points)

### Algorithm

```dart
int calculateTrustScore(PackageInfo pkg) {
  // Auto-max for trusted publishers
  if (isTrustedPublisher(pkg)) return 30;
  
  int score = 0;
  if (pkg.hasVerifiedPublisher) score += 20;
  if (pkg.isFlutterFavorite) score += 10;
  
  return score;
}

bool isTrustedPublisher(PackageInfo pkg) {
  return ['dart.dev', 'flutter.dev', 'google.dev']
      .contains(pkg.publisherId);
}
```

### Examples

| Publisher | Verified | Flutter Favorite | Score |
|-----------|----------|------------------|-------|
| `dart.dev` | ✅ | ✅ | 30 (auto) |
| `verified.io` | ✅ | ✅ | 30 |
| `verified.io` | ✅ | ❌ | 20 |
| `null` | ❌ | ❌ | 0 |

---

## 3. Popularity Score (0-20 points)

### Algorithm

```dart
int calculatePopularityScore(PackageInfo pkg) {
  if (isTrustedPublisher(pkg)) return 20;
  
  final healthRatio = pkg.grantedPoints / pkg.maxPoints;
  final popularity = pkg.popularityScore;
  
  return (healthRatio * popularity * 20).round().clamp(0, 20);
}
```

### Why This Formula?

**Goal:** Penalize packages that are popular but technically unhealthy.

**Example 1: High Quality + High Popularity**
```
Package A:
  grantedPoints: 135/140 (96% health)
  popularityScore: 0.95
  
Score: 0.96 * 0.95 * 20 = 18.24 → 18/20 ✅
```

**Example 2: Low Quality + High Popularity (Vibe Code)**
```
Package B:
  grantedPoints: 70/140 (50% health)
  popularityScore: 0.90
  
Score: 0.50 * 0.90 * 20 = 9 → 9/20 ⚠️
```

---

## 4. Penalties (-65 to 0 points)

### Algorithm

```dart
int calculatePenalties(PackageInfo pkg) {
  if (isTrustedPublisher(pkg)) return 0;
  
  int penalty = 0;
  
  // Vibe code detection
  if (minimalDocs && unverifiedPublisher) {
    penalty -= 30;
  } else if (minimalDocs) {
    penalty -= 15;
  }
  
  // Experimental version
  if (version.startsWith('0.0.') && age > 365) {
    penalty -= 20;
  }
  
  // No repository
  if (noRepository) {
    penalty -= 30;
  }
  
  return penalty.clamp(-65, 0);
}
```

### Penalty Matrix

| Red Flag | Verified Publisher | Penalty |
|----------|-------------------|---------|
| README < 300 chars | No | -30 |
| README < 300 chars | Yes | -15 |
| No repository | Any | -30 |
| Version 0.0.x (12+ months) | Any | -20 |

### Maximum Penalty Example

```
Package X:
  - README: 50 chars (unverified) → -30
  - No repository                  → -30
  - Version 0.0.1 (18 months)      → -20
  
Total penalties: -80 → Clamped to -65
```

**Result:** Even with perfect other scores (40+30+20=90), this package maxes at **25/100** ❌

---

## Status Determination

```dart
HealthStatus determineStatus(int score) {
  if (score >= 80) return HealthStatus.healthy;
  if (score >= 50) return HealthStatus.warning;
  return HealthStatus.critical;
}
```

| Score | Status | Symbol | Meaning |
|-------|--------|--------|---------|
| 80-100 | Healthy | ✅ | Production-ready |
| 50-79 | Warning | ⚠️ | Use with caution |
| 0-49 | Critical | ❌ | Avoid or replace |

---

## Real-World Scoring Examples

### Example 1: `dio` (Healthy)

```yaml
Package: dio
Version: 5.4.0
Publisher: dart.dev
Last Update: 15 days ago
Pub Points: 135/140
Popularity: 0.99
Repository: ✅ https://github.com/cfug/dio
README: 1200+ chars
```

**Calculation:**
```
Maintenance: 40 (recent update)
Trust:       30 (trusted publisher)
Popularity:  20 (auto-max for trusted)
Penalties:    0 (no red flags)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total:       90/100 ✅ HEALTHY
```

---

### Example 2: `shared_preferences` (Warning)

```yaml
Package: shared_preferences
Version: 2.2.2
Publisher: flutter.dev
Last Update: 380 days ago
Pub Points: 140/140
Popularity: 0.95
Repository: ✅
README: 800+ chars
```

**Calculation:**
```
Maintenance: 40 (stable: 140pts + 0.95 popularity)
Trust:       30 (flutter.dev = trusted)
Popularity:  20 (auto-max)
Penalties:    0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total:       90/100 ✅ HEALTHY
```

**Note:** Despite 380 days without update, stability exception applies.

---

### Example 3: `some_old_package` (Critical)

```yaml
Package: some_old_package
Version: 0.0.1
Publisher: null (unverified)
Last Update: 650 days ago
Pub Points: 45/140
Popularity: 0.15
Repository: ❌ None
README: 85 chars
```

**Calculation:**
```
Maintenance:  0 (650 days, not stable)
Trust:        0 (no publisher)
Popularity:   2 (0.32 * 0.15 * 20 ≈ 2)
Penalties:  -65 (max)
  └─ Minimal docs + unverified: -30
  └─ No repository:             -30
  └─ Version 0.0.1 (650 days):  -20
     (clamped to -65)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total:        0/100 ❌ CRITICAL
```

**Flags:**
- 🚨 VIBE CODE PROBABLE
- ⚠️ Legacy (21+ months)
- 🔓 Unverified publisher
- 🚫 No repository
- 📄 Minimal docs

---

## Edge Cases & FAQ

### Q: Why does an old package get 90/100?

**A:** Stability exception applies when:
- Pub points ≥ 130
- Popularity > 0.7

These packages are **mature, not dead**.

---

### Q: Why penalize minimal docs for verified publishers?

**A:** Even verified publishers should document their packages. Penalty is lighter (-15 vs -30).

---

### Q: Can a package score above 100?

**A:** No. Total is clamped to 0-100 range.

```dart
total.clamp(0, 100)
```

---

### Q: What if pub.dev data is incomplete?

**A:** Default values are used:
- `grantedPoints`: 0
- `maxPoints`: 140
- `popularityScore`: 0.0

This results in lower scores, erring on the side of caution.

---

## Interpreting Complex Cases

### Case 1: High Popularity, Low Health

```
Package: viral_but_messy
  Popularity: 0.85
  Pub Points: 65/140
  
Popularity Score: (65/140) * 0.85 * 20 ≈ 8/20
```

**Interpretation:** Likely "hype-driven" package. Investigate before using.

---

### Case 2: Low Popularity, High Health

```
Package: niche_gem
  Popularity: 0.25
  Pub Points: 138/140
  
Popularity Score: (138/140) * 0.25 * 20 ≈ 5/20
```

**Interpretation:** High-quality but niche. Safe to use if it fits your needs.

---