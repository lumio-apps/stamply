import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../passport_validity.dart';
import '../reminder_service.dart';
import '../theme.dart';
import '../visa_repository.dart';
import '../widgets.dart';
import 'language_list.dart';

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
    final l = context.l10n;
    setState(() => _updating = true);
    final result = await scope.repo.refresh();
    if (!mounted) return;
    setState(() => _updating = false);
    if (result == DataRefreshResult.updated) scope.state.cleanUp(scope.repo.data);
    final text = switch (result) {
      DataRefreshResult.updated => l.dataUpdated(scope.repo.data.version),
      DataRefreshResult.upToDate => l.dataUpToDate,
      DataRefreshResult.failed => l.dataFailed,
    };
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggleReminder(AppState state, bool on) async {
    if (!on) {
      state.setExpiryReminder(false);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final denied = context.l10n.reminderDenied;
    final allowed = await ReminderService.requestPermission();
    if (allowed) {
      state.setExpiryReminder(true);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(denied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final data = scope.repo.data;
    final extra = StamplyColors.of(context);
    final l = context.l10n;
    final brightness = Theme.of(context).brightness;
    final expiry = state.passportExpiry;
    final validity = expiry == null ? null : PassportValidity.check(expiry, DateTime.now());

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(l.settingsTitle, style: Theme.of(context).textTheme.headlineMedium),
          SectionLabel(l.appearance),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l.themeSystem),
                  icon: const Icon(Icons.brightness_auto)),
              ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l.themeLight),
                  icon: const Icon(Icons.light_mode_outlined)),
              ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l.themeDark),
                  icon: const Icon(Icons.dark_mode_outlined)),
            ],
            selected: {state.themeMode},
            onSelectionChanged: (s) => state.setThemeMode(s.first),
          ),
          SectionLabel(l.language),
          CardBox(child: LanguageTile(state: state)),
          SectionLabel(l.myPassport),
          CardBox(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_available_outlined, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expiry == null
                                ? l.passportExpiryDate
                                : l.expiresOn(DateFormat.yMMMd().format(expiry)),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          if (validity != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: validity.tone.background(brightness),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                validity.summary(l),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: validity.tone.foreground(brightness),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  validity?.advice(l) ?? l.expiryEmptyAdvice,
                  style: TextStyle(fontSize: 14, height: 1.5, color: extra.muted),
                ),
                if (expiry != null && ReminderService.supported) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: state.expiryReminder,
                    onChanged: (on) => _toggleReminder(state, on),
                    title: Text(l.reminderSwitch),
                    subtitle: Text(l.reminderSwitchHint),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => pickPassportExpiry(context, state),
                        child: Text(expiry == null ? l.addExpiryDate : l.changeDate),
                      ),
                    ),
                    if (expiry != null) ...[
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => state.setPassportExpiry(null),
                        child: Text(l.remove),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SectionLabel(l.visaData),
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
                          Text(l.dataFrom(data.version),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(
                            '${l.dataCountries(data.countries.length)} · '
                            '${scope.repo.usingDownloadedData ? l.dataDownloaded : l.dataBuiltIn}',
                            style: TextStyle(fontSize: 13, color: extra.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l.dataExplain,
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
                  label: Text(_updating ? l.updating : l.updateData),
                ),
              ],
            ),
          ),
          SectionLabel(l.about),
          CardBox(
            child: Column(
              children: [
                ListTile(
                  leading: const StamplyLogo(size: 36),
                  title: const Text('Stamply – Visa Checker',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_appVersion.isEmpty ? 'Lumio Apps' : '${l.appVersion(_appVersion)} · Lumio Apps'),
                ),
                Divider(height: 1, color: extra.divider),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l.privacy),
                  subtitle: Text(l.privacySummary),
                ),
                Divider(height: 1, color: extra.divider),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l.licensesAndData),
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
            l.disclaimerSettings,
            style: TextStyle(fontSize: 13, height: 1.5, color: extra.muted),
          ),
        ],
      ),
    );
  }
}
