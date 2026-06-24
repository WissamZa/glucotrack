// Platform guard for BLE sync.
//
// flutter_blue_plus supports: Android, iOS, macOS, Windows.
// It does NOT support: Linux desktop or Web.
//
// This helper provides a single place to check at runtime rather than
// scattering kIsWeb / Platform checks across the UI code.
import 'package:flutter/foundation.dart';

bool get isBleSupported {
  if (kIsWeb) return false;
  // Use defaultTargetPlatform — available on all platforms, no dart:io needed.
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return true;
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return false;
  }
}

/// Human-readable reason why BLE is not supported on this platform.
/// Returns null when [isBleSupported] is true.
String? get bleUnsupportedReason {
  if (isBleSupported) return null;
  if (kIsWeb) {
    return 'Web Bluetooth is not supported by this app. '
        'Please use the Android or iOS app to sync your meter.';
  }
  return 'Bluetooth LE sync is not available on Linux desktop. '
      'Please use GlucoTrack on Android or iOS to sync your '
      'OneTouch Select Plus Flex meter.';
}
