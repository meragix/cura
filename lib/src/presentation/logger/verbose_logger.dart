class VerboseLogger {
  void section(String title) {
    print('\n[$title]');
  }

  void detail(String key, String value, {bool success = true}) {
    final emoji = success ? '✅' : '❌';
    print('   $key: $value $emoji');
  }

  void calculation(String step, String result) {
    print('   • $step: $result');
  }
}
