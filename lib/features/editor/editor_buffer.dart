import 'package:flutter/material.dart';

import 'code_language.dart';
import 'highlighting_controller.dart';

/// Everything the editor needs for one open file.
class EditorBuffer {
  EditorBuffer({
    required this.name,
    required String text,
    required this.language,
  })  : controller = HighlightingController(text: text, language: language),
        savedText = text;

  final String name;
  final CodeLanguage language;
  final HighlightingController controller;
  final UndoHistoryController undo = UndoHistoryController();
  final FocusNode focus = FocusNode();

  String savedText;

  bool get dirty => controller.text != savedText;

  void markSaved(String text) => savedText = text;

  void dispose() {
    controller.dispose();
    undo.dispose();
    focus.dispose();
  }
}
