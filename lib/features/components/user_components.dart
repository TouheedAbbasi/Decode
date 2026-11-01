import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/storage/atomic_file.dart';
import 'component_item.dart';

/// Stores the user's own components in one JSON file.
class UserComponentsRepository {
  UserComponentsRepository(this.file);

  final File file;

  Future<List<ComponentItem>> load() async {
    if (!await file.exists()) return [];
    try {
      final data = jsonDecode(await file.readAsString()) as List<dynamic>;
      return [
        for (final entry in data)
          ComponentItem.fromJson(entry as Map<String, dynamic>),
      ];
    } catch (_) {
      // Keep the unreadable file so nothing is lost, then start fresh.
      try {
        await file.rename('${file.path}.corrupt');
      } catch (_) {
        // Nothing more we can do.
      }
      return [];
    }
  }

  Future<void> save(List<ComponentItem> items) async {
    await file.parent.create(recursive: true);
    await writeFileAtomic(
      file,
      jsonEncode([for (final item in items) item.toJson()]),
    );
  }
}

final userComponentsRepositoryProvider =
    FutureProvider<UserComponentsRepository>((ref) async {
  final docs = await getApplicationDocumentsDirectory();
  return UserComponentsRepository(File(p.join(docs.path, 'user_components.json')));
});

class UserComponentsNotifier extends AsyncNotifier<List<ComponentItem>> {
  @override
  Future<List<ComponentItem>> build() async {
    final repo = await ref.watch(userComponentsRepositoryProvider.future);
    return repo.load();
  }

  Future<UserComponentsRepository> get _repo =>
      ref.read(userComponentsRepositoryProvider.future);

  /// Adds a new component or replaces the one with the same id.
  Future<void> upsert(ComponentItem item) async {
    final repo = await _repo;
    final current = await repo.load();
    final index = current.indexWhere((c) => c.id == item.id);
    final next = [...current];
    if (index >= 0) {
      next[index] = item;
    } else {
      next.insert(0, item);
    }
    await repo.save(next);
    state = AsyncData(next);
  }

  Future<void> delete(String id) async {
    final repo = await _repo;
    final next = [
      for (final c in await repo.load())
        if (c.id != id) c,
    ];
    await repo.save(next);
    state = AsyncData(next);
  }

  static String newId() => 'u_${DateTime.now().microsecondsSinceEpoch}';
}

final userComponentsProvider =
    AsyncNotifierProvider<UserComponentsNotifier, List<ComponentItem>>(
  UserComponentsNotifier.new,
);
