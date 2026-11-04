import 'package:flutter/material.dart';

import '../components/components_screen.dart';
import 'color_tools_screen.dart';
import 'effects_screen.dart';
import 'gradient_screen.dart';
import 'lorem_screen.dart';
import 'palettes_screen.dart';

/// Inspiration and developer tools in one place.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final tools = <({IconData icon, String title, String subtitle, Widget page})>[
      (
        icon: Icons.palette_outlined,
        title: 'Color Palettes',
        subtitle: '300 combos that match',
        page: const PalettesScreen(),
      ),
      (
        icon: Icons.widgets_outlined,
        title: 'Components',
        subtitle: 'Online + your own',
        page: const ComponentsScreen(),
      ),
      (
        icon: Icons.gradient_rounded,
        title: 'Gradients',
        subtitle: 'Build and copy CSS',
        page: const GradientScreen(),
      ),
      (
        icon: Icons.blur_on_rounded,
        title: 'Shadow & Glass',
        subtitle: 'Shadow, glass, neumorphism',
        page: const EffectsScreen(),
      ),
      (
        icon: Icons.colorize_rounded,
        title: 'Color Tools',
        subtitle: 'HSL, contrast, shades',
        page: const ColorToolsScreen(),
      ),
      (
        icon: Icons.notes_rounded,
        title: 'Lorem Text',
        subtitle: 'Placeholder content',
        page: const LoremScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: GridView.count(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.15,
        children: [
          for (final tool in tools)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => tool.page),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(tool.icon, color: scheme.primary),
                    ),
                    const Spacer(),
                    Text(
                      tool.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.subtitle,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
