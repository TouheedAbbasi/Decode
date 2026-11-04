import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../editor/color_picker.dart';
import '../editor/css_color.dart';
import 'copy_helper.dart';
import 'palette_model.dart';

/// Build a CSS gradient visually and copy the code.
class GradientScreen extends ConsumerStatefulWidget {
  const GradientScreen({super.key});

  @override
  ConsumerState<GradientScreen> createState() => _GradientScreenState();
}

class _GradientScreenState extends ConsumerState<GradientScreen> {
  List<Color> _stops = const [Color(0xFF6D63F5), Color(0xFFEC4899)];
  double _angle = 135;
  bool _radial = false;
  final _random = math.Random();

  String get _css {
    final colors = [for (final c in _stops) colorHex(c)].join(', ');
    return _radial
        ? 'background: radial-gradient(circle, $colors);'
        : 'background: linear-gradient(${_angle.round()}deg, $colors);';
  }

  Gradient get _gradient {
    if (_radial) return RadialGradient(colors: _stops);
    final r = _angle * math.pi / 180;
    return LinearGradient(
      begin: Alignment(-math.sin(r), math.cos(r)),
      end: Alignment(math.sin(r), -math.cos(r)),
      colors: _stops,
    );
  }

  Future<void> _edit(int index) async {
    final picked = await showColorPickerDialog(
      context,
      initial: _stops[index],
      initialText: colorHex(_stops[index]),
    );
    if (picked == null) return;
    final color = parseCssColor(picked);
    if (color != null) {
      setState(() => _stops = [..._stops]..[index] = color);
    }
  }

  void _randomize() {
    final palettes = ref.read(palettesProvider);
    final palette = palettes[_random.nextInt(palettes.length)];
    final count = 2 + _random.nextInt(2);
    final picks = [...palette.colors]..shuffle(_random);
    setState(() {
      _stops = picks.take(count).toList();
      _angle = (_random.nextInt(12) * 30).toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Gradient Generator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: _gradient,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < _stops.length; i++)
                GestureDetector(
                  onTap: () => _edit(i),
                  onLongPress: _stops.length > 2
                      ? () => setState(() => _stops = [..._stops]..removeAt(i))
                      : null,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _stops[i],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outline, width: 2),
                    ),
                  ),
                ),
              if (_stops.length < 5)
                IconButton.outlined(
                  tooltip: 'Add colour',
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () =>
                      setState(() => _stops = [..._stops, _stops.last]),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap a colour to change it. Long-press to remove (minimum 2).',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Linear')),
              ButtonSegment(value: true, label: Text('Radial')),
            ],
            selected: {_radial},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _radial = s.first),
          ),
          if (!_radial) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Angle'),
                Expanded(
                  child: Slider(
                    value: _angle,
                    max: 360,
                    onChanged: (v) => setState(() => _angle = v),
                  ),
                ),
                SizedBox(width: 44, child: Text('${_angle.round()}\u00B0')),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(color: scheme.outline),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              _css,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _randomize,
                  icon: const Icon(Icons.casino_outlined),
                  label: const Text('Random'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => copyText(context, _css, message: 'CSS copied'),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy CSS'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
