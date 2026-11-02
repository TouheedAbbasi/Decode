import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/preview/preview_source.dart';
import '../../core/settings/settings_providers.dart';
import '../preview/preview_screen.dart';
import 'code_editor_pane.dart';
import 'code_language.dart';
import 'editor_buffer.dart';
import 'explorer_drawer.dart';
import 'find_replace_bar.dart';
import 'workspace.dart';

/// The code editor for a [Workspace]: one of Decode's projects, or a real
/// folder on the phone.
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, required this.workspace, this.initialFile});

  final Workspace workspace;

  /// Relative path of a file to open first.
  final String? initialFile;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  static const _autosaveDelay = Duration(seconds: 2);
  static const _preferredFiles = ['index.html', 'style.css', 'script.js'];

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<EditorBuffer> _buffers = [];
  final Set<String> _opening = {};
  Set<String> _dirtyPaths = {};
  int _index = 0;
  bool _loading = true;
  bool _saving = false;
  bool _showFind = false;
  String? _error;
  Timer? _autosave;

  Workspace get _workspace => widget.workspace;

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
      final root = await _workspace.list('');
      final files = {
        for (final e in root)
          if (!e.isDirectory && _workspace.isEditable(e.path)) e.path,
      };
      final first = widget.initialFile != null
          ? [widget.initialFile!]
          : [for (final f in _preferredFiles) if (files.contains(f)) f];
      for (final path in first) {
        await _openFile(path);
      }
      if (!mounted) return;
      setState(() => _loading = false);
      if (_buffers.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scaffoldKey.currentState?.openDrawer(),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not open this folder. Check storage permission.';
      });
    }
  }

  Future<void> _openFile(String path) async {
    final existing = _buffers.indexWhere((b) => b.path == path);
    if (existing >= 0) {
      if (mounted) setState(() => _index = existing);
      return;
    }
    if (!_opening.add(path)) return;
    try {
      final text = await _workspace.read(path);
      if (!mounted) return;
      final buffer = EditorBuffer(
        path: path,
        text: text,
        language: CodeLanguage.fromFileName(path),
      );
      buffer.controller.addListener(_onChanged);
      setState(() {
        _buffers.add(buffer);
        _index = _buffers.length - 1;
      });
    } on FileSystemException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not open $path');
    } finally {
      _opening.remove(path);
    }
  }

  void _onChanged() {
    _autosave?.cancel();
    if (ref.read(autosaveProvider)) {
      _autosave = Timer(_autosaveDelay, () => _saveAll(silent: true));
    }
    // Rebuild only when a "modified" dot appears or disappears, not on
    // every keystroke.
    final now = {
      for (final b in _buffers)
        if (b.dirty) b.path,
    };
    if (!setEquals(now, _dirtyPaths)) {
      _dirtyPaths = now;
      if (mounted) setState(() {});
    }
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
      for (final buffer in dirty) {
        final text = buffer.controller.text;
        await _workspace.write(buffer.path, text);
        buffer.markSaved(text);
      }
      if (!silent) _toast('Saved');
    } catch (_) {
      _toast('Could not save. Check storage permission.');
    } finally {
      _saving = false;
      _dirtyPaths = {
        for (final b in _buffers)
          if (b.dirty) b.path,
      };
      if (mounted) setState(() {});
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _closeTab(int index) async {
    final buffer = _buffers[index];
    if (buffer.dirty) {
      await _saveAll(silent: true);
      if (buffer.dirty) return; // Saving failed: keep the tab open.
    }
    if (!mounted) return;
    setState(() {
      _buffers.removeAt(index);
      if (_index >= _buffers.length) _index = _buffers.length - 1;
      if (_index < 0) _index = 0;
      _dirtyPaths = {
        for (final b in _buffers)
          if (b.dirty) b.path,
      };
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => buffer.dispose());
  }

  String? _previewEntry() {
    final active = _buffers.isEmpty ? null : _buffers[_index];
    if (active != null && active.language == CodeLanguage.html) {
      return active.path;
    }
    if (_buffers.any((b) => b.path == 'index.html')) return 'index.html';
    if (File(p.join(_workspace.rootPath, 'index.html')).existsSync()) {
      return 'index.html';
    }
    for (final b in _buffers) {
      if (b.language == CodeLanguage.html) return b.path;
    }
    return null;
  }

  Future<void> _openPreview() async {
    final entry = _previewEntry();
    if (entry == null) {
      _toast('Open an HTML file to preview it.');
      return;
    }
    await _saveAll(silent: true);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PreviewScreen(
          entry: entry,
          source: OverlaySource(
            overrides: _currentFiles,
            base: DirectorySource(Directory(_workspace.rootPath)),
          ),
        ),
      ),
    );
  }

  Map<String, String> _currentFiles() => {
        for (final b in _buffers) b.path: b.controller.text,
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
    final dirty = _dirtyPaths.isNotEmpty;

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPop();
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawerEnableOpenDragGesture: false,
        drawer: ExplorerDrawer(
          workspace: _workspace,
          activePath: _buffers.isEmpty ? null : _buffers[_index].path,
          onOpen: (path) {
            _scaffoldKey.currentState?.closeDrawer();
            _openFile(path);
          },
        ),
        appBar: AppBar(
          title: Text(
            dirty ? '${_workspace.title} \u2022' : _workspace.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              tooltip: 'Files',
              icon: const Icon(Icons.folder_open_rounded),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            IconButton(
              tooltip: 'Find and replace',
              icon: const Icon(Icons.search_rounded),
              onPressed: _buffers.isEmpty
                  ? null
                  : () => setState(() => _showFind = !_showFind),
            ),
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
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (_buffers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Open a file from the Files panel to start editing.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Show files'),
              ),
            ],
          ),
        ),
      );
    }
    final buffer = _buffers[_index];
    return Column(
      children: [
        _FileTabs(
          buffers: _buffers,
          selected: _index,
          dirtyPaths: _dirtyPaths,
          onSelect: (i) => setState(() => _index = i),
          onClose: _closeTab,
        ),
        if (_showFind)
          FindReplaceBar(
            key: ValueKey('find_${buffer.path}'),
            buffer: buffer,
            onClose: () => setState(() => _showFind = false),
          ),
        Expanded(
          child: CodeEditorPane(
            key: ValueKey(buffer.path),
            buffer: buffer,
            fontSize: fontSize,
            showLineNumbers: ref.watch(lineNumbersProvider),
            smartTyping: ref.watch(smartTypingProvider),
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
    required this.dirtyPaths,
    required this.onSelect,
    required this.onClose,
  });

  final List<EditorBuffer> buffers;
  final int selected;
  final Set<String> dirtyPaths;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onClose;

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
          final dirty = dirtyPaths.contains(buffer.path);
          return InkWell(
            onTap: () => onSelect(i),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(left: 16, right: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? scheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    dirty ? '${buffer.name} \u2022' : buffer.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                  InkWell(
                    onTap: () => onClose(i),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
