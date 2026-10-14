import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'country_picker_page.dart';
import 'result_page.dart';

/// "Check" tab: pick passport + destination, then see the result.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final extra = StamplyColors.of(context);
    final l = context.l10n;
    final passport = state.passport;
    final destination = state.destination;

    Future<void> choosePassport() async {
      final code = await pickCountry(context, title: l.myPassport, selected: passport);
      if (code != null) state.setPassport(code);
    }

    Future<void> chooseDestination() async {
      final code = await pickCountry(context, title: l.travellingTo, selected: destination);
      if (code != null) state.setDestination(code);
    }

    void openResult(TripCheck check) {
      state.addRecent(check);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ResultPage(check: check)));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Row(
            children: [
              const StamplyLogo(size: 32),
              const SizedBox(width: 10),
              Text('Stamply', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 24),
          Text(l.homeTitle, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            l.homeSubtitle,
            style: TextStyle(fontSize: 15, height: 1.5, color: extra.muted),
          ),
          const SizedBox(height: 24),
          CardBox(
            padding: const EdgeInsets.all(8),
            child: Stack(
              alignment: AlignmentDirectional.centerEnd,
              children: [
                Column(
                  children: [
                    _CountryRow(
                      label: l.myPassport,
                      code: passport,
                      name: passport == null ? null : scope.nameOf(passport),
                      onTap: choosePassport,
                    ),
                    Divider(height: 1, indent: 12, endIndent: 12, color: extra.divider),
                    _CountryRow(
                      label: l.travellingTo,
                      code: destination,
                      name: destination == null ? null : scope.nameOf(destination),
                      onTap: chooseDestination,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 44),
                  child: IconButton.outlined(
                    tooltip: l.swapTooltip,
                    style: IconButton.styleFrom(
                      backgroundColor: extra.card,
                      side: BorderSide(color: extra.divider),
                    ),
                    onPressed: passport == null && destination == null ? null : state.swap,
                    icon: const Icon(Icons.swap_vert),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: passport != null && destination != null
                ? () => openResult(TripCheck(passport, destination))
                : null,
            child: Text(l.checkRequirements),
          ),
          if (state.recent.isNotEmpty) ...[
            SectionLabel(
              l.recentChecks,
              trailing: TextButton(onPressed: state.clearRecent, child: Text(l.clear)),
            ),
            CardBox(
              child: Column(
                children: [
                  for (final (i, check) in state.recent.indexed) ...[
                    if (i > 0) Divider(height: 1, color: extra.divider),
                    CheckTile(check: check, onTap: () => openResult(check)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.label,
    required this.code,
    required this.name,
    required this.onTap,
  });

  final String label;
  final String? code;
  final String? name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final extra = StamplyColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            code == null
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: extra.divider,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add, color: extra.muted),
                  )
                : CountryBadge(code: code!),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 13, color: extra.muted)),
                  const SizedBox(height: 2),
                  Text(
                    name ?? context.l10n.chooseCountry,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: name == null ? extra.muted : null,
                    ),
                  ),
                ],
              ),
            ),
            // Space for the swap button that floats over the rows.
            const SizedBox(width: 56),
            Icon(Icons.chevron_right, color: extra.muted),
          ],
        ),
      ),
    );
  }
}

/// One row: "IN → Thailand" with its status pill.
class CheckTile extends StatelessWidget {
  const CheckTile({super.key, required this.check, required this.onTap, this.changed = false});

  final TripCheck check;
  final VoidCallback onTap;

  /// True when the rule changed since the user last looked at it.
  final bool changed;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final data = scope.repo.data;
    final rule = data.rule(check.passport, check.destination);
    return ListTile(
      onTap: onTap,
      title: Text(
        '${check.passport} → ${scope.nameOf(check.destination)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: rule == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (changed) ...[const ChangedBadge(), const SizedBox(width: 8)],
                StatusPill(rule: rule),
              ],
            ),
    );
  }
}
