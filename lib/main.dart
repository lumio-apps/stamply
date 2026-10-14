import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'app_state.dart';
import 'l10n/l10n.dart';
import 'pages/explore_page.dart';
import 'pages/home_page.dart';
import 'pages/saved_page.dart';
import 'pages/settings_page.dart';
import 'pages/welcome_page.dart';
import 'theme.dart';
import 'visa_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerLicenses();
  final repo = await VisaRepository.load();
  final state = await AppState.load();
  state.cleanUp(repo.data);
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

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [HomePage(), ExplorePage(), SavedPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: const Icon(Icons.task_alt),
            label: l.navCheck,
          ),
          NavigationDestination(
            icon: const Icon(Icons.travel_explore_outlined),
            selectedIcon: const Icon(Icons.travel_explore),
            label: l.navExplore,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_border),
            selectedIcon: const Icon(Icons.bookmark),
            label: l.navSaved,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.navSettings,
          ),
        ],
      ),
    );
  }
}
