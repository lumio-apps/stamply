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

    Future<void> chooseSecondPassport() async {
      final code = await pickCountry(context, title: l.secondPassport, selected: state.passport2);
      if (code != null) state.setPassport2(code);
    }

    void openResult(TripCheck check) {
      state.addRecent(check);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ResultPage(check: check)));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Rise(
            child: Row(
              children: [
                const StamplyLogo(size: 32),
                const SizedBox(width: 10),
                Text('Stamply', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l.homeTitle, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            l.homeSubtitle,
            style: TextStyle(fontSize: 15, height: 1.5, color: extra.muted),
          ),
          const SizedBox(height: 24),
          Rise(
            delay: const Duration(milliseconds: 120),
            child: CardBox(
              radius: 32,
              padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 12),
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
                    child: _SwapButton(
                      tooltip: l.swapTooltip,
                      onPressed: passport == null && destination == null ? null : state.swap,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (passport != null) ...[
            const SizedBox(height: 8),
            if (state.passport2 == null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: chooseSecondPassport,
                  icon: const Icon(Icons.add),
                  label: Text(l.addSecondPassport),
                ),
              )
            else
              CardBox(
                child: Column(
                  children: [
                    ListTile(
                      onTap: chooseSecondPassport,
                      leading: CountryBadge(code: state.passport2!, size: 40),
                      title: Text(scope.nameOf(state.passport2!),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      subtitle: Text(l.secondPassport, style: TextStyle(color: extra.muted)),
                      trailing: IconButton(
                        tooltip: l.removeSecondPassport,
                        icon: const Icon(Icons.close),
                        onPressed: () => state.setPassport2(null),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8, bottom: 4),
                        child: TextButton(
                          onPressed: state.swapPassports,
                          child: Text(l.useThisPassport),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 16),
          Rise(
            delay: const Duration(milliseconds: 200),
            child: FilledButton(
              onPressed: passport != null && destination != null
                  ? () => openResult(TripCheck(passport, destination))
                  : null,
              child: Text(l.checkRequirements),
            ),
          ),
          if (state.recent.isNotEmpty) ...[
            SectionLabel(
              l.recentChecks,
              trailing: TextButton(onPressed: state.clearRecent, child: Text(l.clear)),
            ),
            CardBox(
              inset: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (final (i, check) in state.recent.indexed)
                    Rise(
                      delay: Duration(milliseconds: 320 + 90 * i),
                      child: CheckTile(check: check, onTap: () => openResult(check)),
                    ),
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
    return CardBox(
      inset: true,
      radius: 24,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              code == null
                  ? Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Neu.raised(extra),
                        shape: BoxShape.circle,
                        boxShadow: Neu.shadows(extra, depth: 0.5),
                      ),
                      child: Icon(Icons.add, color: extra.muted),
                    )
                  : CountryBadge(code: code!),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: extra.muted)),
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
      ),
    );
  }
}

/// Round raised button that turns half a circle each time it is pressed.
class _SwapButton extends StatefulWidget {
  const _SwapButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback? onPressed;

  @override
  State<_SwapButton> createState() => _SwapButtonState();
}

class _SwapButtonState extends State<_SwapButton> {
  double _turns = 0;

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.onPressed;
    final reduce = motionOff(context);
    return NeuButton(
      tooltip: widget.tooltip,
      width: 44,
      height: 44,
      radius: 22,
      padding: EdgeInsets.zero,
      onPressed: onPressed == null
          ? null
          : () {
              setState(() => _turns += 0.5);
              onPressed();
            },
      child: AnimatedRotation(
        turns: _turns,
        duration: reduce ? Duration.zero : const Duration(milliseconds: 420),
        curve: Curves.easeInOutBack,
        child: const Icon(Icons.swap_vert, size: 24),
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
