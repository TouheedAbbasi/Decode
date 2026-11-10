import 'package:flutter/material.dart';

import 'code_actions.dart';
import 'code_editing.dart';
import 'code_editor_field.dart';
import 'code_language.dart';
import 'editor_buffer.dart';

/// The editor plus the coding-symbol toolbar. Suggestions are drawn inside
/// the editor itself (see [CodeEditorField]).
class CodeEditorPane extends StatelessWidget {
  const CodeEditorPane({
    super.key,
    required this.buffer,
    required this.fontSize,
    this.showLineNumbers = true,
    this.smartTyping = true,
    this.wrap = true,
  });

  final EditorBuffer buffer;
  final double fontSize;
  final bool showLineNumbers;
  final bool smartTyping;
  final bool wrap;

  static const _symbols = [
    '<', '>', '/', '{', '}', '(', ')', '[', ']', '"', "'", ';', ':', '=', '.',
    '#', '!', '&', '|', r'$', '-', '_', '+', '*', //
  ];

  void _insert(String value) {
    final controller = buffer.controller;
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : start;
    final newValue = TextEditingValue(
      text: text.replaceRange(start, end, value),
      selection: TextSelection.collapsed(offset: start + value.length),
    );
    controller.value = smartTyping
        ? (CodeEditing.smartEdit(controller.value, newValue, buffer.language) ??
            newValue)
        : newValue;
    buffer.focus.requestFocus();
  }

  void _indent({required bool outdent}) {
    final controller = buffer.controller;
    final selection = controller.selection;
    if (!outdent && selection.isValid && selection.isCollapsed) {
      _insert('  ');
      return;
    }
    controller.value = CodeActions.indent(controller.value, outdent: outdent);
    buffer.focus.requestFocus();
  }

  void _comment() {
    final controller = buffer.controller;
    controller.value =
        CodeActions.toggleComment(controller.value, buffer.language);
    buffer.focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: CodeEditorField(
            buffer: buffer,
            fontSize: fontSize,
            showLineNumbers: showLineNumbers,
            smartTyping: smartTyping,
            wrap: wrap,
          ),
        ),
        ListenableBuilder(
          listenable: buffer.controller,
          builder: (context, _) => _statusBar(scheme),
        ),
        ListenableBuilder(
          listenable: buffer.undo,
          builder: (context, _) => _toolbar(scheme),
        ),
      ],
    );
  }

  /// Thin VS Code style status strip: line, column, language.
  Widget _statusBar(ColorScheme scheme) {
    final controller = buffer.controller;
    final text = controller.text;
    final selection = controller.selection;
    var line = 1;
    var column = 1;
    var selected = 0;
    if (selection.isValid) {
      final offset = selection.start.clamp(0, text.length).toInt();
      for (var i = 0; i < offset; i++) {
        if (text.codeUnitAt(i) == 10) line++;
      }
      column = offset - (text.substring(0, offset).lastIndexOf('\n') + 1) + 1;
      selected = selection.end - selection.start;
    }
    final language = switch (buffer.language) {
      CodeLanguage.html => 'HTML',
      CodeLanguage.css => 'CSS',
      CodeLanguage.js => 'JavaScript',
      CodeLanguage.text => 'Text',
    };
    final style = TextStyle(color: scheme.onSurfaceVariant, fontSize: 11);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Row(
        children: [
          Text('Ln $line, Col $column', style: style),
          if (selected > 0) Text('  ($selected selected)', style: style),
          const Spacer(),
          Text('Spaces: 2   UTF-8   $language', style: style),
        ],
      ),
    );
  }

  Widget _toolbar(ColorScheme scheme) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Row(
        children: [
          _iconKey(
            Icons.undo_rounded,
            'Undo',
            buffer.undo.value.canUndo ? buffer.undo.undo : null,
            scheme,
          ),
          _iconKey(
            Icons.redo_rounded,
            'Redo',
            buffer.undo.value.canRedo ? buffer.undo.redo : null,
            scheme,
          ),
          _iconKey(
            Icons.format_indent_increase_rounded,
            'Indent',
            () => _indent(outdent: false),
            scheme,
          ),
          _iconKey(
            Icons.format_indent_decrease_rounded,
            'Outdent',
            () => _indent(outdent: true),
            scheme,
          ),
          _textKey('//', _comment, scheme),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _symbols.length,
              itemBuilder: (_, i) =>
                  _textKey(_symbols[i], () => _insert(_symbols[i]), scheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconKey(
    IconData icon,
    String tooltip,
    VoidCallback? onTap,
    ColorScheme scheme,
  ) {
    return InkWell(
      canRequestFocus: false,
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: 40,
          height: 46,
          child: Icon(
            icon,
            size: 20,
            color: onTap == null
                ? scheme.onSurfaceVariant.withAlpha(90)
                : scheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _textKey(String label, VoidCallback onTap, ColorScheme scheme) {
    return InkWell(
      canRequestFocus: false,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 38),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
