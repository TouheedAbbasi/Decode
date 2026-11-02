import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/storage/storage_access.dart';
import '../editor/editor_screen.dart';
import '../editor/workspace.dart';
import 'file_browser_screen.dart';
import 'recent_folders.dart';

/// Opens a real folder from the phone in the editor. Files are read and
/// saved in place, so other apps see the changes.
Future<void> openDeviceFolder(
  BuildContext context,
  WidgetRef ref,
  String path, {
  String? initialFile,
  bool replace = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  if (!await ensureStorageAccess()) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Storage access is needed to open folders.')),
    );
    return;
  }
  if (!await Directory(path).exists()) {
    await ref.read(recentFoldersProvider.notifier).remove(path);
    messenger.showSnackBar(
      const SnackBar(content: Text('That folder no longer exists.')),
    );
    return;
  }

  await ref.read(recentFoldersProvider.notifier).add(path);
  final route = MaterialPageRoute<void>(
    builder: (_) => EditorScreen(
      workspace: DirectoryWorkspace(
        rootPath: path,
        title: p.basename(path).isEmpty ? path : p.basename(path),
        atomic: false,
      ),
      initialFile: initialFile,
    ),
  );
  if (replace) {
    await navigator.pushReplacement(route);
  } else {
    await navigator.push(route);
  }
}

/// Shows the file browser so the user can pick a folder or a file.
Future<void> pickFromDevice(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FileBrowserScreen()),
    );
