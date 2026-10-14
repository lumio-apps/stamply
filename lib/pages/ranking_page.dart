import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import '../widgets.dart';

/// All passports, ranked by how many destinations they reach without a visa in advance.
class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final l = context.l10n;
    final extra = StamplyColors.of(context);
    final list = scope.repo.data.ranking();
    final mine = {state.passport, state.passport2}..remove(null);

    return Scaffold(
      appBar: AppBar(title: Text(l.rankingTitle)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        itemCount: list.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Text(l.rankingIntro,
                  style: TextStyle(fontSize: 14, height: 1.5, color: extra.muted)),
            );
          }
          final e = list[i - 1];
          final isMine = mine.contains(e.code);
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            selected: isMine,
            selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
            leading: SizedBox(
              width: 72,
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('${e.rank}',
                        style: TextStyle(fontSize: 14, color: extra.muted),
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 6),
                  CountryBadge(code: e.code, size: 36),
                ],
              ),
            ),
            title: Text(scope.nameOf(e.code), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text('${e.score}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          );
        },
      ),
    );
  }
}
