import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_providers.dart';
import '../admin/admin_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final fontSize = ref.watch(editorFontSizeProvider);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Editor font size',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('${fontSize.round()} px', style: TextStyle(color: muted)),
            ],
          ),
          Slider(
            value: fontSize,
            min: EditorFontSizeNotifier.min,
            max: EditorFontSizeNotifier.max,
            divisions: (EditorFontSizeNotifier.max - EditorFontSizeNotifier.min)
                .round(),
            onChanged: (v) => ref.read(editorFontSizeProvider.notifier).set(v),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '<h1 class="title">Hello</h1>',
              style: TextStyle(fontFamily: 'monospace', fontSize: fontSize),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Line numbers'),
            value: ref.watch(lineNumbersProvider),
            onChanged: (v) => ref.read(lineNumbersProvider.notifier).set(v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Autosave'),
            subtitle: const Text('Save 2 seconds after you stop typing'),
            value: ref.watch(autosaveProvider),
            onChanged: (v) => ref.read(autosaveProvider.notifier).set(v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Smart typing'),
            subtitle: const Text('Auto-close brackets, quotes and tags'),
            value: ref.watch(smartTypingProvider),
            onChanged: (v) => ref.read(smartTypingProvider.notifier).set(v),
          ),
          const SizedBox(height: 20),
          const Text('Tools', style: TextStyle(fontWeight: FontWeight.w600)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Admin Panel'),
            subtitle: const Text('Manage, back up and import your components'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AdminScreen()),
            ),
          ),
          const SizedBox(height: 20),
          const Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Center(
            child: Image.asset(
              dark
                  ? 'assets/brand/logo_full_dark.png'
                  : 'assets/brand/logo_full.png',
              height: 110,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Decode by Senpai Studio  -  version 0.3.0',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 12),
          Text(
            'Privacy: your projects are stored only on this device. Decode '
            'does not upload your code and shows no ads.',
            style: TextStyle(color: muted),
          ),
        ],
      ),
    );
  }
}
