import 'package:flutter/material.dart';

import 'code_language.dart';
import 'syntax_highlighter.dart';

/// A text controller that colours its text by [language].
///
/// Colouring is cached, so moving the cursor or scrolling does not re-scan
/// the whole file; only real text changes do.
class HighlightingController extends TextEditingController {
  HighlightingController({super.text, required this.language});

  CodeLanguage language;
  SyntaxPalette palette = SyntaxPalette.light;

  /// Files bigger than this are shown without colours to stay responsive.
  static const maxHighlightLength = 80000;

  String? _cacheText;
  CodeLanguage? _cacheLanguage;
  SyntaxPalette? _cachePalette;
  List<TextSpan> _cacheSpans = const <TextSpan>[];

  List<TextSpan> _spans() {
    if (_cacheText == text &&
        _cacheLanguage == language &&
        identical(_cachePalette, palette)) {
      return _cacheSpans;
    }
    _cacheSpans = text.length > maxHighlightLength
        ? [TextSpan(text: text)]
        : buildSpans(text, language, palette);
    _cacheText = text;
    _cacheLanguage = language;
    _cachePalette = palette;
    return _cacheSpans;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(style: style, children: _spans());
  }
}
