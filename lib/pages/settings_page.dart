import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_state.dart';
import '../theme.dart';
import '../update_service.dart';
import '../visa_repository.dart';
import '../widgets.dart';

/// "Settings" tab: theme, visa data updates and app info.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _updating = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  Future<void> _updateData() async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _updating = true);
    final result = await scope.repo.refresh();
    if (!mounted) return;
    setState(() => _updating = false);
    if (result == DataRefreshResult.updated) scope.state.cleanUp(scope.repo.data);
    final text = switch (result) {
      DataRefreshResult.updated => 'Visa data updated to ${scope.repo.data.version}.',
      DataRefreshResult.upToDate => 'You already have the latest visa data.',
      DataRefreshResult.failed => 'Could not update. Check your internet connection and try again.',
    };
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final data = scope.repo.data;
    final extra = StamplyColors.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SectionLabel('Appearance'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
            ],
            selected: {state.themeMode},
            onSelectionChanged: (s) => state.setThemeMode(s.first),
          ),
          const SectionLabel('Visa data'),
          CardBox(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.dataset_outlined, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Data from ${data.version}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(
                            '${data.countries.length} countries · '
                            '${scope.repo.usingDownloadedData ? 'downloaded update' : 'built into the app'}',
                            style: TextStyle(fontSize: 13, color: extra.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Stamply works offline. Tap below to download the latest visa data file '
                  'from GitHub. No account, and no personal data is sent.',
                  style: TextStyle(fontSize: 14, height: 1.5, color: extra.muted),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _updating ? null : _updateData,
                  icon: _updating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: Text(_updating ? 'Updating…' : 'Update data'),
                ),
              ],
            ),
          ),
          const SectionLabel('About'),
          CardBox(
            child: Column(
              children: [
                ListTile(
                  leading: const StamplyLogo(size: 36),
                  title: const Text('Stamply – Visa Checker',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_appVersion.isEmpty ? 'Lumio Apps' : 'Version $_appVersion · Lumio Apps'),
                ),
                if (kSelfUpdate) ...[
                  Divider(height: 1, color: extra.divider),
                  ListTile(
                    leading: const Icon(Icons.system_update_outlined),
                    title: const Text('Check for updates'),
                    onTap: () => UpdateService.checkForUpdates(context),
                  ),
                ],
                Divider(height: 1, color: extra.divider),
                const ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Privacy'),
                  subtitle: Text('No ads, no tracking, no account. Your checks stay on this device.'),
                ),
                Divider(height: 1, color: extra.divider),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Licenses and data source'),
                  subtitle: Text(data.source),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Stamply',
                    applicationVersion: _appVersion,
                    applicationIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: StamplyLogo(size: 56),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Stamply gives general guidance only. Visa rules change often — always confirm '
            'with the embassy or official government website before you travel.',
            style: TextStyle(fontSize: 13, height: 1.5, color: extra.muted),
          ),
        ],
      ),
    );
  }
}
