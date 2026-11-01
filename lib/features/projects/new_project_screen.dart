import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'project_providers.dart';
import 'templates.dart';

/// Opens the New Project screen and shows a confirmation when it succeeds.
Future<void> openNewProject(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final created = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(builder: (_) => const NewProjectScreen()),
  );
  if (created == true) {
    messenger.showSnackBar(const SnackBar(content: Text('Project created')));
  }
}

class NewProjectScreen extends ConsumerStatefulWidget {
  const NewProjectScreen({super.key});

  @override
  ConsumerState<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends ConsumerState<NewProjectScreen> {
  final _name = TextEditingController();
  bool _useTemplate = false;
  ProjectTemplate _template = Templates.htmlCssJs;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a project name');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final template = _useTemplate ? _template : Templates.blank;
      await ref
          .read(projectsProvider.notifier)
          .create(name: name, template: template);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not create the project. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('New Project')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const _Label('Project Name'),
          TextField(
            controller: _name,
            maxLength: 60,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'My Awesome Project',
              errorText: _error,
              counterText: '',
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 20),
          const _Label('Project Type'),
          _OptionTile(
            selected: !_useTemplate,
            icon: Icons.code_rounded,
            title: 'Blank Project',
            subtitle: 'Start with a clean slate',
            onTap: () => setState(() => _useTemplate = false),
          ),
          const SizedBox(height: 10),
          _OptionTile(
            selected: _useTemplate,
            icon: Icons.copy_all_outlined,
            title: 'Use Template',
            subtitle: 'Choose from ready-to-use starter templates',
            onTap: () => setState(() => _useTemplate = true),
          ),
          if (_useTemplate) ...[
            const SizedBox(height: 20),
            const _Label('Choose Template'),
            for (final t in Templates.starters) ...[
              _OptionTile(
                selected: _template.id == t.id,
                icon: t.icon,
                title: t.title,
                subtitle: t.subtitle,
                onTap: () => setState(() => _template = t),
              ),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 8),
          Text(
            'Projects are stored only on this device.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _busy ? null : _create,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Project'),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outline,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: scheme.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
