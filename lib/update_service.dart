import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'l10n/l10n.dart';

/// Checks GitHub Releases for a newer APK and installs it inside the app.
class UpdateService {
  static const _latestReleaseUrl =
      'https://api.github.com/repos/lumio-apps/stamply/releases/latest';

  /// Shows the full "Check for updates" flow with dialogs.
  static Future<void> checkForUpdates(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    messenger.showSnackBar(
      SnackBar(content: Text(l.updChecking), duration: const Duration(seconds: 1)),
    );

    try {
      final info = await PackageInfo.fromPlatform();
      final res = await http
          .get(Uri.parse(_latestReleaseUrl), headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('Server returned ${res.statusCode}');

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final latestTag = (data['tag_name'] as String? ?? '').trim();
      final latest = latestTag.replaceFirst(RegExp(r'^[vV]'), '');
      final notes = (data['body'] as String? ?? '').trim();
      final assets = (data['assets'] as List? ?? []).cast<Map<String, dynamic>>();
      final apk = assets.where((a) => (a['name'] as String? ?? '').endsWith('.apk')).firstOrNull;

      if (!context.mounted) return;

      if (latest.isEmpty || !_isNewer(latest, info.version) || apk == null) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text(l.updLatest(info.version))),
        );
        return;
      }

      final install = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.updAvailable(latestTag)),
          content: SingleChildScrollView(
            child: Text(
              '${l.updCurrent(info.version)}\n\n'
              '${notes.isEmpty ? l.updReady : notes}',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.updLater)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.updUpdate)),
          ],
        ),
      );
      if (install != true || !context.mounted) return;

      await _downloadAndInstall(context, apk['browser_download_url'] as String, l);
    } catch (_) {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(l.updCheckFailed)),
      );
    }
  }

  static Future<void> _downloadAndInstall(
    BuildContext context,
    String url,
    AppLocalizations l,
  ) async {
    final progress = ValueNotifier<double?>(null);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(l.updDownloading),
          content: ValueListenableBuilder<double?>(
            valueListenable: progress,
            builder: (ctx, value, child) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: value),
                const SizedBox(height: 12),
                Text(value == null ? l.updStarting : '${(value * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ),
        ),
      ),
    );

    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(url)));
      if (response.statusCode != 200) throw Exception('Download failed');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Stamply-update.apk');
      final sink = file.openWrite();
      final total = response.contentLength ?? 0;
      var received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) progress.value = received / total;
      }
      await sink.close();

      navigator.pop();
      final result = await OpenFilex.open(file.path, type: 'application/vnd.android.package-archive');
      if (result.type != ResultType.done) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.updInstallerFailed(result.message))),
        );
      }
    } catch (_) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l.updDownloadFailed)),
      );
    } finally {
      client.close();
      progress.dispose();
    }
  }

  /// Returns true if [latest] (e.g. "1.2.0") is newer than [current].
  static bool _isNewer(String latest, String current) {
    List<int> parse(String v) =>
        v.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final a = parse(latest);
    final b = parse(current);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}
