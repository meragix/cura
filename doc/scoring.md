# Scoring Algorithm

## Overview

Cura calculates a health score from 0 to 100 for each package based on four
weighted dimensions, plus bonuses and penalties applied on top:

```text
Total Score = Vitality (40) + Technical Health (30) + Trust (20) + Maintenance (10)
            + Bonuses (variable) + Penalties (variable)
            clamped to [0, 100]
```

---

## Dimensions

### 1. Vitality — 40 pts

Vitality reflects the recency and frequency of package updates.

| Last update  | Base points |
|--------------|-------------|
| ≤ 1 month    | 40          |
| 1–3 months   | 35          |
| 3–6 months   | 28          |
| 6–12 months  | 20          |
| 1–2 years    | 10          |
| > 2 years    | 0           |

**Stability bonus (+5 pts):** Applies to packages 6+ months old that meet all of the following criteria:

- Pana score ≥ 130/130, **and**
- Popularity > 70 %, **and**
- Version is a stable `1.x+` release (no pre-release suffix)

OR when the package is published by a [trusted publisher](#trusted-publisher-floor).

**GitHub activity bonus (+5 pts):** Applies when the repository recorded more
than 10 commits in the last 90 days (requires GitHub data to be available).

**Examples:**

| Last published | GitHub 90d commits | Points |
|----------------|--------------------|--------|
| 45 days ago    | 5                  | 35     |
| 45 days ago    | 25                 | 40     |
| 7 months ago   | —                  | 20     |
| 2.5 years ago  | —                  | 0      |

---

### 2. Technical Health — 30 pts

Technical Health evaluates code quality, language compliance, and platform coverage.

#### a) Pana score — 0–15 pts

```dart
int panaPortion = (panaScore / 130 * 15).round().clamp(0, 15);
```

pub.dev's Pana analysis grants points up to a max of 130. Cura normalises
that to 15 pts.

| Pana score | Points |
|------------|--------|
| 130        | 15     |
| 100        | 11     |
| 50         | 5      |

#### b) Null safety — 10 pts

Packages that opt in to sound null safety receive the full 10 pts.

#### c) Dart 3 compatibility — 3 pts

Awarded when the package is tagged `is:dart3-compatible` on pub.dev.

#### d) Platform breadth — 0–2 pts

One point per supported platform beyond the first, capped at 2.

```dart
score += (pkg.supportedPlatforms.length - 1).clamp(0, 2);
```

| Platforms supported | Points |
|---------------------|--------|
| 3 or more           | 2      |
| 2                   | 1      |
| 1                   | 0      |

**Full example:**

```text
Pana 130/130    →  15 pts
Null safe       →  10 pts
Dart 3 compat   →   3 pts
3 platforms     →   2 pts
──────────────────────────
Technical total =  30 / 30
```

---

### 3. Trust — 20 pts

Trust reflects community adoption and download activity.

#### a) Pub.dev likes — 0–10 pts

```dart
int likeScore = (likes / 1000 * 10).round().clamp(0, 10);
```

| Likes    | Points |
|----------|--------|
| ≥ 1 000  | 10     |
| 500      | 5      |
| 100      | 1      |

#### b) Download popularity — 0–10 pts

```dart
int popScore = (popularity / 100 * 10).round().clamp(0, 10);
```

pub.dev's download-based popularity metric mapped to a 0–100 scale.

| Popularity | Points |
|------------|--------|
| 100 %      | 10     |
| 50 %       | 5      |
| 10 %       | 1      |

#### c) GitHub stars bonus — +3 pts

Awarded when the repository has more than 1 000 stars (requires GitHub data).

**Full example:**

```text
3 200 likes      →  10 pts  (capped)
98 % popularity  →  10 pts
> 1 000 stars    →   3 pts
────────────────────────────
Trust total      =  23 / 23  (clamped to 20 by weight normalisation)
```

---

### 4. Maintenance — 10 pts

Maintenance reflects official backing and recognition.

#### a) Verified publisher — 5 pts

Packages published under a verified domain (e.g. `dart.dev`, `flutter.dev`)
receive 5 pts.

#### b) Flutter Favorite badge — 5 pts

The official Flutter Favorite designation grants 5 pts.

---

## Penalties

Penalties are subtracted from the raw dimension total **after** all four
dimensions are summed. The result is then clamped to `[0, 100]`.

| Condition                                       | Deduction |
|-------------------------------------------------|-----------|
| No source repository linked                     | −30 pts   |
| Experimental `0.0.x` version stalled > 1 year  | −20 pts   |

A package with no repository and an experimental stalled version loses up
to 50 pts, which typically pushes the score below the critical threshold (< 50).

---

## Trusted Publisher Floor

Packages published by a trusted first-party publisher (e.g. `dart.dev`,
`flutter.dev`) receive a **score floor of 70**: their composite score is
clamped to `[70, 100]` rather than `[0, 100]`.

This is a **floor**, not an exemption:

- Trusted publishers still go through full dimension scoring.
- Penalties still apply (a Google package with no repository loses 30 pts).
- [Red flags](#red-flags) are still detected and surfaced to the user.
- The [zero-score overrides](#zero-score-overrides) below take precedence.
  A discontinued or critically vulnerable trusted-publisher package still
  scores 0.

---

## Zero-Score Overrides

The following conditions **override all other criteria** and force the score to
exactly 0 (grade F), regardless of any dimension score, bonus, or trusted-publisher
floor:

1. **Package is discontinued** — tagged `is:discontinued` on pub.dev.
2. **Critical security vulnerability** — at least one CVE with
   `severity == critical` detected via OSV.dev with no known patch.

---

## Red Flags

Red flags are qualitative risk signals that complement the numeric score.
They are evaluated for every package, including trusted-publisher packages.
Each flag carries a typed severity level:

| Severity   | Meaning                                     |
|------------|---------------------------------------------|
| `critical` | Immediate risk; action or avoidance required|
| `warning`  | Elevated risk; review recommended           |
| `info`     | Worth monitoring                            |

| Flag                         | Severity | Condition                                            |
|------------------------------|----------|------------------------------------------------------|
| `StalePackageFlag`           | warning  | No release in > 18 months on a non-stable package   |
| `LimitedPlatformSupportFlag` | info     | Fewer than 3 supported platforms                    |
| `UnverifiedPublisherFlag`    | warning  | No verified publisher on pub.dev                    |
| `MissingRepositoryFlag`      | critical | No source repository URL                            |
| `SuboptimalPanaScoreFlag`    | info     | Pana score < 100/130                                |
| `ExperimentalVersionFlag`    | warning  | Version starts with `0.0.`                          |
| `NoNullSafetyFlag`           | critical | Does not opt in to sound null safety                |
| `NewPackageFlag`             | info     | Tagged `is:recent` — limited track record           |
| `NotDart3CompatibleFlag`     | warning  | Not tagged `is:dart3-compatible`                    |
| `NotWasmReadyFlag`           | info     | Web package not tagged `is:wasm-ready`              |
| `MissingLicenseFlag`         | critical | No SPDX license detected — legal risk (priority)   |
| `MultipleRisksFlag`          | critical | ≥ 3 flags on an unverified package                  |

`MissingLicenseFlag` is a priority legal-risk signal: any package without a
detectable SPDX license requires legal review before commercial use.

`MultipleRisksFlag` is prepended to the list when three or more individual
flags are present on an unverified package, providing a single top-level
signal for downstream tooling.

---

## Recommendations

Recommendations are typed, prioritised, actionable guidance derived from
the score and red flags. Each recommendation has a level:

| Level      | Meaning                                          |
|------------|--------------------------------------------------|
| `critical` | Do not use in production without resolution      |
| `warning`  | Review required before production use            |
| `action`   | Specific investigation step recommended          |
| `advisory` | General guidance, low urgency                    |

Key recommendation rules (in priority order):

1. **Score ≥ 80** → single `advisory` "Verified health — suitable for production use"
2. **`MultipleRisksFlag`** → `critical` AVOID + `action` to find alternatives (early exit)
3. **`MissingLicenseFlag`** → `critical` legal review warning (surfaced first)
4. **`MissingRepositoryFlag`** → `critical` cannot audit source code
5. **`StalePackageFlag`** (non-stable) → `warning` seek alternatives
6. **`ExperimentalVersionFlag`** → `warning` wait for 1.0.0
7. **`NewPackageFlag`** → `advisory` monitor for breaking changes
8. **`NotWasmReadyFlag`** → `advisory` fallback bundle-size note

---

## Grade Mapping

Grades are derived from the final `total` score after all dimension scores,
bonuses, penalties, and the trusted-publisher floor are applied.

| Score range | Grade | Meaning                      |
|-------------|-------|------------------------------|
| 90–100      | A+    | Excellent, production-ready  |
| 80–89       | A     | Very good, recommended       |
| 70–79       | B     | Good, safe to use            |
| 60–69       | C     | Fair, use with caution       |
| 50–59       | D     | Poor, consider alternatives  |
| 0–49        | F     | Critical, avoid              |

---

## Complete Example

**Package:** `riverpod` v2.4.9

```bash
Input data
  Last published : 45 days ago
  GitHub 90d     : 32 commits
  Pana score     : 130 / 130
  Null safe      : yes
  Dart 3 compat  : yes
  Platforms      : android, ios, web, linux, macos, windows  (6)
  Likes          : 1 250
  Popularity     : 98 %
  GitHub stars   : 4 800
  Publisher      : riverpod.dev  (verified)
  Flutter Fav    : no
  Repository     : yes
  License        : MIT

Calculation
  Vitality
    45 days                  →  35 pts (base)
    32 commits (90d)         →  +5 pts (activity bonus)
                             ─────────
                             =  40 / 40

  Technical health
    Pana 130/130             →  15 pts
    Null safe                →  10 pts
    Dart 3 compatible        →   3 pts
    6 platforms → 5 beyond 1 → +2 pts (capped)
                             ─────────
                             =  30 / 30

  Trust
    1 250 likes              →  10 pts  (capped)
    98% popularity           →  10 pts
    4 800 stars (> 1 000)    →  +3 pts  (bonus)
    Weight normalisation     →  cap 20
                             ─────────
                             =  20 / 20

  Maintenance
    Publisher: riverpod.dev  →   5 pts
    Flutter Fav: no          →   0 pts
                             ─────────
                             =   5 / 10

  Penalties
    Repository: yes          →   0
    Version: 2.4.9           →   0
                             ─────────
                             =   0

  ════════════════════════════
  TOTAL = 40 + 30 + 20 + 5 + 0 = 95 / 100
  GRADE = A+
  Red flags = none
```

---

## Architecture Notes

The scoring engine uses the **Strategy pattern**: each dimension
(`VitalityDimension`, `TechnicalHealthDimension`, `TrustDimension`,
`MaintenanceDimension`) is an independent class implementing the
`ScoringDimension` interface. The `CalculateScore` orchestrator delegates
to them and composes the final `Score`.

Adding a new scoring dimension requires only:

1. Implementing `ScoringDimension`
2. Injecting it via `CalculateScore.withDimensions()`

No modification of the orchestrator is needed (Open/Closed Principle).

Input data is passed as a Dart **Record** (`ScoringInput`):

```dart
typedef ScoringInput = ({
  PackageInfo package,
  GitHubMetrics? github,
  List<Vulnerability> vulnerabilities,
});
```

This makes dimension unit tests trivial — no mocking framework needed for
the input side.

---

## Related

- [Configuration reference](configuration.md) — full config key list
- [API integration](api-integration.md) — where the raw data comes from
- [Caching](caching.md) — how results are stored between runs
- [Architecture](architecture.md) — hexagonal architecture and DI wiring
