
# Core Concepts

Understanding how Cura evaluates package health.

## The Health Score

Cura assigns each package a **0-100 point score** based on four pillars:

### 1. Maintenance Score (40 points max)

**What it measures:** How recently the package was updated.

| Last Release | Points | Status |
|--------------|--------|--------|
| < 6 months | 40 | ✅ Active |
| < 12 months | 20 | ⚠️ Moderate |
| 18+ months | 0 | ❌ Legacy |

**Exception:** Packages with 130+ pub points and 0.7+ popularity are considered **stable** and receive full 40 points regardless of age.

**Why?** Mature packages like `path_provider` don't need frequent updates.

---

### 2. Trust Score (30 points max)

**What it measures:** Publisher credibility.

| Criteria | Points |
|----------|--------|
| Verified publisher (any) | +20 |
| Flutter Favorite badge | +10 |
| Trusted publisher (dart.dev, flutter.dev, google.dev) | 30 (auto-max) |

**Why?** Official packages bypass all scoring and get 100/100 automatically.

---

### 3. Popularity Score (20 points max)

**What it measures:** Balance of popularity vs technical health.

```dart
score = (grantedPoints / maxPoints) * popularityScore * 20
```

**Example:**

- Package A: 140/140 points, 0.9 popularity → 18/20
- Package B: 70/140 points, 0.95 popularity → 9.5/20 (popular but low quality)

**Why?** Prevents "hype-driven" packages with poor maintenance from scoring high.

---

### 4. Penalties (up to -65 points)

**Red flags that trigger penalties:**

| Red Flag | Penalty |
|----------|---------|
| README < 300 chars + unverified publisher | -30 |
| No repository link | -30 |
| Version 0.0.x for 12+ months | -20 |
| README < 300 chars (verified publisher) | -15 |

**Combined Example:**

```
Package X:
  - Maintenance: 20 (12 months old)
  - Trust: 0 (unverified)
  - Popularity: 10
  - Penalties: -30 (no repo) -30 (minimal docs + unverified)
  
Total: 20 + 0 + 10 - 60 = -30 → Clamped to 0
Final Score: 0/100 ❌
```

---

## Trusted Publishers Whitelist

Packages from these publishers **automatically receive 100/100**:

- `dart.dev`
- `flutter.dev`
- `google.dev`
- `firebase.google.com`

**Why?** These are official, maintained by Google/Dart team.

---

## Stability Detection

A package is considered **stable** if:

1. `grantedPoints >= 130` (out of 140 max)
2. `popularityScore > 0.7`

**Effect:** No penalty for lack of recent updates.

**Example:**

```
path_provider:
  - Last update: 620 days ago
  - Pub points: 135/140
  - Popularity: 0.98
  
Result: Treated as stable → 40/40 maintenance score ✅
```

---

## Vibe Code Detection

A package is flagged as **"VIBE CODE PROBABLE"** if:

```dart
redFlags.length >= 3 && !hasVerifiedPublisher
```

**Typical vibe code profile:**

- Version 0.0.1 for 12+ months
- No repository link
- README < 300 characters
- Unverified publisher

**Recommendation:** ❌ Avoid entirely.

---

## Cache System

### How It Works

1. First request → Fetch from pub.dev API
2. Store in `~/.cura/.cura_cache.json` with timestamp
3. Subsequent requests within 24h → Use cache
4. After 24h → Refresh from API

### Cache Entry Structure

```json
{
  "dio": {
    "packageInfo": { ... },
    "cachedAt": "2026-01-22T10:30:00Z"
  }
}
```

### Why Cache?

- **Respects pub.dev rate limits** (~100-200 req/min)
- **Speeds up repeated analyses** (cache hit <50ms)
- **Offline capability** (partial, for cached packages)

---

## Concurrency Control

Cura uses a **semaphore pattern** to limit concurrent API requests:

```dart
maxConcurrentRequests = 5
```

**Why?** Prevents overwhelming pub.dev with 50+ simultaneous requests.

**Effect:** Analyzing 50 packages takes ~10-15 seconds instead of 2-3 seconds, but avoids rate limiting.

---
