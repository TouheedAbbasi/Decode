import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/preview/preview_source.dart';
import '../preview/preview_screen.dart';
import '../projects/project_providers.dart';
import '../projects/project_tile.dart' show showNameDialog;
import 'component_item.dart';
import 'component_studio_screen.dart';
import 'user_components.dart';

enum _MenuAction { copyToMine, edit, delete }

class ComponentDetailScreen extends ConsumerStatefulWidget {
  const ComponentDetailScreen({super.key, required this.item});

  final ComponentItem item;

  @override
  ConsumerState<ComponentDetailScreen> createState() =>
      _ComponentDetailScreenState();
}

class _ComponentDetailScreenState extends ConsumerState<ComponentDetailScreen>
    with SingleTickerProviderStateMixin {
  late final List<(String, String)> _tabs;
  late final TabController _controller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _tabs = [
      ('HTML', item.html),
      if (item.css.isNotEmpty) ('CSS', item.css),
      if (item.js.isNotEmpty) ('JS', item.js),
    ];
    _controller = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyCurrent() async {
    final (label, code) = _tabs[_controller.index];
    await Clipboard.setData(ClipboardData(text: code));
    _toast('$label code copied');
  }

  void _preview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PreviewScreen(source: MemorySource(widget.item.toFiles())),
      ),
    );
  }

  Future<void> _useInNewProject() async {
    final name = await showNameDialog(
      context,
      title: 'New project name',
      initial: widget.item.name,
      action: 'Create',
    );
    if (name == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(projectsProvider.notifier)
          .create(name: name, template: widget.item.toTemplate());
      _toast('Project "$name" created');
    } catch (_) {
      _toast('Could not create the project.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onMenu(_MenuAction action) async {
    final navigator = Navigator.of(context);
    switch (action) {
      case _MenuAction.copyToMine:
        final savedCopy = await navigator.push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => ComponentStudioScreen(initial: widget.item),
          ),
        );
        if (savedCopy == true) _toast('Saved to My Components');
      case _MenuAction.edit:
        final savedEdit = await navigator.push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => ComponentStudioScreen(initial: widget.item),
          ),
        );
        if (savedEdit == true && mounted) navigator.pop();
      case _MenuAction.delete:
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete component?'),
            content: Text('"${widget.item.name}" will be permanently deleted.'),
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
        if (ok == true) {
          await ref
              .read(userComponentsProvider.notifier)
              .delete(widget.item.id);
          if (mounted) navigator.pop();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.item.isUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name),
        actions: [
          IconButton(
            tooltip: 'Copy code',
            icon: const Icon(Icons.copy_rounded),
            onPressed: _copyCurrent,
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: _onMenu,
            itemBuilder: (_) => [
              if (isUser) ...const [
                PopupMenuItem(value: _MenuAction.edit, child: Text('Edit')),
                PopupMenuItem(value: _MenuAction.delete, child: Text('Delete')),
              ] else
                const PopupMenuItem(
                  value: _MenuAction.copyToMine,
                  child: Text('Customize in My Components'),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _controller,
          tabs: [for (final t in _tabs) Tab(text: t.$1)],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [for (final t in _tabs) _CodeView(code: t.$2)],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _preview,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Preview'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _useInNewProject,
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: const Text('Use in new project'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeView extends StatelessWidget {
  const _CodeView({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
