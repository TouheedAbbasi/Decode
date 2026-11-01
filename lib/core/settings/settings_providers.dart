import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main() with the real instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider not overridden'),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPrefsProvider).getString(_key);
    return ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPrefsProvider).setString(_key, mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class EditorFontSizeNotifier extends Notifier<double> {
  static const _key = 'editor_font_size';
  static const min = 11.0;
  static const max = 22.0;

  @override
  double build() {
    final saved = ref.watch(sharedPrefsProvider).getDouble(_key);
    return (saved ?? 14).clamp(min, max).toDouble();
  }

  Future<void> set(double size) async {
    state = size.clamp(min, max).toDouble();
    await ref.read(sharedPrefsProvider).setDouble(_key, state);
  }
}

final editorFontSizeProvider =
    NotifierProvider<EditorFontSizeNotifier, double>(EditorFontSizeNotifier.new);
