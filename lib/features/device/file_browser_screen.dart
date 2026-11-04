import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/storage/storage_access.dart';
import '../editor/workspace.dart';
import 'device_files.dart';

/// A simple file manager for the phone's storage. Pick a folder to open it
/// as a project, or tap an HTML / CSS / JS file to edit it directly.
class FileBrowserScreen extends ConsumerStatefulWidget {
  const FileBrowserScreen({super.key, this.pickFile = false});

  /// When true, tapping any file returns its path instead of opening it.
  final bool pickFile;

  @override
  ConsumerState<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends ConsumerState<FileBrowserScreen> {
  static const _root = '/storage/emulated/0';

  Directory? _dir;
  List<FileSystemEntity> _entries = const [];
  bool _checking = true;
  bool _denied = false;
  String? _error;

  final _editor = DirectoryWorkspace(rootPath: _root, title: 'root');

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _checking = true;
      _denied = false;
    });
    final granted = await ensureStorageAccess();
    if (!mounted) return;
    if (!granted) {
      setState(() {
        _checking = false;
        _denied = true;
      });
      return;
    }
    final start = Directory(_root);
    await _go(await start.exists() ? start : Directory.current);
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _go(Directory dir) async {
    try {
      final items = await dir.list(followLinks: false).toList();
      items.removeWhere((e) => p.basename(e.path).startsWith('.'));
      items.sort((a, b) {
        final aDir = a is Directory;
        final bDir = b is Directory;
        if (aDir != bDir) return aDir ? -1 : 1;
        return p
            .basename(a.path)
            .toLowerCase()
            .compareTo(p.basename(b.path).toLowerCase());
      });
      if (!mounted) return;
      setState(() {
        _dir = dir;
        _entries = items;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not read this folder.');
    }
  }

  bool get _atTop => _dir == null || p.equals(_dir!.path, _root) || _dir!.parent.path == _dir!.path;

  void _up() {
    final dir = _dir;
    if (dir == null || _atTop) return;
    _go(dir.parent);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dir = _dir;

    return PopScope(
      canPop: _atTop || _denied || _checking,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _up();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            dir == null
                ? (widget.pickFile ? 'Choose a file' : 'Open from device')
                : (p.basename(dir.path).isEmpty ? 'Storage' : p.basename(dir.path)),
          ),
          actions: [
            if (!_atTop)
              IconButton(
                tooltip: 'Up one folder',
                icon: const Icon(Icons.arrow_upward_rounded),
                onPressed: _up,
              ),
          ],
        ),
        body: _body(scheme),
        bottomNavigationBar: dir == null || _denied || widget.pickFile
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: FilledButton.icon(
                    onPressed: () =>
                        openDeviceFolder(context, ref, dir.path, replace: true),
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('Open this folder'),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _body(ColorScheme scheme) {
    if (_checking) return const Center(child: CircularProgressIndicator());
    if (_denied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Decode needs access to your files to open folders from your '
                'phone and save changes back to them.\n\nTurn on '
                '"Allow access to manage all files" for Decode, then come back.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  await openStorageSettings();
                },
                child: const Text('Open settings'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: _start, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    if (_error != null) return Center(child: Text(_error!));

    final dir = _dir!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              dir.path,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final entry in const {
                'Internal storage': _root,
                'Documents': '$_root/Documents',
                'Download': '$_root/Download',
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(entry.key),
                    onPressed: () async {
                      final target = Directory(entry.value);
                      if (await target.exists()) await _go(target);
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _entries.isEmpty
              ? Center(
                  child: Text(
                    'This folder is empty',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (_, i) => _row(_entries[i], scheme),
                ),
        ),
      ],
    );
  }

  Widget _row(FileSystemEntity entity, ColorScheme scheme) {
    final name = p.basename(entity.path);
    final isDir = entity is Directory;
    final editable = !isDir && (widget.pickFile || _editor.isEditable(name));
    return ListTile(
      dense: true,
      leading: Icon(
        isDir ? Icons.folder_rounded : Icons.insert_drive_file_outlined,
        color: isDir || editable
            ? scheme.onSurface
            : scheme.onSurfaceVariant.withAlpha(110),
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isDir || editable
              ? scheme.onSurface
              : scheme.onSurfaceVariant.withAlpha(140),
        ),
      ),
      trailing: isDir ? const Icon(Icons.chevron_right_rounded) : null,
      onTap: () {
        if (isDir) {
          _go(entity);
        } else if (widget.pickFile) {
          Navigator.of(context).pop(entity.path);
        } else if (editable) {
          openDeviceFolder(
            context,
            ref,
            p.dirname(entity.path),
            initialFile: name,
            replace: true,
          );
        }
      },
    );
  }
}
