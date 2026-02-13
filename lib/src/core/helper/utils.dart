import 'dart:io';

class HelperUtils {
  static String getHomeDirectory() {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE']!;
    } else {
      return Platform.environment['HOME']!;
    }
  }
}
