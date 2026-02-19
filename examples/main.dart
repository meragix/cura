/// Example: Simple check of a Dart/Flutter project
///
/// This demonstrates the most basic usage of Cura:
/// checking all dependencies in a pubspec.yaml file.

import 'dart:io';

void main() async {
  print('🔍 Cura - Simple Check Example\n');

  // Ensure we're in a Dart/Flutter project
  if (!await File('pubspec.yaml').exists()) {
    print('❌ Error: pubspec.yaml not found');
    print('Run this example from a Dart/Flutter project directory.');
    exit(1);
  }

  print('Running: cura check\n');
  print('─' * 50);

  // Execute cura scan
  final result = await Process.run(
    'cura',
    ['check'],
    runInShell: true,
  );

  print(result.stdout);

  if (result.exitCode != 0) {
    print(result.stderr);
    exit(result.exitCode);
  }

  print('─' * 50);
  print('\n✅ Check completed!\n');
  print('💡 Tips:');
  print('  • Use --verbose for detailed output');
  print('  • Use --json for machine-readable output');
  print('  • Use cura view <package> for detailed info');
}
