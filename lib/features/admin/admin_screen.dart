import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/preview/preview_source.dart';
import '../components/component_backup.dart';
import '../components/component_item.dart';
import '../components/component_library.dart';
import '../components/online_components.dart';
import '../components/component_studio_screen.dart';
import '../components/user_components.dart';
import '../preview/preview_screen.dart';
import '../projects/project_providers.dart';

enum _ExportMode { copy, share }

enum _RowAction { edit, preview, duplicate, delete }

/// Manage everything you built: stats, search, bulk actions, backup/import.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final Set<String> _selected = {};
  String _query = '';
  String _category = 'All';

  bool get _selecting => _selected.isNotEmpty;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<ComponentItem> _visible(List<ComponentItem> all) {
    return all.where((c) {
      final inCategory = _category == 'All' || c.category == _category;
      final inQuery = _query.isEmpty ||
          c.name.toLowerCase().contains(_query) ||
          c.description.toLowerCase().contains(_query);
      return inCategory && inQuery;
    }).toList();
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  Future<void> _create() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const ComponentStudioScreen()),
    );
  }

  Future<void> _edit(ComponentItem item) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ComponentStudioScreen(initial: item),
      ),
    );
  }

  void _preview(ComponentItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PreviewScreen(source: MemorySource(item.toFiles())),
      ),
    );
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _delete(Set<String> ids, String label) async {
    final ok = await _confirm(
      'Delete $label?',
      'This cannot be undone. Export a backup first if you may need it.',
      'Delete',
    );
    if (!ok) return;
    try {
      await ref.read(userComponentsProvider.notifier).deleteMany(ids);
      if (mounted) setState(_selected.clear);
      _toast('Deleted');
    } catch (_) {
      _toast('Could not delete. Please try again.');
    }
  }

  Future<void> _moveSelected() async {
    final category = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Move to category'),
        children: [
          for (final c in userCategories)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(c),
              child: Text(c),
            ),
        ],
      ),
    );
    if (category == null) return;
    try {
      await ref
          .read(userComponentsProvider.notifier)
          .moveMany(Set.of(_selected), category);
      if (mounted) setState(_selected.clear);
      _toast('Moved to $category');
    } catch (_) {
      _toast('Could not move. Please try again.');
    }
  }

  Future<void> _export(List<ComponentItem> items, _ExportMode mode) async {
    if (items.isEmpty) {
      _toast('Nothing to export yet.');
      return;
    }
    final text = encodeBackup(items);
    try {
      if (mode == _ExportMode.copy) {
        await Clipboard.setData(ClipboardData(text: text));
        _toast('${items.length} components copied. Paste them anywhere safe.');
      } else {
        await Share.share(text, subject: 'Decode components backup');
      }
    } catch (_) {
      _toast('Could not export. Please try again.');
    }
  }

  Future<void> _import() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _ImportDialog(),
    );
    if (text == null || text.trim().isEmpty) return;
    try {
      final items = decodeBackup(
        text,
        idPrefix: UserComponentsNotifier.newId(),
        categories: userCategories,
      );
      final count =
          await ref.read(userComponentsProvider.notifier).importAll(items);
      _toast('Imported $count components');
    } on FormatException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not import. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(userComponentsProvider);
    final all = mine.valueOrNull ?? const <ComponentItem>[];

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Scaffold(
        appBar: _selecting ? _selectionBar(all) : _normalBar(all),
        body: mine.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Could not load.')),
          data: _content,
        ),
      ),
    );
  }

  AppBar _normalBar(List<ComponentItem> all) {
    return AppBar(
      title: const Text('Admin Panel'),
      actions: [
        IconButton(
          tooltip: 'New component',
          icon: const Icon(Icons.add_rounded),
          onPressed: _create,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'import':
                _import();
              case 'copy':
                _export(all, _ExportMode.copy);
              case 'share':
                _export(all, _ExportMode.share);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'import', child: Text('Import backup')),
            PopupMenuItem(value: 'copy', child: Text('Copy all as backup')),
            PopupMenuItem(value: 'share', child: Text('Share backup')),
          ],
        ),
      ],
    );
  }

  AppBar _selectionBar(List<ComponentItem> all) {
    final chosen = [
      for (final c in all)
        if (_selected.contains(c.id)) c,
    ];
    return AppBar(
      leading: IconButton(
        tooltip: 'Cancel selection',
        icon: const Icon(Icons.close_rounded),
        onPressed: () => setState(_selected.clear),
      ),
      title: Text('${_selected.length} selected'),
      actions: [
        IconButton(
          tooltip: 'Select all',
          icon: const Icon(Icons.select_all_rounded),
          onPressed: () =>
              setState(() => _selected.addAll(_visible(all).map((c) => c.id))),
        ),
        IconButton(
          tooltip: 'Move to category',
          icon: const Icon(Icons.drive_file_move_outlined),
          onPressed: _moveSelected,
        ),
        IconButton(
          tooltip: 'Copy as backup',
          icon: const Icon(Icons.ios_share_rounded),
          onPressed: () => _export(chosen, _ExportMode.copy),
        ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () =>
              _delete(Set.of(_selected), '${_selected.length} components'),
        ),
      ],
    );
  }

  Widget _content(List<ComponentItem> all) {
    final scheme = Theme.of(context).colorScheme;
    final projects = ref.watch(projectsProvider).valueOrNull?.length ?? 0;
    final used = all.map((c) => c.category).toSet().toList()..sort();
    final items = _visible(all);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Row(
          children: [
            _Stat(label: 'My components', value: '${all.length}'),
            const SizedBox(width: 10),
            _Stat(
              label: 'Online',
              value: '${ref.watch(onlineComponentsProvider).items.length}',
            ),
            const SizedBox(width: 10),
            _Stat(label: 'Projects', value: '$projects'),
          ],
        ),
        const SizedBox(height: 16),
        if (all.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Text(
                  'You have not created any components yet.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create component'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _import,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Import backup'),
                ),
              ],
            ),
          )
        else ...[
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search my components...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: used.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final name = i == 0 ? 'All' : used[i - 1];
                return ChoiceChip(
                  label: Text(name),
                  selected: _category == name,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _category = name),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No matching components',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
          for (final item in items) ...[
            _row(item, scheme),
            const Divider(),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Tip: long-press a row to select several at once.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(ComponentItem item, ColorScheme scheme) {
    final selected = _selected.contains(item.id);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      selected: selected,
      leading: _selecting
          ? Checkbox(value: selected, onChanged: (_) => _toggle(item.id))
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: scheme.primary),
            ),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        item.description.isEmpty
            ? item.category
            : '${item.category} \u2022 ${item.description}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
      ),
      trailing: _selecting
          ? null
          : PopupMenuButton<_RowAction>(
              icon: Icon(Icons.more_horiz, color: scheme.onSurfaceVariant),
              onSelected: (action) {
                switch (action) {
                  case _RowAction.edit:
                    _edit(item);
                  case _RowAction.preview:
                    _preview(item);
                  case _RowAction.duplicate:
                    ref.read(userComponentsProvider.notifier).duplicate(item);
                  case _RowAction.delete:
                    _delete({item.id}, '"${item.name}"');
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: _RowAction.edit, child: Text('Edit')),
                PopupMenuItem(value: _RowAction.preview, child: Text('Preview')),
                PopupMenuItem(
                  value: _RowAction.duplicate,
                  child: Text('Duplicate'),
                ),
                PopupMenuItem(value: _RowAction.delete, child: Text('Delete')),
              ],
            ),
      onTap: () => _selecting ? _toggle(item.id) : _edit(item),
      onLongPress: () => _toggle(item.id),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) _controller.text = data!.text!;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import backup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paste the backup text you copied earlier.'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(hintText: '{ "components": [...] }'),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _paste,
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: const Text('Paste'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Import'),
        ),
      ],
    );
  }
}
