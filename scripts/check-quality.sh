#!/bin/bash
set -e

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

echo "✅ All checks passed!"
