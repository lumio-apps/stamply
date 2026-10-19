import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import '../widgets.dart';

/// Searchable list of all countries. Pops with the chosen ISO-2 code.
class CountryPickerPage extends StatefulWidget {
  const CountryPickerPage({super.key, required this.title, this.selected});

  final String title;
  final String? selected;

  @override
  State<CountryPickerPage> createState() => _CountryPickerPageState();
}

class _CountryPickerPageState extends State<CountryPickerPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final data = scope.repo.data;
    final l = context.l10n;
    final extra = StamplyColors.of(context);
    final q = _query.trim().toLowerCase();
    // (code, name in the app's language), sorted by that name. The search also
    // matches the English name and the two-letter code.
    final entries = [
      for (final code in data.countries.keys) (code, scope.nameOf(code)),
    ]..sort((a, b) => a.$2.toLowerCase().compareTo(b.$2.toLowerCase()));
    final shown = q.isEmpty
        ? entries
        : entries
            .where((e) =>
                e.$2.toLowerCase().contains(q) ||
                data.nameOf(e.$1).toLowerCase().contains(q) ||
                e.$1.toLowerCase() == q)
            .toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                labelText: l.searchCountry,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l.clearSearch,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }),
                      ),
                filled: true,
                fillColor: extra.field,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text(l.noCountryMatches(_query.trim()),
                        style: TextStyle(color: extra.muted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final e = shown[i];
                      final selected = e.$1 == widget.selected;
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        selected: selected,
                        selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                        leading: CountryBadge(code: e.$1, size: 40),
                        title: Text(
                          e.$2,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        trailing: selected
                            ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () => Navigator.pop(context, e.$1),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Opens the picker and returns the chosen code (or null if cancelled).
Future<String?> pickCountry(BuildContext context, {required String title, String? selected}) {
  return Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => CountryPickerPage(title: title, selected: selected)),
  );
}
