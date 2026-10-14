import 'package:flutter/material.dart';

import '../app_state.dart';
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
    final data = AppScope.of(context).repo.data;
    final extra = StamplyColors.of(context);
    final q = _query.trim().toLowerCase();
    final entries = data.countries.entries
        .where((e) => q.isEmpty || e.value.toLowerCase().contains(q) || e.key.toLowerCase() == q)
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
                labelText: 'Search country',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }),
                      ),
                filled: true,
                fillColor: extra.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text('No country matches "$_query"',
                        style: TextStyle(color: extra.muted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      final selected = e.key == widget.selected;
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        selected: selected,
                        selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                        leading: CountryBadge(code: e.key, size: 40),
                        title: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        trailing: selected
                            ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () => Navigator.pop(context, e.key),
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
