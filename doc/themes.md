# Theme Customization

Cura provides three built-in themes that control terminal color output and
progress symbols. The active theme is applied globally before any output is
printed.

---

## Available Themes

| Theme     | Description                                          |
|-----------|------------------------------------------------------|
| `dark`    | Default theme. ANSI colors calibrated for dark terminals. |
| `light`   | Palette calibrated for light terminal backgrounds.   |
| `minimal` | Monochrome output. No ANSI color codes emitted.      |

---

## Selecting a Theme

### Global configuration

```bash
cura config set theme minimal
```

The value is written to `~/.cura/config.yaml` and applied to every subsequent
command until changed.

### Per-invocation override

```bash
cura check --theme light
```

CLI flags take precedence over config files.

### Project-level configuration

Commit a project config to enforce a consistent theme across the team:

```yaml
# ./.cura/config.yaml
theme: minimal
```

---

## Theme Details

### dark (default)

Calibrated for dark terminal backgrounds (iTerm2, Windows Terminal, Ghostty).

```text
Score  92  A+   ████████████████████  Healthy
Score  68  C    ███████████░░░░░░░░░  Warning
Score  25  F    █████░░░░░░░░░░░░░░░  Critical
```

Colors: cyan (header), green (healthy), yellow (warning), red (critical),
magenta (accents).

---

### light

Identical layout to `dark`. Foreground values adjusted for readability on
light terminal backgrounds.

---

### minimal

Monochrome — no ANSI color codes are emitted.

Suitable for:

- CI/CD log viewers (GitHub Actions, GitLab CI)
- Terminals without color support
- Piping output to files or other tools

```text
Score  92  A+   ||||||||||||||||||||  Healthy
Score  68  C    |||||||||||.........  Warning
Score  25  F    |||||...............  Critical
```

Symbols replace color indicators so the output remains meaningful without
color.

---

## CI/CD Recommendation

Set `minimal` in the project config for consistent, readable pipeline logs:

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
