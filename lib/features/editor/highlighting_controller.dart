import 'package:flutter/material.dart';

import 'code_language.dart';
import 'syntax_highlighter.dart';

/// A text controller that colours its text by [language].
class HighlightingController extends TextEditingController {
  HighlightingController({super.text, required this.language});

  CodeLanguage language;
  SyntaxPalette palette = SyntaxPalette.light;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(style: style, children: buildSpans(text, language, palette));
  }
}
