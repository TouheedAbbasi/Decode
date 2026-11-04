import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'copy_helper.dart';
import 'palette_model.dart';

class PaletteDetailScreen extends ConsumerWidget {
  const PaletteDetailScreen({super.key, required this.palette});

  final Palette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(favoritePalettesProvider).contains(palette.index);
    final scheme = Theme.of(context).colorScheme;
    final roles = palette.roles;

    return Scaffold(
      appBar: AppBar(
        title: Text(palette.name),
        actions: [
          IconButton(
            tooltip: saved ? 'Remove from saved' : 'Save',
            icon: Icon(
              saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: saved ? Colors.redAccent : null,
            ),
            onPressed: () =>
                ref.read(favoritePalettesProvider.notifier).toggle(palette.index),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                for (final c in palette.colors)
                  InkWell(
                    onTap: () => copyText(
                      context,
                      colorHex(c),
                      message: '${colorHex(c)} copied',
                    ),
                    child: Container(
                      height: 84,
                      color: c,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        colorHex(c),
                        style: TextStyle(
                          color: readableOn(c),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap a colour to copy it.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => copyText(
                  context,
                  palette.cssVariables,
                  message: 'CSS variables copied',
                ),
                icon: const Icon(Icons.code_rounded),
                label: const Text('CSS variables'),
              ),
              OutlinedButton.icon(
                onPressed: () => copyText(
                  context,
                  palette.cssGradient,
                  message: 'Gradient copied',
                ),
                icon: const Icon(Icons.gradient_rounded),
                label: const Text('Gradient'),
              ),
              OutlinedButton.icon(
                onPressed: () => copyText(
                  context,
                  palette.hexes.join(', '),
                  message: 'HEX list copied',
                ),
                icon: const Icon(Icons.tag_rounded),
                label: const Text('HEX list'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'How it looks in a page',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: roles.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build something great',
                  style: TextStyle(
                    color: roles.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'A short line of text to see how the colours read together.',
                  style: TextStyle(color: roles.text.withAlpha(200)),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: roles.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Card title',
                          style: TextStyle(
                            color: readableOn(roles.surface),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: roles.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Button',
                          style: TextStyle(
                            color: readableOn(roles.accent),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
