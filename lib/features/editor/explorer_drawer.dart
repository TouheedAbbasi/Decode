import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../device/file_browser_screen.dart';
import '../projects/project_tile.dart' show showNameDialog;
import 'workspace.dart';

/// VS Code style file explorer shown in the editor's side drawer.
class ExplorerDrawer extends StatefulWidget {
  const ExplorerDrawer({
    super.key,
    required this.workspace,
    required this.activePath,
    required this.onOpen,
  });

  final Workspace workspace;
  final String? activePath;

  /// Called with the relative path of a file the user tapped or created.
  final void Function(String path) onOpen;

  @override
  State<ExplorerDrawer> createState() => _ExplorerDrawerState();
}

class _ExplorerDrawerState extends State<ExplorerDrawer> {
  final Map<String, List<WorkspaceEntry>> _children = {};
  final Set<String> _expanded = {};
  String _selectedDir = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  Future<void> _load(String dir) async {
    try {
      final items = await widget.workspace.list(dir);
      if (!mounted) return;
      setState(() {
        _children[dir] = items;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not read this folder.');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _join(String dir, String name) => dir.isEmpty ? name : '$dir/$name';

  bool _validName(String name) =>
      name.isNotEmpty &&
      !name.contains('/') &&
      !name.contains(r'\') &&
      name != '.' &&
      name != '..';

  Future<void> _create({required bool folder}) async {
    final name = await showNameDialog(
      context,
      title: folder ? 'New folder' : 'New file',
      initial: folder ? '' : 'untitled.html',
      action: 'Create',
    );
    if (name == null) return;
    if (!_validName(name)) {
      _toast('Use a simple name without slashes.');
      return;
    }
    final path = _join(_selectedDir, name);
    try {
      if (folder) {
        await widget.workspace.createFolder(path);
      } else {
        await widget.workspace.createFile(path);
      }
      await _load(_selectedDir);
      if (!folder && mounted) widget.onOpen(path);
    } on FileSystemException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not create it. Check storage permission.');
    }
  }

  /// Copies a file (for example an image) from the phone into the project.
  Future<void> _importFile() async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const FileBrowserScreen(pickFile: true),
      ),
    );
    if (picked == null || !mounted) return;
    final dest = _selectedDir.isEmpty ? 'img' : _selectedDir;
    try {
      final relative = await widget.workspace.importFile(picked, dest);
      _children.clear();
      _expanded.add(dest);
      await _load('');
      await _load(dest);
      await Clipboard.setData(ClipboardData(text: relative));
      if (mounted) _toast('Added $relative (path copied). Use it as src="$relative"');
    } on FileSystemException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not add the file.');
    }
  }

  List<Widget> _rows(String dir, int depth) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <Widget>[];
    for (final entry in _children[dir] ?? const <WorkspaceEntry>[]) {
      final editable =
          entry.isDirectory || widget.workspace.isEditable(entry.path);
      final open = _expanded.contains(entry.path);
      final active = entry.path == widget.activePath;
      rows.add(
        InkWell(
          onTap: () {
            if (entry.isDirectory) {
              setState(() {
                _selectedDir = entry.path;
                if (!_expanded.remove(entry.path)) _expanded.add(entry.path);
              });
              if (!_children.containsKey(entry.path)) _load(entry.path);
            } else if (editable) {
              widget.onOpen(entry.path);
            } else {
              _toast('${entry.name} cannot be edited here.');
            }
          },
          child: Container(
            color: active ? scheme.primaryContainer : null,
            padding: EdgeInsets.fromLTRB(12.0 + depth * 16, 9, 12, 9),
            child: Row(
              children: [
                Icon(
                  entry.isDirectory
                      ? (open
                          ? Icons.folder_open_rounded
                          : Icons.folder_rounded)
                      : Icons.insert_drive_file_outlined,
                  size: 18,
                  color: editable
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant.withAlpha(120),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: editable
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant.withAlpha(120),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (entry.isDirectory && open) rows.addAll(_rows(entry.path, depth + 1));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      width: 300,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.workspace.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'New file',
                    icon: const Icon(Icons.note_add_outlined),
                    onPressed: () => _create(folder: false),
                  ),
                  IconButton(
                    tooltip: 'Add a file or image from the phone',
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    onPressed: _importFile,
                  ),
                  IconButton(
                    tooltip: 'New folder',
                    icon: const Icon(Icons.create_new_folder_outlined),
                    onPressed: () => _create(folder: true),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () {
                      _children.clear();
                      _load('');
                      for (final dir in _expanded.toList()) {
                        _load(dir);
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _selectedDir.isEmpty
                    ? widget.workspace.rootPath
                    : '${widget.workspace.title}/$_selectedDir',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
              ),
            ),
            Divider(color: scheme.outline),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: TextStyle(color: scheme.error)),
              ),
            Expanded(
              child: _children.containsKey('')
                  ? ListView(children: _rows('', 0))
                  : const Center(child: CircularProgressIndicator()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'New files and folders are created in the highlighted folder.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
