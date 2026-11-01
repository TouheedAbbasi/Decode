import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
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
}
