import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/preview/preview_source.dart';
import '../preview/preview_screen.dart';
import 'component_detail_screen.dart';
import 'component_item.dart';
import 'component_library.dart';
import 'component_studio_screen.dart';
import 'user_components.dart';

class ComponentsScreen extends ConsumerStatefulWidget {
  const ComponentsScreen({super.key});

  @override
  ConsumerState<ComponentsScreen> createState() => _ComponentsScreenState();
}

class _ComponentsScreenState extends ConsumerState<ComponentsScreen> {
  String _category = 'All';
  String _query = '';

  List<ComponentItem> _filtered(List<ComponentItem> mine) {
    final all = [...mine, ...componentLibrary];
    return all.where((c) {
      final inCategory = switch (_category) {
        'All' => true,
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
    final items = _filtered(mine);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Component Library'),
        actions: [
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
              itemCount: componentCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final name = componentCategories[i];
                return ChoiceChip(
                  label: Text(name),
                  selected: _category == name,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _category = name),
                );
              },
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _category == 'My Components' && _query.isEmpty
                            ? 'No components yet. Tap + to create your first one.'
                            : 'No matching components',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) => _ComponentTile(item: items[i]),
                  ),
          ),
        ],
      ),
    );
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
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
