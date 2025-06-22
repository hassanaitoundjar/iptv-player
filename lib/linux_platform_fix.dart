import 'package:flutter/foundation.dart';

/// A utility class to handle platform-specific behavior for Linux
class LinuxPlatformFix {
  /// Checks if the current platform is Linux
  static bool get isLinux => defaultTargetPlatform == TargetPlatform.linux;
}
