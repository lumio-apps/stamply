import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home_page.dart';
import 'result_page.dart';

/// "Saved" tab: trips the user bookmarked on the result screen.
class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context).state;
    final extra = StamplyColors.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text('Saved', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Trips you bookmark appear here, ready to check again.',
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
                    'Tap the bookmark on a result to save it.',
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
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Theme.of(context).colorScheme.error,
                        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onError),
                      ),
                      onDismissed: (_) => state.toggleSaved(check),
                      child: CheckTile(
                        check: check,
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
