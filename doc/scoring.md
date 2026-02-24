# Scoring Algorithm

## Overview

Cura calculates a **health score from 0 to 100** for each package based on four
weighted dimensions:

```
Total Score = Vitality (40) + Technical Health (30) + Trust (20) + Maintenance (10)
```

---

## Dimensions

### 1. Vitality — 40 pts

Measures how actively maintained the package is.

```dart
int calculateVitality(DateTime lastPublished) {
  final daysSince = DateTime.now().difference(lastPublished).inDays;

  if (daysSince <= 30)  return 40; // updated this month
  if (daysSince <= 90)  return 35; // updated this quarter
  if (daysSince <= 180) return 28; // updated this semester
  if (daysSince <= 365) return 20; // updated this year
  if (daysSince <= 730) return 10; // updated in last 2 years
  return 0;                        // abandoned (> 2 years)
}
```

**Stable-package exception:** A package with a Pana score > 130, popularity
> 0.9, and a verified publisher receives a +5 bonus even when older, because it
has a proven track record.

**Examples:**

| Last published  | Points |
|-----------------|--------|
| 45 days ago     |     35 |
| 7 months ago    |     20 |
| 2.5 years ago   |      0 |

---

### 2. Technical Health — 30 pts

Evaluates code quality and platform coverage.

#### a) Pana score — 15 pts

```dart
int panaPortion = (panaScore / 130 * 15).round();
```

pub.dev's Pana analysis produces a score on a 0–140 scale. Cura normalises
it to 15 points.

| Pana score  | Points |
|-------------|--------|
| 130 / 140   |     15 |
| 100 / 140   |     11 |
|  50 / 140   |      5 |

#### b) Null safety — 10 pts

Packages that support null safety receive the full 10 points.

#### c) Platform support — 5 pts

One point per supported platform, capped at 5.

| Platforms supported | Points |
|---------------------|--------|
| 5 or more           |      5 |
| 3                   |      3 |
| 1                   |      1 |

**Total example:**

```
Pana 120 / 140  →  13 pts
Null safe       →  10 pts
4 platforms     →   4 pts
──────────────────────────
Technical total =  27 / 30
```

---

### 3. Trust — 20 pts

Measures community confidence and adoption.

#### a) Likes — 10 pts

```dart
int likeScore = (likes / 1000 * 10).round().clamp(0, 10);
```

| Likes     | Points |
|-----------|--------|
| >= 1 000  |     10 |
| 500       |      5 |
| 100       |      1 |

#### b) Popularity — 10 pts

```dart
int popScore = (popularity / 100 * 10).round().clamp(0, 10);
```

pub.dev's download-based popularity metric (0–100).

| Popularity | Points |
|------------|--------|
| 100 %      |     10 |
| 50 %       |      5 |
| 10 %       |      1 |

**Total example:**

```
3 200 likes      →  10 pts  (capped)
98 % popularity  →  10 pts
────────────────────────────
Trust total      =  20 / 20
```

---

### 4. Maintenance — 10 pts

Indicates official backing and long-term reliability.

#### a) Verified publisher — 5 pts

Packages published by a verified domain (e.g. `dart.dev`, `flutter.dev`) receive
5 points.

#### b) Flutter Favorite badge — 5 pts

The official Flutter Favorite designation grants 5 points.

**Total example:**

```
Publisher: dart.dev  →  5 pts
Flutter Favorite: v  →  5 pts
──────────────────────────────
Maintenance total    = 10 / 10
```

---

## Automatic Score of 0

The following conditions override all other criteria and force the score to 0:

1. **Package is discontinued** — tagged `is:discontinued` on pub.dev
2. **Critical security vulnerability** — a CVE with severity CRITICAL or HIGH
   detected via OSV.dev

These are deal-breakers regardless of how high the package otherwise scores.

---

## Grade Mapping

| Score range | Grade | Meaning                         |
|-------------|-------|---------------------------------|
| 90–100      | A+    | Excellent — production ready    |
| 80–89       | A     | Very good — highly recommended  |
| 70–79       | B     | Good — safe to use              |
| 60–69       | C     | Fair — use with caution         |
| 50–59       | D     | Poor — consider alternatives    |
| 0–49        | F     | Critical — avoid                |

---

## Complete Example

**Package:** `riverpod` v2.4.9

```
Input data
  Last published : 45 days ago
  Pana score     : 130 / 140
  Null safe      : yes
  Platforms      : android, ios, web, macos, windows, linux  (6)
  Likes          : 1 250
  Popularity     : 98 %
  Publisher      : riverpod.dev  (verified)
  Flutter Fav    : no

Calculation
  Vitality        45 days  →  35 / 40

  Technical health
    Pana 130/140  →  15 pts
    Null safe     →  10 pts
    6 platforms   →   5 pts
                  ─────────
                  = 30 / 30

  Trust
    1 250 likes    →  10 pts
    98% popularity →  10 pts
                   ─────────
                   = 20 / 20

  Maintenance
    Publisher v    →   5 pts
    FF badge x     →   0 pts
                   ─────────
                   =  5 / 10

  ════════════════════════════
  FINAL SCORE = 90 / 100  (A+)
```

---

## Related

- [Configuration reference](configuration.md) — full config key list
- [API integration](api-integration.md) — where the raw data comes from
- [Caching](caching.md) — how results are stored between runs
