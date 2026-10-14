import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

/// Android: opens the share sheet without an extra plugin (MainActivity.kt,
/// same channel as the other Lumio apps).
/// Windows and other desktops: copies the text and opens the picture in the
/// default image viewer, from where it can be copied or sent.
class ShareService {
  static const _channel = MethodChannel('lumio/share');

  static Future<void> shareText(String text) {
    if (Platform.isAndroid) return _channel.invokeMethod<void>('shareText', {'text': text});
    return Clipboard.setData(ClipboardData(text: text));
  }

  /// Shares a PNG that lives in the app cache folder.
  static Future<void> shareImage(String path, String text) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('shareImage', {'path': path, 'text': text});
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    await OpenFilex.open(path);
  }
}
