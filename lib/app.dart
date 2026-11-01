import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/settings/settings_providers.dart';
import 'core/theme/app_theme.dart';
import 'shell/main_shell.dart';

class DecodeApp extends ConsumerWidget {
  const DecodeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Decode',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: const MainShell(),
    );
  }
}
