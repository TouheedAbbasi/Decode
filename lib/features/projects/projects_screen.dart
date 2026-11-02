import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:path/path.dart' as p;

import '../device/device_files.dart';
import '../device/recent_folders.dart';
import 'new_project_screen.dart';
import 'project_providers.dart';
import 'project_tile.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final recents = ref.watch(recentFoldersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            tooltip: 'Open from device',
            icon: const Icon(Icons.folder_open_outlined),
            onPressed: () => pickFromDevice(context),
          ),
          IconButton(
            tooltip: 'Create project',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => openNewProject(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search projects...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          if (recents.isNotEmpty && _query.isEmpty) _recentFolders(recents, muted),
          Expanded(
            child: projects.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Could not load projects')),
              data: (all) {
                final list = _query.isEmpty
                    ? all
                    : all
                        .where((p) => p.name.toLowerCase().contains(_query))
                        .toList();
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      all.isEmpty ? 'No projects yet' : 'No matching projects',
                      style: TextStyle(color: muted),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) => ProjectTile(project: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentFolders(List<String> recents, Color muted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opened from device',
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final path in recents.take(3))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_open_rounded),
              title: Text(
                p.basename(path).isEmpty ? path : p.basename(path),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontSize: 11),
              ),
              trailing: IconButton(
                tooltip: 'Remove from list',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () =>
                    ref.read(recentFoldersProvider.notifier).remove(path),
              ),
              onTap: () => openDeviceFolder(context, ref, path),
            ),
          const Divider(),
        ],
      ),
    );
  }
}
