import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../schengen.dart';
import '../theme.dart';
import '../widgets.dart';

/// Schengen 90/180-day calculator. Everything is worked out on the device.
class SchengenPage extends StatefulWidget {
  const SchengenPage({super.key});

  @override
  State<SchengenPage> createState() => _SchengenPageState();
}

class _SchengenPageState extends State<SchengenPage> {
  DateTime? _entry;

  Future<void> _addStay(AppState state) async {
    final l = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 2),
      lastDate: DateTime(today.year + 2, 12, 31),
      helpText: l.schengenRangeHelp,
    );
    if (range != null) state.addStay(SchengenStay(range.start, range.end));
  }

  Future<void> _pickEntry() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _entry ?? today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 2, 12, 31),
      helpText: context.l10n.schengenPickEntry,
    );
    if (picked != null) setState(() => _entry = picked);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final l = context.l10n;
    final extra = StamplyColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat.yMMMd();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final calc = SchengenCalculator(state.stays);
    final used = calc.usedOn(today);
    final left = calc.remainingOn(today);
    final freeAgain = calc.nextFreeDay(today);
    final entry = _entry;
    final maxStay = entry == null ? null : calc.maxStayFrom(entry);
    final members = kSchengenCountries.toList()
      ..sort((a, b) => scope.nameOf(a).toLowerCase().compareTo(scope.nameOf(b).toLowerCase()));

    return Scaffold(
      appBar: AppBar(title: Text(l.schengenTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(l.schengenIntro, style: TextStyle(fontSize: 15, height: 1.5, color: extra.muted)),
          const SizedBox(height: 16),
          CardBox(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.schengenAsOf(fmt.format(today)),
                    style: TextStyle(fontSize: 13, color: extra.muted)),
                const SizedBox(height: 6),
                Text(
                  left < 0 ? l.schengenOver : l.schengenRemaining(left),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (used / kSchengenLimit).clamp(0.0, 1.0),
                    minHeight: 10,
                    color: left <= 0 ? scheme.error : scheme.primary,
                    backgroundColor: extra.divider,
                  ),
                ),
                const SizedBox(height: 8),
                Text(l.schengenDaysUsed(used, kSchengenLimit),
                    style: TextStyle(fontSize: 14, color: extra.muted)),
                if (freeAgain != null) ...[
                  const SizedBox(height: 8),
                  Text(l.schengenFreeAgain(fmt.format(freeAgain)),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          SectionLabel(l.schengenStays),
          if (state.stays.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l.schengenNoStays, style: TextStyle(color: extra.muted)),
            )
          else
            CardBox(
              child: Column(
                children: [
                  for (final (i, stay) in state.stays.indexed) ...[
                    if (i > 0) Divider(height: 1, color: extra.divider),
                    ListTile(
                      leading: const Icon(Icons.flight_takeoff_outlined),
                      title: Text('${fmt.format(stay.start)} – ${fmt.format(stay.end)}'),
                      subtitle: Text(l.schengenStayDays(stay.days),
                          style: TextStyle(color: extra.muted)),
                      trailing: IconButton(
                        tooltip: l.remove,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => state.removeStay(stay),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _addStay(state),
            icon: const Icon(Icons.add),
            label: Text(l.schengenAddStay),
          ),
          SectionLabel(l.schengenPlan),
          CardBox(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.schengenPlanHint,
                    style: TextStyle(fontSize: 14, height: 1.5, color: extra.muted)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickEntry,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(entry == null ? l.schengenPickEntry : fmt.format(entry)),
                ),
                if (entry != null && maxStay != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    l.schengenCanStay(
                      maxStay,
                      fmt.format(entry),
                      fmt.format(DateTime(entry.year, entry.month, entry.day + (maxStay > 0 ? maxStay - 1 : 0))),
                    ),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          CardBox(
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(l.schengenWhichCountries),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  members.map(scope.nameOf).join(', '),
                  style: TextStyle(fontSize: 14, height: 1.6, color: extra.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l.schengenRules, style: TextStyle(fontSize: 13, height: 1.5, color: extra.muted)),
        ],
      ),
    );
  }
}
