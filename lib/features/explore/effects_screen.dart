import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../editor/color_picker.dart';
import '../editor/css_color.dart';
import 'copy_helper.dart';

enum _Mode { shadow, glass, neumorphism }

/// Box-shadow, glassmorphism and neumorphism generators with live preview.
class EffectsScreen extends StatefulWidget {
  const EffectsScreen({super.key});

  @override
  State<EffectsScreen> createState() => _EffectsScreenState();
}

class _EffectsScreenState extends State<EffectsScreen> {
  _Mode _mode = _Mode.shadow;
  double _radius = 20;

  // shadow
  double _x = 0, _y = 12, _blur = 30, _spread = -4, _opacity = 0.25;
  Color _shadowColor = const Color(0xFF000000);

  // glass
  double _glassBlur = 14, _glassAlpha = 0.2;

  // neumorphism
  Color _base = const Color(0xFFE0E5EC);
  double _distance = 9, _neuBlur = 18, _intensity = 0.15;

  Future<Color?> _pick(Color initial) async {
    final text = await showColorPickerDialog(
      context,
      initial: initial,
      initialText: colorToHex(initial),
    );
    return text == null ? null : parseCssColor(text);
  }

  Color _shift(Color c, double delta) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + delta).clamp(0.0, 1.0).toDouble()).toColor();
  }

  String _rgba(Color c, double alpha) {
    final v = c.toARGB32();
    return 'rgba(${(v >> 16) & 0xFF}, ${(v >> 8) & 0xFF}, ${v & 0xFF}, '
        '${alpha.toStringAsFixed(2)})';
  }

  String get _css {
    switch (_mode) {
      case _Mode.shadow:
        return 'box-shadow: ${_x.round()}px ${_y.round()}px ${_blur.round()}px '
            '${_spread.round()}px ${_rgba(_shadowColor, _opacity)};\n'
            'border-radius: ${_radius.round()}px;';
      case _Mode.glass:
        return 'background: ${_rgba(Colors.white, _glassAlpha)};\n'
            'backdrop-filter: blur(${_glassBlur.round()}px);\n'
            '-webkit-backdrop-filter: blur(${_glassBlur.round()}px);\n'
            'border: 1px solid ${_rgba(Colors.white, 0.3)};\n'
            'border-radius: ${_radius.round()}px;\n'
            'box-shadow: 0 8px 32px rgba(0, 0, 0, 0.15);';
      case _Mode.neumorphism:
        final dark = colorToHex(_shift(_base, -_intensity));
        final light = colorToHex(_shift(_base, _intensity));
        final d = _distance.round();
        final b = _neuBlur.round();
        return 'background: ${colorToHex(_base)};\n'
            'border-radius: ${_radius.round()}px;\n'
            'box-shadow: ${d}px ${d}px ${b}px $dark,\n'
            '            -${d}px -${d}px ${b}px $light;';
    }
  }

  Widget _preview() {
    final r = BorderRadius.circular(_radius);
    switch (_mode) {
      case _Mode.shadow:
        return Container(
          height: 220,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 150,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: r,
              boxShadow: [
                BoxShadow(
                  offset: Offset(_x, _y),
                  blurRadius: _blur,
                  spreadRadius: _spread,
                  color: _shadowColor.withAlpha((_opacity * 255).round()),
                ),
              ],
            ),
          ),
        );
      case _Mode.glass:
        return Container(
          height: 220,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF6D63F5), Color(0xFFEC4899), Color(0xFFF59E0B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            borderRadius: r,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: _glassBlur, sigmaY: _glassBlur),
              child: Container(
                width: 160,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((_glassAlpha * 255).round()),
                  borderRadius: r,
                  border: Border.all(color: Colors.white.withAlpha(77)),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Glass',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        );
      case _Mode.neumorphism:
        return Container(
          height: 220,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _base,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 150,
            height: 110,
            decoration: BoxDecoration(
              color: _base,
              borderRadius: r,
              boxShadow: [
                BoxShadow(
                  offset: Offset(_distance, _distance),
                  blurRadius: _neuBlur,
                  color: _shift(_base, -_intensity),
                ),
                BoxShadow(
                  offset: Offset(-_distance, -_distance),
                  blurRadius: _neuBlur,
                  color: _shift(_base, _intensity),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String suffix = 'px',
  }) {
    final shown = suffix == '' ? value.toStringAsFixed(2) : '${value.round()}$suffix';
    return Row(
      children: [
        SizedBox(width: 78, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
        SizedBox(width: 48, child: Text(shown, textAlign: TextAlign.right)),
      ],
    );
  }

  List<Widget> _controls() {
    final radius = _slider('Radius', _radius, 0, 60, (v) => setState(() => _radius = v));
    switch (_mode) {
      case _Mode.shadow:
        return [
          _slider('X offset', _x, -50, 50, (v) => setState(() => _x = v)),
          _slider('Y offset', _y, -50, 50, (v) => setState(() => _y = v)),
          _slider('Blur', _blur, 0, 100, (v) => setState(() => _blur = v)),
          _slider('Spread', _spread, -30, 30, (v) => setState(() => _spread = v)),
          _slider('Opacity', _opacity, 0, 1, (v) => setState(() => _opacity = v),
              suffix: ''),
          radius,
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Shadow colour'),
            trailing: CircleAvatar(backgroundColor: _shadowColor, radius: 14),
            onTap: () async {
              final c = await _pick(_shadowColor);
              if (c != null) setState(() => _shadowColor = c);
            },
          ),
        ];
      case _Mode.glass:
        return [
          _slider('Blur', _glassBlur, 0, 30, (v) => setState(() => _glassBlur = v)),
          _slider('Opacity', _glassAlpha, 0.05, 0.6,
              (v) => setState(() => _glassAlpha = v),
              suffix: ''),
          radius,
        ];
      case _Mode.neumorphism:
        return [
          _slider('Distance', _distance, 2, 30, (v) => setState(() => _distance = v)),
          _slider('Blur', _neuBlur, 4, 60, (v) => setState(() => _neuBlur = v)),
          _slider('Intensity', _intensity, 0.05, 0.35,
              (v) => setState(() => _intensity = v),
              suffix: ''),
          radius,
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Surface colour'),
            trailing: CircleAvatar(backgroundColor: _base, radius: 14),
            onTap: () async {
              final c = await _pick(_base);
              if (c != null) setState(() => _base = c);
            },
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Shadow & Glass')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<_Mode>(
            segments: const [
              ButtonSegment(value: _Mode.shadow, label: Text('Shadow')),
              ButtonSegment(value: _Mode.glass, label: Text('Glass')),
              ButtonSegment(value: _Mode.neumorphism, label: Text('Neumorphism')),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 14),
          _preview(),
          const SizedBox(height: 10),
          ..._controls(),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(color: scheme.outline),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              _css,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => copyText(context, _css, message: 'CSS copied'),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy CSS'),
          ),
        ],
      ),
    );
  }
}
