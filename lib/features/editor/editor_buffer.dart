import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'code_editing.dart';
import 'code_language.dart';
import 'highlighting_controller.dart';

/// Everything the editor needs for one open file.
class EditorBuffer {
  EditorBuffer({
    required this.path,
    required String text,
    required this.language,
  })  : controller = HighlightingController(text: text, language: language),
        savedText = text;

  /// Path relative to the workspace root, using `/` (for example
  /// `css/style.css`).
  final String path;
  final CodeLanguage language;
  final HighlightingController controller;
  final UndoHistoryController undo = UndoHistoryController();
  final FocusNode focus = FocusNode();

  /// One stable instance, so the text field never sees a "new" formatter.
  late final List<TextInputFormatter> formatters = [
    CodeInputFormatter(language),
  ];

  String savedText;

  String get name => path.contains('/')
      ? path.substring(path.lastIndexOf('/') + 1)
      : path;

  bool get dirty => controller.text != savedText;

  void markSaved(String text) => savedText = text;

  void dispose() {
    controller.dispose();
    undo.dispose();
    focus.dispose();
  }
}
