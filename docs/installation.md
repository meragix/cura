
# Installation

## Prerequisites

- **Dart SDK** ≥ 3.0.0
- **Git** (for development)

## Quick Install

Activate Cura globally via pub:

```bash
dart pub global activate cura_cli
```

Verify installation:

```bash
cura --version
# Output: cura version 0.1.0
```

## Alternative: Local Installation

For development or testing:

```bash
git clone https://github.com/yourusername/cura.git
cd cura
melos bootstrap
dart pub global activate --source path packages/cura_cli
```

## Troubleshooting

### Command Not Found

If `cura` is not recognized, ensure your PATH includes pub cache:

**macOS/Linux:**

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

Add to `~/.bashrc`, `~/.zshrc`, or equivalent.

**Windows:**

```powershell
$env:Path += ";$env:USERPROFILE\AppData\Local\Pub\Cache\bin"
```

### Permission Denied (macOS/Linux)

```bash
chmod +x ~/.pub-cache/bin/cura
```

### Dart SDK Not Found

Install Dart via:

- [dart.dev/get-dart](https://dart.dev/get-dart)
- Or use Flutter SDK (includes Dart)

## Updating

```bash
dart pub global activate cura_cli
```

This automatically fetches the latest version from pub.dev.

## Uninstalling

```bash
dart pub global deactivate cura_cli
```
