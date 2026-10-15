import 'package:flutter/services.dart';

/// Opens the Android share sheet without an extra plugin (MainActivity.kt,
/// same channel as the other Lumio apps).
class ShareService {
  static const _channel = MethodChannel('lumio/share');

  static Future<void> shareText(String text) =>
      _channel.invokeMethod<void>('shareText', {'text': text});

  /// Shares a PNG that lives in the app cache folder.
  static Future<void> shareImage(String path, String text) =>
      _channel.invokeMethod<void>('shareImage', {'path': path, 'text': text});
}
