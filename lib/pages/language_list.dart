import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../theme.dart';

/// Every language the app has, with its own name. Used on the welcome screen
/// and in Settings. Tapping a row switches the app language right away.
class LanguageList extends StatelessWidget {
  const LanguageList({super.key, required this.state, this.shrinkWrap = false});

  final AppState state;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final extra = StamplyColors.of(context);
    final current = state.languageCode;
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: kLanguages.length,
      itemBuilder: (context, i) {
        final lang = kLanguages[i];
        final selected = lang.code == current;
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          selected: selected,
          selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
          title: Text(
            lang.nativeName,
            style: TextStyle(
              fontSize: 17,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: lang.code == 'en'
              ? null
              : Text(lang.englishName, style: TextStyle(color: extra.muted)),
          trailing: selected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
          onTap: () => state.setLanguage(lang.code),
        );
      },
    );
  }
}

/// Bottom sheet with the language list (Settings).
Future<void> showLanguageSheet(BuildContext context, AppState state) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => ListenableBuilder(
      listenable: state,
      builder: (ctx, _) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 8),
              child: Text(ctx.l10n.language, style: Theme.of(ctx).textTheme.titleLarge),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: LanguageList(state: state),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The row in Settings that shows the current language and opens the sheet.
class LanguageTile extends StatelessWidget {
  const LanguageTile({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.translate),
      title: Text(context.l10n.language),
      subtitle: Text(languageByCode(state.languageCode).nativeName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showLanguageSheet(context, state),
    );
  }
}
