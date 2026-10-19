import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'app_state.dart';
import 'l10n/l10n.dart';
import 'pages/explore_page.dart';
import 'pages/home_page.dart';
import 'pages/map_page.dart';
import 'pages/saved_page.dart';
import 'pages/schengen_page.dart';
import 'pages/settings_page.dart';
import 'pages/welcome_page.dart';
import 'platform_integration.dart';
import 'reminder_service.dart';
import 'theme.dart';
import 'widgets.dart';
import 'visa_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerLicenses();
  final repo = await VisaRepository.load();
  final state = await AppState.load();
  state.cleanUp(repo.data);
  ReminderService.attach(state);
  PlatformIntegration.attach(state, repo);
  runApp(StamplyApp(state: state, repo: repo));
}

/// Shows the font and data licenses on the "Licenses" screen.
void _registerLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['Passport Index Data'],
      await rootBundle.loadString('assets/data/LICENSE-data.txt'),
    );
    yield LicenseEntryWithLineBreaks(
      ['Unicode CLDR (country names)'],
      await rootBundle.loadString('assets/data/LICENSE-cldr.txt'),
    );
    yield LicenseEntryWithLineBreaks(
      ['Space Grotesk'],
      await rootBundle.loadString('assets/fonts/OFL-SpaceGrotesk.txt'),
    );
    yield LicenseEntryWithLineBreaks(
      ['IBM Plex Sans'],
      await rootBundle.loadString('assets/fonts/OFL-IBMPlexSans.txt'),
    );
  });
}

class StamplyApp extends StatelessWidget {
  const StamplyApp({super.key, required this.state, required this.repo});

  final AppState state;
  final VisaRepository repo;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      repo: repo,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final language = state.languageCode;
          // Dates (DateFormat) follow the app language.
          Intl.defaultLocale = language;
          return MaterialApp(
            // A fresh key after the welcome screen clears every open page.
            key: ValueKey(state.onboarded),
            title: 'Stamply',
            debugShowCheckedModeBanner: false,
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: state.themeMode,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            // On tablets and foldables keep the phone-style layout centered.
            builder: (context, child) => AppBackground(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: child,
                ),
              ),
            ),
            home: state.onboarded ? const HomeShell() : WelcomePage(state: state),
          );
        },
      ),
    );
  }
}

/// Bottom navigation with the four tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openShortcut();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _openShortcut();
  }

  /// Opens the screen chosen with a long-press app shortcut, if any.
  Future<void> _openShortcut() async {
    final shortcut = await PlatformIntegration.consumeShortcut();
    if (!mounted || shortcut == null) return;
    switch (shortcut) {
      case PlatformIntegration.shortcutCheck:
        setState(() => _index = 0);
      case PlatformIntegration.shortcutExplore:
        setState(() => _index = 1);
      case PlatformIntegration.shortcutMap:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage()));
      case PlatformIntegration.shortcutSchengen:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SchengenPage()));
    }
  }

  static const _pages = [HomePage(), ExplorePage(), SavedPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: _NavBar(
            index: _index,
            onChanged: (i) => setState(() => _index = i),
            items: [
              (Icons.task_alt, l.navCheck),
              (Icons.travel_explore, l.navExplore),
              (Icons.bookmark_border, l.navSaved),
              (Icons.tune, l.navSettings),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating soft bottom bar. The open tab sinks into the bar.
class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onChanged, required this.items});

  final int index;
  final ValueChanged<int> onChanged;
  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    final extra = StamplyColors.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final reduce = MediaQuery.of(context).disableAnimations;
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 320);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: extra.base,
        borderRadius: BorderRadius.circular(36),
        boxShadow: Neu.shadows(extra),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
        height: 72,
        child: Row(
          children: [
            for (final (i, item) in items.indexed)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == index,
                  label: item.$2,
                  child: Tooltip(
                    message: item.$2,
                    child: InkResponse(
                      onTap: () => onChanged(i),
                      radius: 34,
                      child: Center(
                        child: SizedBox(
                          width: 54,
                          height: 54,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedScale(
                                scale: i == index ? 1 : 0.4,
                                duration: duration,
                                curve: Curves.easeOutBack,
                                child: AnimatedOpacity(
                                  opacity: i == index ? 1 : 0,
                                  duration: duration,
                                  child: CustomPaint(
                                    size: const Size.square(54),
                                    painter: InsetPainter(colors: extra, radius: 27, depth: 0.8),
                                  ),
                                ),
                              ),
                              AnimatedScale(
                                scale: i == index ? 1.08 : 1,
                                duration: duration,
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  item.$1,
                                  size: 26,
                                  color: i == index ? accent : extra.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}
