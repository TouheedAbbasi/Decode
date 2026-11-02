import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/preview/preview_source.dart';
import '../../core/settings/settings_providers.dart';
import '../editor/code_editor_pane.dart';
import '../editor/code_language.dart';
import '../editor/editor_buffer.dart';
import '../preview/preview_screen.dart';
import 'component_item.dart';
import 'component_library.dart';
import 'user_components.dart';

/// Create or edit one of your own components.
///
/// Pass [initial] with `isUser == true` to edit it, or any other item to start
/// a new component from a copy of it.
class ComponentStudioScreen extends ConsumerStatefulWidget {
  const ComponentStudioScreen({super.key, this.initial});

  final ComponentItem? initial;

  @override
  ConsumerState<ComponentStudioScreen> createState() =>
      _ComponentStudioScreenState();
}

class _ComponentStudioScreenState extends ConsumerState<ComponentStudioScreen> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final EditorBuffer _html;
  late final EditorBuffer _css;
  late final EditorBuffer _js;
  late String _category;
  late final String _id;
  late final bool _editing;
  int _tab = 0;
  bool _saving = false;

  List<EditorBuffer> get _buffers => [_html, _css, _js];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _editing = initial?.isUser ?? false;
    _id = _editing ? initial!.id : UserComponentsNotifier.newId();
    _name = TextEditingController(
      text: initial == null
          ? ''
          : (_editing ? initial.name : '${initial.name} copy'),
    );
    _description = TextEditingController(text: initial?.description ?? '');
    _category = (initial != null && userCategories.contains(initial.category))
        ? initial.category
        : 'UI';
    _html = EditorBuffer(
      path: 'index.html',
      text: initial?.html ?? '',
      language: CodeLanguage.html,
    );
    _css = EditorBuffer(
      path: 'style.css',
      text: initial?.css ?? '',
      language: CodeLanguage.css,
    );
    _js = EditorBuffer(
      path: 'script.js',
      text: initial?.js ?? '',
      language: CodeLanguage.js,
    );
    for (final buffer in _buffers) {
      buffer.focus.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    for (final buffer in _buffers) {
      buffer.focus.removeListener(_refresh);
      buffer.dispose();
    }
    super.dispose();
  }

  ComponentItem _build() => ComponentItem(
        id: _id,
        name: _name.text.trim().isEmpty ? 'Untitled' : _name.text.trim(),
        description: _description.text.trim(),
        category: _category,
        icon: Icons.extension_outlined,
        html: _html.controller.text,
        css: _css.controller.text,
        js: _js.controller.text,
        isUser: true,
      );

  void _quickPreview() {
    final files = _build().toFiles();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PreviewScreen(source: MemorySource(files)),
      ),
    );
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_name.text.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter a name')));
      return;
    }
    if (_html.controller.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Add some HTML first')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(userComponentsProvider.notifier).upsert(_build());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the component.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fontSize = ref.watch(editorFontSizeProvider);
    final buffer = _buffers[_tab];
    final typing = _buffers.any((b) => b.focus.hasFocus);
    const labels = ['HTML', 'CSS', 'JS'];

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit Component' : 'New Component'),
        actions: [
          IconButton(
            tooltip: 'Quick preview',
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: _quickPreview,
          ),
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.check_rounded),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!typing) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _name,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      hintText: 'Component name',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _description,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      hintText: 'Short description (optional)',
                      counterText: '',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: userCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChip(
                  label: Text(userCategories[i]),
                  selected: _category == userCategories[i],
                  showCheckmark: false,
                  onSelected: (_) =>
                      setState(() => _category = userCategories[i]),
                ),
              ),
            ),
          ],
          Container(
            height: 42,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: scheme.outline),
                bottom: BorderSide(color: scheme.outline),
              ),
            ),
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: i == _tab
                                  ? scheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: i == _tab
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: CodeEditorPane(
              key: ValueKey(buffer.name),
              buffer: buffer,
              fontSize: fontSize,
              showLineNumbers: ref.watch(lineNumbersProvider),
              smartTyping: ref.watch(smartTypingProvider),
            ),
          ),
        ],
      ),
    );
  }
}
