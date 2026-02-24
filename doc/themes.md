# Theme Customization

Cura ships with three built-in themes that control terminal colors and symbols.
The active theme is applied globally before any output is printed.

---

## Available Themes

| Theme     | Description                                        |
|-----------|----------------------------------------------------|
| `dark`    | Default. Vibrant ANSI colors on dark backgrounds.  |
| `light`   | Softer palette suited to light terminal backgrounds.|
| `minimal` | Monochrome. Safe for CI logs and color-blind users. |

---

## Selecting a Theme

### Persist the choice globally

```bash
cura config set theme minimal
```

The value is written to `~/.cura/config.yaml` and used by every subsequent
command until changed.

### Override for a single run

```bash
cura check --theme light
```

CLI flags always take precedence over config files.

### Project-scoped theme

Commit a project config to lock the theme for the whole team:

```yaml
# ./.cura/config.yaml
theme: minimal
```

---

## Theme Details

### dark (default)

Designed for dark terminal backgrounds (iTerm2, Windows Terminal, Ghostty).

```
Score  92  A+   ████████████████████  Healthy
Score  68  C    ███████████░░░░░░░░░  Warning
Score  25  F    █████░░░░░░░░░░░░░░░  Critical
```

Colors used: cyan (header), green (healthy), yellow (warning), red (critical),
magenta (accents).

---

### light

Designed for light terminal backgrounds (macOS default Terminal, some SSH
clients).

Same information layout as `dark` with adjusted foreground brightness so text
remains readable on white/cream backgrounds.

---

### minimal

Monochrome — no ANSI color codes are emitted.

Recommended for:

- CI/CD log viewers (GitHub Actions, GitLab CI)
- Terminals without color support
- Piping output to files or other tools

```
Score  92  A+   ||||||||||||||||||||  Healthy
Score  68  C    |||||||||||.........  Warning
Score  25  F    |||||...............  Critical
```

Symbols replace color indicators so the output remains meaningful without color.

---

## CI/CD Recommendation

Set `minimal` in your project config for consistent, readable pipeline logs:

```yaml
# ./.cura/config.yaml
theme: minimal
use_colors: false
```

Or set it inline:

```bash
cura check --theme minimal --min-score 80
```

---

## Related

- [Configuration reference](configuration.md) — all config keys
- [CI/CD integration](ci-cd.md) — pipeline setup
