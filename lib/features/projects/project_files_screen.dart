import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'project.dart';
import 'project_providers.dart';

/// Temporary read-only view of a project's files.
/// Replaced by the real editor in Phase 3.
class ProjectFilesScreen extends ConsumerWidget {
  const ProjectFilesScreen({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(projectFilesProvider(project));
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: Text(project.name)),
      body: files.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not read files')),
        data: (list) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final (name, size) in list)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(name),
                subtitle: Text('$size bytes', style: TextStyle(color: muted)),
              ),
            const SizedBox(height: 16),
            Text(
              'The code editor arrives in the next phase.',
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
