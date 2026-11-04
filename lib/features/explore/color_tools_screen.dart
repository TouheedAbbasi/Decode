import 'package:flutter/material.dart';

import '../editor/color_picker.dart';
import '../editor/css_color.dart';
import 'copy_helper.dart';
import 'palette_model.dart';

/// Colour picker with HEX / RGB / HSL, contrast checker and shades.
class ColorToolsScreen extends StatefulWidget {
  const ColorToolsScreen({super.key});

  @override
  State<ColorToolsScreen> createState() => _ColorToolsScreenState();
}

class _ColorToolsScreenState extends State<ColorToolsScreen> {
  HSLColor _hsl = const HSLColor.fromAHSL(1, 247, 0.9, 0.62);
  final _hex = TextEditingController(text: '#6d63f5');

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _set(HSLColor value) {
    setState(() => _hsl = value);
    _hex.text = colorToHex(value.toColor());
  }

  double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  Widget _contrastTile(Color color, Color against, String label) {
    final ratio = _contrast(color, against);
    final grade = ratio >= 7
        ? 'AAA'
        : ratio >= 4.5
            ? 'AA'
            : ratio >= 3
                ? 'AA Large'
                : 'Fail';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text on $label',
              style: TextStyle(color: against, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${ratio.toStringAsFixed(2)}:1  $grade',
              style: TextStyle(color: against, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _valueRow(BuildContext context, String label, String value) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 44,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      title: Text(value, style: const TextStyle(fontFamily: 'monospace')),
      trailing: const Icon(Icons.copy_rounded, size: 18),
      onTap: () => copyText(context, value, message: '$label copied'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsl.toColor();
    final scheme = Theme.of(context).colorScheme;

    final shades = [
      for (var i = 1; i <= 9; i++) _hsl.withLightness(i / 10).toColor(),
    ];
    final harmony = {
      'Complement': _hsl.withHue((_hsl.hue + 180) % 360).toColor(),
      'Analogous +30': _hsl.withHue((_hsl.hue + 30) % 360).toColor(),
      'Analogous -30': _hsl.withHue((_hsl.hue + 330) % 360).toColor(),
      'Triad +120': _hsl.withHue((_hsl.hue + 120) % 360).toColor(),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Color Tools')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outline),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _hex,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(isDense: true),
                  onChanged: (t) {
                    final parsed = parseCssColor(t.startsWith('#') ? t : '#$t');
                    if (parsed != null) {
                      setState(() => _hsl = HSLColor.fromColor(parsed));
                    }
                  },
                ),
              ),
            ],
          ),
          HslPicker(value: _hsl, onChanged: _set),
          _valueRow(context, 'HEX', colorToHex(color)),
          _valueRow(context, 'RGB', colorToRgb(color)),
          _valueRow(context, 'HSL', colorToHsl(color)),
          const SizedBox(height: 14),
          const Text('Contrast', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              _contrastTile(color, Colors.white, 'white'),
              const SizedBox(width: 10),
              _contrastTile(color, Colors.black, 'black'),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Shades', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final c in shades)
                Expanded(
                  child: GestureDetector(
                    onTap: () => copyText(context, colorHex(c),
                        message: '${colorHex(c)} copied'),
                    child: Container(height: 44, color: c),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Harmony', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final e in harmony.entries)
                InkWell(
                  onTap: () => copyText(context, colorHex(e.value),
                      message: '${colorHex(e.value)} copied'),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 44,
                        decoration: BoxDecoration(
                          color: e.value,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(e.key, style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
