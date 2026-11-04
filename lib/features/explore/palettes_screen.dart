import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'palette_detail_screen.dart';
import 'palette_model.dart';

/// 300 ready-made colour palettes that go well together.
class PalettesScreen extends ConsumerStatefulWidget {
  const PalettesScreen({super.key});

  @override
  ConsumerState<PalettesScreen> createState() => _PalettesScreenState();
}

class _PalettesScreenState extends ConsumerState<PalettesScreen> {
  String _filter = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(palettesProvider);
    final favorites = ref.watch(favoritePalettesProvider);
    final scheme = Theme.of(context).colorScheme;

    final shown = all.where((p) {
      final inFilter = switch (_filter) {
        'All' => true,
        'Saved' => favorites.contains(p.index),
        _ => p.mood == _filter,
      };
      final inQuery = _query.isEmpty ||
          p.name.toLowerCase().contains(_query) ||
          p.hexes.any((h) => h.toLowerCase().contains(_query.replaceAll('#', '')));
      return inFilter && inQuery;
    }).toList();

    final filters = ['All', 'Saved', ...paletteMoods];

    return Scaffold(
      appBar: AppBar(title: Text('Color Palettes (${all.length})')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or hex...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(filters[i]),
                selected: _filter == filters[i],
                showCheckmark: false,
                onSelected: (_) => setState(() => _filter = filters[i]),
              ),
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text(
                      _filter == 'Saved'
                          ? 'Tap the heart on a palette to save it here.'
                          : 'No matching palettes',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: shown.length,
                    itemBuilder: (_, i) => _PaletteCard(
                      palette: shown[i],
                      saved: favorites.contains(shown[i].index),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PaletteCard extends ConsumerWidget {
  const _PaletteCard({required this.palette, required this.saved});

  final Palette palette;
  final bool saved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PaletteDetailScreen(palette: palette),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  for (final c in palette.colors)
                    Expanded(child: ColoredBox(color: c, child: const SizedBox.expand())),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 2, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          palette.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          palette.mood,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: saved ? 'Remove from saved' : 'Save',
                    icon: Icon(
                      saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 20,
                      color: saved ? Colors.redAccent : scheme.onSurfaceVariant,
                    ),
                    onPressed: () => ref
                        .read(favoritePalettesProvider.notifier)
                        .toggle(palette.index),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
