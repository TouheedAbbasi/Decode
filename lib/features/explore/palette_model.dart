import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_providers.dart';
import 'palette_data.dart';

const paletteMoods = [
  'Pastel', 'Vibrant', 'Dark', 'Earth', 'Ocean', 'Sunset', 'Forest', 'Retro',
  'Candy', 'Nordic', 'Mono', 'Neon', 'Muted', 'Lavender', //
];

class Palette {
  const Palette({
    required this.index,
    required this.colors,
    required this.name,
    required this.mood,
  });

  final int index;
  final List<Color> colors;
  final String name;
  final String mood;

  List<String> get hexes => [for (final c in colors) colorHex(c)];

  /// `:root { --color-1: ...; }`
  String get cssVariables => ':root {\n${[
        for (var i = 0; i < colors.length; i++)
          '  --color-${i + 1}: ${colorHex(colors[i])};',
      ].join('\n')}\n}';

  String get cssGradient =>
      'background: linear-gradient(135deg, ${hexes.join(', ')});';

  /// Sensible UI roles picked from the four colours.
  PaletteRoles get roles {
    final byLight = [...colors]
      ..sort((a, b) => HSLColor.fromColor(b).lightness
          .compareTo(HSLColor.fromColor(a).lightness));
    final background = byLight.first;
    final text = byLight.last;
    final rest = byLight.sublist(1, byLight.length - 1)
      ..sort((a, b) => HSLColor.fromColor(b).saturation
          .compareTo(HSLColor.fromColor(a).saturation));
    return PaletteRoles(
      background: background,
      text: text,
      accent: rest.first,
      surface: rest.last,
    );
  }
}

class PaletteRoles {
  const PaletteRoles({
    required this.background,
    required this.text,
    required this.accent,
    required this.surface,
  });

  final Color background;
  final Color text;
  final Color accent;
  final Color surface;
}

String colorHex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Black or white, whichever is readable on [background].
Color readableOn(Color background) =>
    background.computeLuminance() > 0.5 ? const Color(0xFF111111) : Colors.white;

List<Palette> parsePalettes(List<String> source) {
  final result = <Palette>[];
  for (var i = 0; i < source.length; i++) {
    final parts = source[i].split('|');
    if (parts.length < 3) continue;
    final colors = [
      for (final hex in parts[0].split('-'))
        Color(0xFF000000 | int.parse(hex, radix: 16)),
    ];
    result.add(Palette(index: i, colors: colors, name: parts[1], mood: parts[2]));
  }
  return result;
}

final palettesProvider = Provider<List<Palette>>(
  (ref) => parsePalettes(paletteSource),
);

class FavoritePalettesNotifier extends Notifier<Set<int>> {
  static const _key = 'favorite_palettes';

  @override
  Set<int> build() {
    final saved = ref.watch(sharedPrefsProvider).getStringList(_key) ?? const [];
    return {for (final s in saved) if (int.tryParse(s) != null) int.parse(s)};
  }

  Future<void> toggle(int index) async {
    final next = {...state};
    if (!next.remove(index)) next.add(index);
    state = next;
    await ref
        .read(sharedPrefsProvider)
        .setStringList(_key, [for (final i in next) '$i']);
  }
}

final favoritePalettesProvider =
    NotifierProvider<FavoritePalettesNotifier, Set<int>>(
  FavoritePalettesNotifier.new,
);
