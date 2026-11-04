import 'package:flutter/material.dart';

import '../editor/lorem.dart';
import 'copy_helper.dart';

/// Placeholder text generator ("lorem ipsum").
class LoremScreen extends StatefulWidget {
  const LoremScreen({super.key});

  @override
  State<LoremScreen> createState() => _LoremScreenState();
}

class _LoremScreenState extends State<LoremScreen> {
  bool _paragraphs = false;
  double _count = 30;

  String get _text => _paragraphs
      ? loremParagraphs(_count.round(), wordsEach: 45)
      : loremWords(_count.round());

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final max = _paragraphs ? 10.0 : 200.0;
    final value = _count.clamp(1, max).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Lorem Generator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Words')),
              ButtonSegment(value: true, label: Text('Paragraphs')),
            ],
            selected: {_paragraphs},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() {
              _paragraphs = s.first;
              _count = _paragraphs ? 3 : 30;
            }),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: 1,
                  max: max,
                  divisions: max.round() - 1,
                  onChanged: (v) => setState(() => _count = v),
                ),
              ),
              SizedBox(width: 40, child: Text('${value.round()}')),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(color: scheme.outline),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(_text, style: const TextStyle(height: 1.5)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => copyText(context, _text, message: 'Text copied'),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy text'),
          ),
          const SizedBox(height: 12),
          Text(
            'In the editor you can also type "lorem", "lorem10", "lorem50" '
            'and pick the suggestion.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
