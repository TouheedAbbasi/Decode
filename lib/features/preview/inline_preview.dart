import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/preview/preview_session.dart';
import '../../core/preview/preview_source.dart';

/// A small live preview that can sit inside a normal screen.
class InlinePreview extends StatefulWidget {
  const InlinePreview({
    super.key,
    required this.source,
    this.entry = 'index.html',
  });

  final PreviewSource source;
  final String entry;

  @override
  State<InlinePreview> createState() => _InlinePreviewState();
}

class _InlinePreviewState extends State<InlinePreview> {
  late final PreviewSession _session;

  @override
  void initState() {
    super.initState();
    _session = PreviewSession(source: widget.source, entry: widget.entry)
      ..start();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final controller = _session.controller;
        if (_session.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Preview failed: ${_session.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (controller == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            WebViewWidget(controller: controller),
            if (_session.loading) const LinearProgressIndicator(minHeight: 2),
          ],
        );
      },
    );
  }
}
