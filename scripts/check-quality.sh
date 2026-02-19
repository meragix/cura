#!/bin/bash
set -e

# Script pour vérifier la qualité avant commit

echo "🔍 Running quality checks..."

# 1. Format
echo "📝 Checking format..."
dart format --set-exit-if-changed .

# 2. Analyze
echo "🔍 Analyzing code..."
dart analyze --fatal-infos

# 3. Tests
echo "🧪 Running tests..."
dart test

# 4. Build
echo "🏗️ Testing build..."
dart compile exe bin/cura.dart -o build/cura-test

echo "✅ All checks passed!"
