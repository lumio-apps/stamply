import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home_page.dart';
import 'result_page.dart';

/// "Saved" tab: trips the user bookmarked on the result screen.
class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final data = scope.repo.data;
    final extra = StamplyColors.of(context);
    final l = context.l10n;
    final changedCount = state.saved
        .where((c) => state.hasChanged(c, data.signature(c.passport, c.destination)))
        .length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(l.savedTitle, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            changedCount > 0 ? l.savedChanged(changedCount) : l.savedIntro,
            style: TextStyle(fontSize: 15, color: extra.muted),
          ),
          const SizedBox(height: 16),
          if (state.saved.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.bookmark_border, size: 48, color: extra.muted),
                  const SizedBox(height: 12),
                  Text(
                    l.savedEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: extra.muted),
                  ),
                ],
              ),
            )
          else
            CardBox(
              child: Column(
                children: [
                  for (final (i, check) in state.saved.indexed) ...[
                    if (i > 0) Divider(height: 1, color: extra.divider),
                    Dismissible(
                      key: ValueKey(check.key),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: AlignmentDirectional.centerEnd,
                        padding: const EdgeInsetsDirectional.only(end: 20),
                        color: Theme.of(context).colorScheme.error,
                        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onError),
                      ),
                      onDismissed: (_) => state.toggleSaved(check),
                      child: CheckTile(
                        check: check,
                        changed: state.hasChanged(check, data.signature(check.passport, check.destination)),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ResultPage(check: check)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
