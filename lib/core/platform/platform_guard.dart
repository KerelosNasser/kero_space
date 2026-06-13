import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

bool get isMobile {
  if (kIsWeb) return true; // Could be mobile web, but we'll default to standard handling
  return Platform.isAndroid || Platform.isIOS;
}
