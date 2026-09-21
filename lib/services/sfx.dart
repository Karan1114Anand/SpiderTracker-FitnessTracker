/// Sound effects, played natively through a small platform channel.
///
/// Every call is safe to make anywhere: with sound off, on the web preview,
/// or in tests (where no platform channel exists) it does nothing.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

abstract final class Sfx {
  static const MethodChannel _channel = MethodChannel('spidertracker/sfx');

  /// Mirrors the user's setting; the repository keeps it in sync.
  static bool enabled = true;

  static Future<void> thwip() => _play('thwip');
  static Future<void> levelUp() => _play('levelup');

  static Future<void> _play(String name) async {
    if (!enabled || kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('play', {'name': name});
    } catch (_) {
      // No native side (tests, web): silence is the right fallback.
    }
  }
}
