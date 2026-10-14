import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import '../widgets.dart';
import 'country_picker_page.dart';
import 'language_list.dart';

/// First launch: pick the language, then the passport. Both can be changed later.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.state});

  final AppState state;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _step = 0;
  String? _passport;

  void _finish({required bool save}) {
    if (save && _passport != null) widget.state.setPassport(_passport);
    widget.state.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final extra = StamplyColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: _step == 0 ? _languageStep(context, l, extra) : _passportStep(context, l, extra),
        ),
      ),
    );
  }

  Widget _languageStep(BuildContext context, AppLocalizations l, StamplyColors extra) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StamplyLogo(size: 56),
        const SizedBox(height: 20),
        Text(l.welcomeTitle, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(l.welcomeTagline, style: TextStyle(fontSize: 15, height: 1.5, color: extra.muted)),
        const SizedBox(height: 20),
        Text(l.chooseLanguage, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: ListenableBuilder(
            listenable: widget.state,
            builder: (context, _) => LanguageList(state: widget.state),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => setState(() => _step = 1),
            child: Text(l.next),
          ),
        ),
      ],
    );
  }

  Widget _passportStep(BuildContext context, AppLocalizations l, StamplyColors extra) {
    final scope = AppScope.of(context);
    final code = _passport;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: IconButton(
            onPressed: () => setState(() => _step = 0),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        const SizedBox(height: 8),
        Text(l.welcomePassportTitle, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(l.welcomePassportHint, style: TextStyle(fontSize: 15, height: 1.5, color: extra.muted)),
        const SizedBox(height: 24),
        CardBox(
          child: ListTile(
            onTap: () async {
              final picked = await pickCountry(context, title: l.myPassport, selected: code);
              if (picked != null) setState(() => _passport = picked);
            },
            leading: code == null
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: extra.divider,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add, color: extra.muted),
                  )
                : CountryBadge(code: code),
            title: Text(
              code == null ? l.chooseCountry : scope.nameOf(code),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: code == null ? extra.muted : null,
              ),
            ),
            subtitle: Text(l.myPassport, style: TextStyle(color: extra.muted)),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: code == null ? null : () => _finish(save: true),
            child: Text(l.getStarted),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: TextButton(onPressed: () => _finish(save: false), child: Text(l.skip)),
        ),
      ],
    );
  }
}
