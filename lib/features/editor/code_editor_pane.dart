import 'package:flutter/material.dart';

import 'code_editing.dart';
import 'code_editor_field.dart';
import 'editor_buffer.dart';
import 'suggester.dart';

/// The editor, an autocomplete bar and the coding-symbol toolbar.
class CodeEditorPane extends StatelessWidget {
  const CodeEditorPane({
    super.key,
    required this.buffer,
    required this.fontSize,
  });

  final EditorBuffer buffer;
  final double fontSize;

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
    controller.value =
        CodeEditing.autoEdit(controller.value, newValue, buffer.language) ??
            newValue;
    buffer.focus.requestFocus();
  }

  void _apply(SuggestionResult result, Suggestion suggestion) {
    final controller = buffer.controller;
    final text = controller.text;
    final cursor = controller.selection.start;
    final newText = text.replaceRange(
      result.replaceStart,
      cursor,
      suggestion.insert,
    );
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: result.replaceStart +
            suggestion.insert.length -
            suggestion.caretBack,
      ),
    );
    buffer.focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(child: CodeEditorField(buffer: buffer, fontSize: fontSize)),
        ListenableBuilder(
          listenable: Listenable.merge([
            buffer.controller,
            buffer.focus,
            buffer.undo,
          ]),
          builder: (context, _) {
            final selection = buffer.controller.selection;
            SuggestionResult? result;
            if (buffer.focus.hasFocus &&
                selection.isValid &&
                selection.isCollapsed) {
              result = Suggester.suggest(
                buffer.controller.text,
                selection.start,
                buffer.language,
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (result != null) _suggestionBar(result, scheme),
                _toolbar(scheme),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _suggestionBar(SuggestionResult result, ColorScheme scheme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: result.items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final item = result.items[i];
          return InkWell(
            canRequestFocus: false,
            borderRadius: BorderRadius.circular(6),
            onTap: () => _apply(result, item),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: scheme.outline),
              ),
              child: Text(
                item.label,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          );
        },
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
          _textKey('Tab', () => _insert('  '), scheme),
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
          width: 42,
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
