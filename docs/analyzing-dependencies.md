
# Analyzing Dependencies

Learn how to use Cura to audit your project's dependencies.

## Basic Usage

### Analyze a Single Package

```bash
cura view 
```

**Example:**

```bash
cura view dio
```

**Output includes:**

- Overall health score
- Breakdown by category
- Red flags (if any)
- Recommendations

---

## Understanding Output

### Healthy Package Example

```
📦 dio (v5.4.0)

Score: 95/100 ✅ HEALTHY

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Breakdown:
  Maintenance:  40/40 ✅
  Trust:        30/30 ✅
  Popularity:   20/20 ✅
  Penalties:     0/0  ✅
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status: ✅ Recommended for production
```

**Interpretation:**

- This package is actively maintained
- Published by a verified source
- High technical quality
- Safe to use

---

### Warning Package Example

```
📦 some_package (v1.2.0)

Score: 65/100 ⚠️ WARNING

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Breakdown:
  Maintenance:  20/40 ⚠️ (380 days)
  Trust:        20/30 ⚠️ (verified, not Flutter Favorite)
  Popularity:   15/20 ✅
  Penalties:   -10/0  ⚠️
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Red Flags:
  ⚠️  No release in 12+ months
  📄 Minimal documentation (180 chars)

Recommendations:
  ⚠️  Use with caution - Monitor for updates
  🔍 Check GitHub for active issues/PRs
```

**Interpretation:**

- Package hasn't been updated in a year
- Documentation is sparse
- Still usable but needs monitoring

---

### Critical Package Example

```
📦 abandoned_pkg (v0.0.1)

Score: 15/100 ❌ CRITICAL

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Breakdown:
  Maintenance:   0/40 ❌ (650 days)
  Trust:         0/30 ❌
  Popularity:    5/20 ⚠️
  Penalties:   -50/0  ❌
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Red Flags:
  🚨 VIBE CODE PROBABLE - Package suspect
  ⚠️  No release in 21+ months (Legacy)
  🔓 Unverified publisher
  🚫 No repository link
  📄 Minimal documentation (45 chars)
  🧪 Experimental version (0.0.1)

Recommendations:
  ❌ AVOID: Likely test/experimental package
  🔍 Seek maintained alternative
```

**Interpretation:**

- DO NOT USE in production
- Likely abandoned or a test package
- Find an alternative immediately

---

## Common Patterns

### 1. Stable But Old Packages

**Example:** `path_provider` (last update 18 months ago)

```
Score: 95/100 ✅ HEALTHY

Why? → 135/140 pub points + 0.98 popularity
       = Treated as stable
```

**Action:** Safe to use. Maturity ≠ Abandonment.

---

### 2. Popular But Low Quality

**Example:** Viral package with 0.95 popularity but 70/140 pub points

```
Score: 55/100 ⚠️ WARNING

Why? → High popularity × Low health ratio
       = Likely hype-driven
```

**Action:** Investigate further. Check GitHub issues.

---

### 3. Official Packages

**Example:** Any package from `dart.dev`

```
Score: 100/100 ✅ HEALTHY

Why? → Trusted publisher auto-whitelist
```

**Action:** Always safe to use.

---

## Best Practices

### 1. Regular Audits

Run Cura monthly:

```bash
# In your project directory
cura check  # (Available in v0.2+)
```

### 2. Pre-Dependency Addition

Before adding a new dependency:

```bash
cura view new_package_name
```

**Decision Matrix:**

| Score | Action |
|-------|--------|
| 80+ | ✅ Add confidently |
| 50-79 | ⚠️ Evaluate alternatives first |
| <50 | ❌ Find better option |

### 3. Cache Management

For critical decisions, bypass cache:

```bash
cura view package_name --skip-cache
```

This ensures latest data from pub.dev.

---

## Troubleshooting

### Package Not Found

```
❌ Error: Package "nonexistent_pkg" not found on pub.dev
```

**Possible causes:**

- Typo in package name
- Package removed from pub.dev
- Private/unpublished package

---

### Rate Limit Error

```
⚠️  Warning: pub.dev rate limit approached
   Slowing down requests...
```

**Cura automatically:**

- Queues requests
- Respects 5-concurrent limit
- Uses cache when available

**Action:** None required (handled automatically)

---
