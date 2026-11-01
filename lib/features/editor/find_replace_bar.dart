import 'package:flutter/material.dart';

import 'editor_buffer.dart';

/// Find / replace for one open file.
class FindReplaceBar extends StatefulWidget {
  const FindReplaceBar({super.key, required this.buffer, required this.onClose});

  final EditorBuffer buffer;
  final VoidCallback onClose;

  @override
  State<FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends State<FindReplaceBar> {
  final _find = TextEditingController();
  final _replace = TextEditingController();
  bool _matchCase = false;

  @override
  void dispose() {
    _find.dispose();
    _replace.dispose();
    super.dispose();
  }

  TextEditingController get _text => widget.buffer.controller;

  RegExp? get _regex {
    final query = _find.text;
    if (query.isEmpty) return null;
    return RegExp(RegExp.escape(query), caseSensitive: _matchCase);
  }

  int get _count => _regex?.allMatches(_text.text).length ?? 0;

  void _select(RegExpMatch match) {
    _text.selection =
        TextSelection(baseOffset: match.start, extentOffset: match.end);
    widget.buffer.focus.requestFocus();
  }

  void _step({required bool forward}) {
    final regex = _regex;
    if (regex == null) return;
    final matches = regex.allMatches(_text.text).toList();
    if (matches.isEmpty) {
      setState(() {});
      return;
    }
    final selection = _text.selection;
    final from = selection.isValid
        ? (forward ? selection.end : selection.start)
        : 0;
    final target = forward
        ? matches.firstWhere((m) => m.start >= from, orElse: () => matches.first)
        : matches.lastWhere((m) => m.end <= from, orElse: () => matches.last);
    _select(target);
  }

  void _replaceCurrent() {
    final regex = _regex;
    if (regex == null) return;
    final selection = _text.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final selected = _text.text.substring(selection.start, selection.end);
      final match = regex.matchAsPrefix(selected);
      if (match != null && match.end == selected.length) {
        final replacement = _replace.text;
        _text.value = TextEditingValue(
          text: _text.text.replaceRange(
            selection.start,
            selection.end,
            replacement,
          ),
          selection: TextSelection.collapsed(
            offset: selection.start + replacement.length,
          ),
        );
      }
    }
    _step(forward: true);
  }

  void _replaceAll() {
    final regex = _regex;
    if (regex == null) return;
    final replacement = _replace.text;
    final updated = _text.text.replaceAllMapped(regex, (_) => replacement);
    if (updated == _text.text) return;
    _text.value = TextEditingValue(
      text: updated,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const fieldPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 10);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outline)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _find,
                  decoration: const InputDecoration(
                    hintText: 'Find',
                    isDense: true,
                    contentPadding: fieldPadding,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _step(forward: true),
                ),
              ),
              const SizedBox(width: 6),
              ListenableBuilder(
                listenable: _text,
                builder: (_, __) => SizedBox(
                  width: 30,
                  child: Text(
                    '$_count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              _key(
                label: 'Aa',
                active: _matchCase,
                tooltip: 'Match case',
                onTap: () => setState(() => _matchCase = !_matchCase),
                scheme: scheme,
              ),
              _iconKey(Icons.keyboard_arrow_up_rounded, 'Previous',
                  () => _step(forward: false)),
              _iconKey(Icons.keyboard_arrow_down_rounded, 'Next',
                  () => _step(forward: true)),
              _iconKey(Icons.close_rounded, 'Close', widget.onClose),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replace,
                  decoration: const InputDecoration(
                    hintText: 'Replace with',
                    isDense: true,
                    contentPadding: fieldPadding,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: _replaceCurrent,
                child: const Text('Replace'),
              ),
              TextButton(
                onPressed: _replaceAll,
                child: const Text('All'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _key({
    required String label,
    required bool active,
    required String tooltip,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        canRequestFocus: false,
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? scheme.primaryContainer : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconKey(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon),
      onPressed: onTap,
    );
  }
}
