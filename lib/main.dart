import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'pages/explore_page.dart';
import 'pages/home_page.dart';
import 'pages/saved_page.dart';
import 'pages/settings_page.dart';
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
        builder: (context, _) => MaterialApp(
          title: 'Stamply',
          debugShowCheckedModeBanner: false,
          themeMode: state.themeMode,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          home: const HomeShell(),
        ),
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
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Check',
          ),
          NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(Icons.travel_explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
