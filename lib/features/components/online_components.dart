import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/storage/atomic_file.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/supabase/supabase_rest.dart';
import 'component_item.dart';
import 'component_library.dart';

/// Keeps the last downloaded rows so the library works offline.
class OnlineCache {
  OnlineCache(this.file);

  final File file;

  Future<List<ComponentItem>> load() async {
    if (!await file.exists()) return [];
    try {
      final data = jsonDecode(await file.readAsString()) as List<dynamic>;
      return parse(data.whereType<Map<String, dynamic>>().toList());
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Map<String, dynamic>> rows) async {
    await file.parent.create(recursive: true);
    await writeFileAtomic(file, jsonEncode(rows));
  }

  static List<ComponentItem> parse(List<Map<String, dynamic>> rows) => [
        for (final row in rows)
          if (ComponentItem.tryFromRemote(row, categories: userCategories)
              case final item?)
            item,
      ];
}

class OnlineSyncState {
  const OnlineSyncState({
    this.items = const [],
    this.syncing = false,
    this.error,
    this.lastSync,
  });

  final List<ComponentItem> items;
  final bool syncing;
  final String? error;
  final DateTime? lastSync;

  OnlineSyncState copyWith({
    List<ComponentItem>? items,
    bool? syncing,
    String? error,
    bool clearError = false,
    DateTime? lastSync,
  }) =>
      OnlineSyncState(
        items: items ?? this.items,
        syncing: syncing ?? this.syncing,
        error: clearError ? null : (error ?? this.error),
        lastSync: lastSync ?? this.lastSync,
      );
}

/// Components published from the admin website. They appear in the app
/// without an app update: the app downloads the list when it opens.
class OnlineComponentsNotifier extends Notifier<OnlineSyncState> {
  @override
  OnlineSyncState build() {
    if (ref.read(supabaseProvider) == null) return const OnlineSyncState();
    Future.microtask(_start);
    return const OnlineSyncState(syncing: true);
  }

  Future<OnlineCache> _cache() async {
    final docs = await getApplicationDocumentsDirectory();
    return OnlineCache(File(p.join(docs.path, 'online_components.json')));
  }

  Future<void> _start() async {
    try {
      final cached = await (await _cache()).load();
      if (cached.isNotEmpty) state = state.copyWith(items: cached);
    } catch (_) {
      // No cache yet (or no storage): the network refresh below still runs.
    }
    await refresh();
  }

  Future<void> refresh() async {
    final client = ref.read(supabaseProvider);
    if (client == null) return;
    state = state.copyWith(syncing: true, clearError: true);
    try {
      final rows = await client.fetchComponents();
      final items = OnlineCache.parse(rows);
      try {
        await (await _cache()).save(rows);
      } catch (_) {
        // Caching is best effort.
      }
      state = state.copyWith(
        items: items,
        syncing: false,
        lastSync: DateTime.now(),
      );
    } on SupabaseException catch (e) {
      state = state.copyWith(syncing: false, error: e.message);
    } catch (_) {
      state = state.copyWith(syncing: false, error: 'Could not refresh.');
    }
  }
}

final onlineComponentsProvider =
    NotifierProvider<OnlineComponentsNotifier, OnlineSyncState>(
  OnlineComponentsNotifier.new,
);
