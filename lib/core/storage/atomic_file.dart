import 'dart:io';

/// Writes [content] to a temp file, then renames it over [file], so a crash
/// can never leave a half-written file behind.
Future<void> writeFileAtomic(File file, String content) async {
  final tmp = File('${file.path}.tmp');
  await tmp.writeAsString(content, flush: true);
  await tmp.rename(file.path);
}
