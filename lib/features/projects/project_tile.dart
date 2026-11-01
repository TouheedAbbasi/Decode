import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../editor/editor_screen.dart';
import 'project.dart';
import 'project_providers.dart';
import 'time_format.dart';

enum _ProjectAction { rename, duplicate, delete }

class ProjectTile extends ConsumerWidget {
  const ProjectTile({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.folder_outlined, size: 28, color: scheme.onSurface),
      title: Text(
        project.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        relativeTime(project.modifiedAt),
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
      ),
      trailing: PopupMenuButton<_ProjectAction>(
        icon: Icon(Icons.more_horiz, color: scheme.onSurfaceVariant),
        onSelected: (action) => _onAction(context, ref, action),
        itemBuilder: (_) => const [
          PopupMenuItem(value: _ProjectAction.rename, child: Text('Rename')),
          PopupMenuItem(
            value: _ProjectAction.duplicate,
            child: Text('Duplicate'),
          ),
          PopupMenuItem(value: _ProjectAction.delete, child: Text('Delete')),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EditorScreen(project: project),
        ),
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _ProjectAction action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(projectsProvider.notifier);
    try {
      switch (action) {
        case _ProjectAction.rename:
          final name = await showNameDialog(
            context,
            title: 'Rename project',
            initial: project.name,
            action: 'Rename',
          );
          if (name != null) await notifier.rename(project, name);
        case _ProjectAction.duplicate:
          await notifier.duplicate(project);
          messenger.showSnackBar(
            const SnackBar(content: Text('Project duplicated')),
          );
        case _ProjectAction.delete:
          final ok = await _confirmDelete(context);
          if (ok == true) await notifier.delete(project);
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete project?'),
          content: Text(
            '"${project.name}" and all its files will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
}

Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  String initial = '',
  required String action,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) =>
          _NameDialog(title: title, initial: initial, action: action),
    );

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.initial,
    required this.action,
  });

  final String title;
  final String initial;
  final String action;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: Text(widget.action)),
      ],
    );
  }
}
