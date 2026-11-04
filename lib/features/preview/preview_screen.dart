import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/preview/browser.dart';
import '../../core/preview/preview_session.dart';
import '../../core/preview/preview_source.dart';

/// Full screen preview with an address bar and "Open in Chrome".
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({
    super.key,
    required this.source,
    this.entry = 'index.html',
  });

  final PreviewSource source;
  final String entry;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
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

  Future<void> _openInChrome() async {
    final messenger = ScaffoldMessenger.of(context);
    final url = await _session.ensureServerUrl();
    if (url == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('This phone does not allow the local preview server.'),
        ),
      );
      return;
    }
    if (!await openInChrome(url)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open a browser.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final controller = _session.controller;
        final address = _session.serverUrl ??
            (_session.bundled ? 'In-app preview' : 'Starting...');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Live Preview'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: controller == null ? null : _session.reload,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Container(
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(color: scheme.outline),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: controller == null ? null : _openInChrome,
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Open in Chrome'),
                      ),
                    ],
                  ),
                ),
              ),
              if (_session.loading) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: controller == null
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                        children: [
                          WebViewWidget(controller: controller),
                          if (_session.error != null)
                            Positioned.fill(
                              child: ColoredBox(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'The page could not be loaded.\n'
                                      '${_session.error}',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
