import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_providers.dart';

/// Folders opened from the phone's storage, newest first.
class RecentFoldersNotifier extends Notifier<List<String>> {
  static const _key = 'recent_folders';
  static const _max = 8;

  @override
  List<String> build() =>
      ref.watch(sharedPrefsProvider).getStringList(_key) ?? const [];

  Future<void> add(String path) async {
    final next = [path, ...state.where((p) => p != path)].take(_max).toList();
    state = next;
    await ref.read(sharedPrefsProvider).setStringList(_key, next);
  }

  Future<void> remove(String path) async {
    final next = state.where((p) => p != path).toList();
    state = next;
    await ref.read(sharedPrefsProvider).setStringList(_key, next);
  }
}

final recentFoldersProvider =
    NotifierProvider<RecentFoldersNotifier, List<String>>(
  RecentFoldersNotifier.new,
);
