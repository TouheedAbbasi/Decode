import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/preview/preview_source.dart';
import '../admin/admin_screen.dart';
import '../preview/preview_screen.dart';
import 'component_detail_screen.dart';
import 'component_item.dart';
import 'component_library.dart';
import 'component_studio_screen.dart';
import 'online_components.dart';
import 'user_components.dart';

class ComponentsScreen extends ConsumerStatefulWidget {
  const ComponentsScreen({super.key});

  @override
  ConsumerState<ComponentsScreen> createState() => _ComponentsScreenState();
}

class _ComponentsScreenState extends ConsumerState<ComponentsScreen> {
  String _category = 'All';
  String _query = '';

  List<ComponentItem> _filtered(
    List<ComponentItem> mine,
    List<ComponentItem> online,
  ) {
    final mineIds = {for (final c in mine) c.id};
    final all = [
      ...mine,
      ...online.where((c) => !mineIds.contains(c.id)),
    ];
    return all.where((c) {
      final inCategory = switch (_category) {
        'All' => true,
        'Online' => c.isRemote,
        'My Components' => c.isUser,
        _ => c.category == _category,
      };
      final inQuery = _query.isEmpty ||
          c.name.toLowerCase().contains(_query) ||
          c.description.toLowerCase().contains(_query);
      return inCategory && inQuery;
    }).toList();
  }

  Future<void> _create() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ComponentStudioScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = ref.watch(userComponentsProvider).valueOrNull ??
        const <ComponentItem>[];
    final online = ref.watch(onlineComponentsProvider);
    final items = _filtered(mine, online.items);
    final categories = [
      'All',
      if (online.items.isNotEmpty) 'Online',
      if (mine.isNotEmpty) 'My Components',
      for (final c in userCategories)
        if (mine.any((m) => m.category == c) ||
            online.items.any((o) => o.category == c))
          c,
    ];
    if (!categories.contains(_category)) _category = 'All';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Component Library'),
        actions: [
          IconButton(
            tooltip: 'Admin panel',
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AdminScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Create component',
            icon: const Icon(Icons.add_rounded),
            onPressed: _create,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search components...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final name = categories[i];
                return ChoiceChip(
                  label: Text(name),
                  selected: _category == name,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _category = name),
                );
              },
            ),
          ),
          if (online.syncing) const LinearProgressIndicator(minHeight: 2),
          if (online.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Row(
                children: [
                  Icon(Icons.cloud_off_outlined,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Could not sync. Showing saved components. '
                      'Pull down to retry.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(onlineComponentsProvider.notifier).refresh(),
              child: items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            _emptyText(),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) => _ComponentTile(item: items[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _emptyText() {
    if (_query.isNotEmpty) return 'No matching components';
    return switch (_category) {
      'My Components' => 'No components yet. Tap + to create your first one.',
      'Online' => 'No online components yet. Pull down to refresh.',
      _ => 'No components yet.\nPublish some from the portal, or tap + to '
          'build your own.',
    };
  }
}

class _ComponentTile extends StatelessWidget {
  const _ComponentTile({required this.item});

  final ComponentItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(item.icon, color: scheme.primary),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          if (item.isNew) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        item.description.isEmpty ? item.category : item.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
      ),
      trailing: IconButton(
        tooltip: 'Quick preview',
        icon: Icon(Icons.play_circle_outline_rounded, color: scheme.primary),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                PreviewScreen(source: MemorySource(item.toFiles())),
          ),
        ),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ComponentDetailScreen(item: item),
        ),
      ),
    );
  }
}
