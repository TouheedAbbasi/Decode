import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/preview/preview_source.dart';
import '../../core/settings/settings_providers.dart';
import '../preview/preview_screen.dart';
import '../projects/project.dart';
import '../projects/project_providers.dart';
import '../projects/project_repository.dart';
import 'code_editor_pane.dart';
import 'code_language.dart';
import 'editor_buffer.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, required this.project});

  final Project project;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  static const _autosaveDelay = Duration(seconds: 2);
  static const _preferredOrder = ['index.html', 'style.css', 'script.js'];

  final List<EditorBuffer> _buffers = [];
  int _index = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Timer? _autosave;

  bool get _anyDirty => _buffers.any((b) => b.dirty);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _autosave?.cancel();
    for (final buffer in _buffers) {
      buffer.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = await ref.read(projectRepositoryProvider.future);
      final files = await repo.listFiles(widget.project);
      final names = [
        for (final (name, _) in files)
          if (_isEditable(name)) name,
      ]..sort(_compareNames);

      final buffers = <EditorBuffer>[];
      for (final name in names) {
        final text = await repo.readFile(widget.project, name);
        final buffer = EditorBuffer(
          name: name,
          text: text,
          language: CodeLanguage.fromFileName(name),
        );
        buffer.controller.addListener(_onChanged);
        buffers.add(buffer);
      }
      if (!mounted) {
        for (final buffer in buffers) {
          buffer.dispose();
        }
        return;
      }
      setState(() {
        _buffers.addAll(buffers);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not open this project.';
      });
    }
  }

  bool _isEditable(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return false;
    return ProjectRepository.editableExtensions
        .contains(name.substring(dot).toLowerCase());
  }

  int _compareNames(String a, String b) {
    final ia = _preferredOrder.indexOf(a);
    final ib = _preferredOrder.indexOf(b);
    if (ia >= 0 || ib >= 0) {
      return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
    }
    return a.compareTo(b);
  }

  void _onChanged() {
    _autosave?.cancel();
    _autosave = Timer(_autosaveDelay, () => _saveAll(silent: true));
    if (mounted) setState(() {});
  }

  Future<void> _saveAll({bool silent = false}) async {
    _autosave?.cancel();
    if (_saving) return;
    final dirty = _buffers.where((b) => b.dirty).toList();
    if (dirty.isEmpty) {
      if (!silent) _toast('Saved');
      return;
    }
    _saving = true;
    try {
      final notifier = ref.read(projectsProvider.notifier);
      for (final buffer in dirty) {
        final text = buffer.controller.text;
        await notifier.saveFile(widget.project, buffer.name, text);
        buffer.markSaved(text);
      }
      if (!silent) _toast('Saved');
    } catch (_) {
      _toast('Could not save. Please try again.');
    } finally {
      _saving = false;
      if (mounted) setState(() {});
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPreview() async {
    await _saveAll(silent: true);
    if (!mounted) return;
    final entry = _buffers.any((b) => b.name == 'index.html')
        ? 'index.html'
        : _buffers.firstWhere(
            (b) => b.language == CodeLanguage.html,
            orElse: () => _buffers.first,
          ).name;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PreviewScreen(
          entry: entry,
          source: OverlaySource(
            overrides: _currentFiles,
            base: DirectorySource(Directory(widget.project.path)),
          ),
        ),
      ),
    );
  }

  Map<String, String> _currentFiles() => {
        for (final b in _buffers) b.name: b.controller.text,
      };

  Future<void> _onPop() async {
    await _saveAll(silent: true);
    if (!mounted) return;
    if (_anyDirty) return; // Save failed: stay so nothing is lost.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(editorFontSizeProvider);
    final dirty = _anyDirty;

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            dirty ? '${widget.project.name} \u2022' : widget.project.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              tooltip: 'Save',
              icon: const Icon(Icons.save_outlined),
              onPressed: _buffers.isEmpty ? null : () => _saveAll(),
            ),
            IconButton(
              tooltip: 'Preview',
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: _buffers.isEmpty ? null : _openPreview,
            ),
          ],
        ),
        body: _buildBody(fontSize),
      ),
    );
  }

  Widget _buildBody(double fontSize) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_buffers.isEmpty) {
      return const Center(child: Text('This project has no editable files.'));
    }
    final buffer = _buffers[_index];
    return Column(
      children: [
        _FileTabs(
          buffers: _buffers,
          selected: _index,
          onSelect: (i) => setState(() => _index = i),
        ),
        Expanded(
          child: CodeEditorPane(
            key: ValueKey(buffer.name),
            buffer: buffer,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}

class _FileTabs extends StatelessWidget {
  const _FileTabs({
    required this.buffers,
    required this.selected,
    required this.onSelect,
  });

  final List<EditorBuffer> buffers;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outline)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: buffers.length,
        itemBuilder: (_, i) {
          final buffer = buffers[i];
          final active = i == selected;
          return InkWell(
            onTap: () => onSelect(i),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? scheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                buffer.dirty ? '${buffer.name} \u2022' : buffer.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
