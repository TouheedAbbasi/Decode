import 'package:flutter/material.dart';

/// Placeholder until Phase 5 (component library).
class ComponentsScreen extends StatelessWidget {
  const ComponentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('Component Library')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Ready-made forms, navbars, cards and templates are coming in a '
            'later phase.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted),
          ),
        ),
      ),
    );
  }
}
