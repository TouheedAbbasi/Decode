import 'package:flutter/material.dart';

import 'css_color.dart';

enum ColorFormat { hex, hsl, rgb }

String formatColor(Color color, ColorFormat format) => switch (format) {
      ColorFormat.hex => colorToHex(color),
      ColorFormat.hsl => colorToHsl(color),
      ColorFormat.rgb => colorToRgb(color),
    };

ColorFormat detectFormat(String text) {
  final t = text.trim().toLowerCase();
  if (t.startsWith('hsl')) return ColorFormat.hsl;
  if (t.startsWith('rgb')) return ColorFormat.rgb;
  return ColorFormat.hex;
}

/// Hue / saturation / lightness / opacity sliders. The colour is kept as an
/// [HSLColor] so the hue is not lost when saturation reaches zero.
class HslPicker extends StatelessWidget {
  const HslPicker({super.key, required this.value, required this.onChanged});

  final HSLColor value;
  final ValueChanged<HSLColor> onChanged;

  static const _hues = [
    Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
    Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF),
    Color(0xFFFF0000), //
  ];

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget slider(
      String label,
      double current,
      double max,
      String shown,
      ValueChanged<double> change,
    ) {
      return Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(label, style: TextStyle(color: muted, fontSize: 12)),
          ),
          Expanded(
            child: Slider(
              value: current.clamp(0, max).toDouble(),
              max: max,
              onChanged: change,
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              shown,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: const LinearGradient(colors: _hues),
          ),
        ),
        slider('H', value.hue, 360, '${value.hue.round()}\u00B0',
            (v) => onChanged(value.withHue(v))),
        slider('S', value.saturation, 1, '${(value.saturation * 100).round()}%',
            (v) => onChanged(value.withSaturation(v))),
        slider('L', value.lightness, 1, '${(value.lightness * 100).round()}%',
            (v) => onChanged(value.withLightness(v))),
        slider('A', value.alpha, 1, '${(value.alpha * 100).round()}%',
            (v) => onChanged(value.withAlpha(v))),
      ],
    );
  }
}

/// Dialog to pick a colour with HSL sliders. Returns the new colour as text
/// (hex, hsl() or rgb(), matching [initialText]'s style), or null.
Future<String?> showColorPickerDialog(
  BuildContext context, {
  required Color initial,
  required String initialText,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ColorPickerDialog(initial: initial, initialText: initialText),
  );
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial, required this.initialText});

  final Color initial;
  final String initialText;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSLColor _hsl;
  late ColorFormat _format;
  late final TextEditingController _hex;

  @override
  void initState() {
    super.initState();
    _hsl = HSLColor.fromColor(widget.initial);
    _format = detectFormat(widget.initialText);
    _hex = TextEditingController(text: colorToHex(widget.initial));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _update(HSLColor next) {
    setState(() => _hsl = next);
    _hex.text = colorToHex(next.toColor());
  }

  void _typed(String text) {
    final color = parseCssColor(text.startsWith('#') ? text : '#$text');
    if (color != null) setState(() => _hsl = HSLColor.fromColor(color));
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsl.toColor();
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Pick a colour'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scheme.outline),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _hex,
                    onChanged: _typed,
                    style: const TextStyle(fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '#4f46e5',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            HslPicker(value: _hsl, onChanged: _update),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final f in ColorFormat.values)
                  ChoiceChip(
                    label: Text(f.name.toUpperCase()),
                    selected: _format == f,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _format = f),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatColor(color, _format),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(formatColor(color, _format)),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
