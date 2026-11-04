import 'package:flutter/painting.dart';

class ColorMatch {
  const ColorMatch(this.start, this.end, this.color);

  final int start;
  final int end;
  final Color color;
}

int _a(Color c) => (c.toARGB32() >> 24) & 0xFF;
int _r(Color c) => (c.toARGB32() >> 16) & 0xFF;
int _g(Color c) => (c.toARGB32() >> 8) & 0xFF;
int _b(Color c) => c.toARGB32() & 0xFF;

/// Reads a CSS colour: #hex, rgb()/rgba(), hsl()/hsla() or a colour name.
Color? parseCssColor(String input) {
  final text = input.trim().toLowerCase();
  if (text.startsWith('#')) return _parseHex(text.substring(1));
  if (text.startsWith('rgb')) return _parseRgb(text);
  if (text.startsWith('hsl')) return _parseHsl(text);
  final named = cssNamedColors[text];
  return named == null ? null : Color(0xFF000000 | named);
}

Color? _parseHex(String hex) {
  if (!RegExp(r'^[0-9a-f]+$').hasMatch(hex)) return null;
  switch (hex.length) {
    case 3:
    case 4:
      final d = hex.split('').map((c) => c + c).toList();
      final a = d.length == 4 ? int.parse(d[3], radix: 16) : 255;
      return Color.fromARGB(
        a,
        int.parse(d[0], radix: 16),
        int.parse(d[1], radix: 16),
        int.parse(d[2], radix: 16),
      );
    case 6:
    case 8:
      final alpha = hex.length == 8 ? int.parse(hex.substring(6, 8), radix: 16) : 255;
      return Color.fromARGB(
        alpha,
        int.parse(hex.substring(0, 2), radix: 16),
        int.parse(hex.substring(2, 4), radix: 16),
        int.parse(hex.substring(4, 6), radix: 16),
      );
  }
  return null;
}

List<double>? _numbers(String text) {
  final open = text.indexOf('(');
  final close = text.lastIndexOf(')');
  if (open < 0 || close <= open) return null;
  final parts = text
      .substring(open + 1, close)
      .split(RegExp(r'[\s,/]+'))
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.length < 3) return null;
  final values = <double>[];
  for (final part in parts) {
    final percent = part.endsWith('%');
    final raw = part.replaceAll(RegExp(r'%|deg'), '');
    final value = double.tryParse(raw);
    if (value == null) return null;
    values.add(percent ? -value : value); // negative marks a percentage
  }
  return values;
}

Color? _parseRgb(String text) {
  final v = _numbers(text);
  if (v == null) return null;
  double channel(double x) => x < 0 ? (-x / 100 * 255) : x;
  final alpha = v.length > 3 ? (v[3] < 0 ? -v[3] / 100 : v[3]) : 1.0;
  return Color.fromARGB(
    (alpha.clamp(0, 1) * 255).round(),
    channel(v[0]).clamp(0, 255).round(),
    channel(v[1]).clamp(0, 255).round(),
    channel(v[2]).clamp(0, 255).round(),
  );
}

Color? _parseHsl(String text) {
  final v = _numbers(text);
  if (v == null) return null;
  final alpha = v.length > 3 ? (v[3] < 0 ? -v[3] / 100 : v[3]) : 1.0;
  return HSLColor.fromAHSL(
    alpha.clamp(0, 1).toDouble(),
    (v[0].abs() % 360).toDouble(),
    (v[1].abs() / 100).clamp(0, 1).toDouble(),
    (v[2].abs() / 100).clamp(0, 1).toDouble(),
  ).toColor();
}

String _hex2(int v) => v.toRadixString(16).padLeft(2, '0');

String colorToHex(Color c) {
  final base = '#${_hex2(_r(c))}${_hex2(_g(c))}${_hex2(_b(c))}';
  return _a(c) == 255 ? base : '$base${_hex2(_a(c))}';
}

String colorToRgb(Color c) {
  final a = _a(c);
  if (a == 255) return 'rgb(${_r(c)}, ${_g(c)}, ${_b(c)})';
  return 'rgba(${_r(c)}, ${_g(c)}, ${_b(c)}, ${(a / 255).toStringAsFixed(2)})';
}

String colorToHsl(Color c) {
  final hsl = HSLColor.fromColor(c);
  final h = hsl.hue.round() % 360;
  final s = (hsl.saturation * 100).round();
  final l = (hsl.lightness * 100).round();
  final a = _a(c);
  if (a == 255) return 'hsl($h, $s%, $l%)';
  return 'hsla($h, $s%, $l%, ${(a / 255).toStringAsFixed(2)})';
}

final _functional = RegExp(
  r'#[0-9a-fA-F]{8}\b|#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3,4}\b|(?:rgb|hsl)a?\([^)]*\)',
);
final _named = RegExp(r'\b(?:' + cssNamedColors.keys.join('|') + r')\b');

/// Colours written in [line]. Colour names are only looked for when
/// [names] is true (CSS), to avoid false hits in prose and code.
List<ColorMatch> findColors(String line, {bool names = false}) {
  final found = <ColorMatch>[];
  for (final m in _functional.allMatches(line)) {
    final color = parseCssColor(m[0]!);
    if (color != null) found.add(ColorMatch(m.start, m.end, color));
  }
  if (names) {
    for (final m in _named.allMatches(line)) {
      final clash = found.any((f) => m.start < f.end && m.end > f.start);
      final color = parseCssColor(m[0]!);
      if (!clash && color != null) found.add(ColorMatch(m.start, m.end, color));
    }
  }
  found.sort((a, b) => a.start.compareTo(b.start));
  return found;
}

/// Popular CSS colour names (RGB values).
const cssNamedColors = <String, int>{
  'black': 0x000000, 'white': 0xFFFFFF, 'red': 0xFF0000, 'lime': 0x00FF00,
  'blue': 0x0000FF, 'yellow': 0xFFFF00, 'cyan': 0x00FFFF, 'aqua': 0x00FFFF,
  'magenta': 0xFF00FF, 'fuchsia': 0xFF00FF, 'silver': 0xC0C0C0,
  'gray': 0x808080, 'grey': 0x808080, 'maroon': 0x800000, 'olive': 0x808000,
  'green': 0x008000, 'purple': 0x800080, 'teal': 0x008080, 'navy': 0x000080,
  'orange': 0xFFA500, 'pink': 0xFFC0CB, 'brown': 0xA52A2A, 'gold': 0xFFD700,
  'coral': 0xFF7F50, 'salmon': 0xFA8072, 'tomato': 0xFF6347,
  'crimson': 0xDC143C, 'indigo': 0x4B0082, 'violet': 0xEE82EE,
  'orchid': 0xDA70D6, 'plum': 0xDDA0DD, 'lavender': 0xE6E6FA,
  'turquoise': 0x40E0D0, 'skyblue': 0x87CEEB, 'steelblue': 0x4682B4,
  'royalblue': 0x4169E1, 'dodgerblue': 0x1E90FF, 'slateblue': 0x6A5ACD,
  'khaki': 0xF0E68C, 'beige': 0xF5F5DC, 'ivory': 0xFFFFF0, 'tan': 0xD2B48C,
  'chocolate': 0xD2691E, 'sienna': 0xA0522D, 'peru': 0xCD853F,
  'wheat': 0xF5DEB3, 'linen': 0xFAF0E6, 'snow': 0xFFFAFA,
  'mintcream': 0xF5FFFA, 'honeydew': 0xF0FFF0, 'azure': 0xF0FFFF,
  'aliceblue': 0xF0F8FF, 'ghostwhite': 0xF8F8FF, 'whitesmoke': 0xF5F5F5,
  'gainsboro': 0xDCDCDC, 'lightgray': 0xD3D3D3, 'lightgrey': 0xD3D3D3,
  'darkgray': 0xA9A9A9, 'darkgrey': 0xA9A9A9, 'dimgray': 0x696969,
  'dimgrey': 0x696969, 'slategray': 0x708090, 'darkslategray': 0x2F4F4F,
  'lightblue': 0xADD8E6, 'lightgreen': 0x90EE90, 'lightpink': 0xFFB6C1,
  'lightyellow': 0xFFFFE0, 'lightcoral': 0xF08080, 'darkblue': 0x00008B,
  'darkgreen': 0x006400, 'darkred': 0x8B0000, 'darkorange': 0xFF8C00,
  'darkviolet': 0x9400D3, 'deeppink': 0xFF1493, 'hotpink': 0xFF69B4,
  'forestgreen': 0x228B22, 'seagreen': 0x2E8B57, 'springgreen': 0x00FF7F,
  'limegreen': 0x32CD32, 'midnightblue': 0x191970, 'firebrick': 0xB22222,
  'goldenrod': 0xDAA520, 'rebeccapurple': 0x663399, 'cornflowerblue': 0x6495ED,
  'mediumpurple': 0x9370DB, 'mediumseagreen': 0x3CB371, 'lightseagreen': 0x20B2AA,
  'cadetblue': 0x5F9EA0, 'rosybrown': 0xBC8F8F, 'thistle': 0xD8BFD8,
  'moccasin': 0xFFE4B5, 'peachpuff': 0xFFDAB9, 'bisque': 0xFFE4C4,
};
