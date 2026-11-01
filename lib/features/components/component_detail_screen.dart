import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../projects/project_providers.dart';
import '../projects/project_tile.dart' show showNameDialog;
import 'component_item.dart';

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

  Future<void> _copyCurrent() async {
    final (label, code) = _tabs[_controller.index];
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label code copied')),
    );
  }

  Future<void> _useInNewProject() async {
    final messenger = ScaffoldMessenger.of(context);
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
      messenger.showSnackBar(
        SnackBar(content: Text('Project "$name" created')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not create the project.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name),
        actions: [
          IconButton(
            tooltip: 'Copy code',
            icon: const Icon(Icons.copy_rounded),
            onPressed: _copyCurrent,
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
          child: FilledButton.icon(
            onPressed: _busy ? null : _useInNewProject,
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('Use in new project'),
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
