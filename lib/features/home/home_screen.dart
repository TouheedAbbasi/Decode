import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/main_shell.dart';
import '../device/device_files.dart';
import '../projects/new_project_screen.dart';
import '../projects/project_providers.dart';
import '../projects/project_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => ref.read(navIndexProvider.notifier).set(3),
            ),
          ),
          Row(
            children: [
              Image.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? 'assets/brand/logo_mark_dark.png'
                    : 'assets/brand/logo_mark.png',
                height: 56,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Decode',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'by Senpai Studio',
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Your Phone. Your Code. Your Future.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => openNewProject(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Project'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => pickFromDevice(context),
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Open from device'),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Projects',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              TextButton(
                onPressed: () => ref.read(navIndexProvider.notifier).set(1),
                child: const Text('See All'),
              ),
            ],
          ),
          projects.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load projects',
                style: TextStyle(color: muted),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No projects yet. Create your first one above.',
                    style: TextStyle(color: muted),
                  ),
                );
              }
              return Column(
                children: [
                  for (final project in list.take(5)) ...[
                    ProjectTile(project: project),
                    const Divider(),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
