import 'dart:convert';
import 'dart:io';

import 'package:decode/core/preview/preview_server.dart';
import 'package:decode/core/preview/preview_source.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(int, String)> get(PreviewServer server, String path) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(server.urlFor(path)));
    final response = await request.close();
    return (response.statusCode, await utf8.decodeStream(response));
  } finally {
    client.close(force: true);
  }
}

void main() {
  test('server serves memory files and 404s unknown ones', () async {
    final server = await PreviewServer.start(
      MemorySource({'index.html': '<h1>Hi</h1>', 'style.css': 'a{}'}),
    );
    addTearDown(server.stop);

    expect(server.baseUrl, startsWith('http://127.0.0.1:'));
    expect(await get(server, 'index.html'), (200, '<h1>Hi</h1>'));
    expect(await get(server, 'style.css'), (200, 'a{}'));
    expect((await get(server, 'missing.js')).$1, 404);
  });

  test('directory source refuses paths outside the project', () async {
    final tmp = await Directory.systemTemp.createTemp('decode_preview_');
    addTearDown(() => tmp.delete(recursive: true));
    final project = Directory('${tmp.path}/proj')..createSync();
    File('${project.path}/index.html').writeAsStringSync('ok');
    File('${project.path}/.decode.json').writeAsStringSync('{}');
    File('${tmp.path}/secret.txt').writeAsStringSync('secret');

    final source = DirectorySource(project);
    expect(utf8.decode((await source.read('index.html'))!), 'ok');
    expect(await source.read('../secret.txt'), isNull);
    expect(await source.read('/etc/passwd'), isNull);
    expect(await source.read('.decode.json'), isNull);
    expect(await source.read('nope.html'), isNull);
  });

  test('overlay source prefers unsaved text', () async {
    final source = OverlaySource(
      overrides: () => {'index.html': 'draft'},
      base: MemorySource({'index.html': 'saved', 'a.css': 'x'}),
    );
    expect(utf8.decode((await source.read('index.html'))!), 'draft');
    expect(utf8.decode((await source.read('a.css'))!), 'x');
  });
}
