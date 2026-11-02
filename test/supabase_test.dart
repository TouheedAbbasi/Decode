import 'dart:convert';

import 'package:decode/core/supabase/supabase_rest.dart';
import 'package:decode/features/components/component_item.dart';
import 'package:decode/features/components/component_library.dart';
import 'package:decode/features/components/online_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetchComponents sends the key and parses rows', () async {
    late http.Request seen;
    final client = SupabaseRest(
      baseUrl: 'https://example.supabase.co/',
      anonKey: 'sb_publishable_test',
      client: MockClient((request) async {
        seen = request;
        return http.Response(
          jsonEncode([
            {'id': 'c_1', 'name': 'A', 'html': '<p>a</p>'},
            'junk',
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final rows = await client.fetchComponents();
    expect(rows.length, 1);
    expect(seen.url.path, '/rest/v1/components');
    expect(seen.url.queryParameters['select'], '*');
    expect(seen.headers['apikey'], 'sb_publishable_test');
    // A publishable key is not a JWT, so it must not be sent as a bearer.
    expect(seen.headers.containsKey('Authorization'), isFalse);
  });

  test('legacy JWT anon keys are also sent as bearer token', () async {
    late http.Request seen;
    final client = SupabaseRest(
      baseUrl: 'https://example.supabase.co',
      anonKey: 'eyJhbGciOi.test.key',
      client: MockClient((request) async {
        seen = request;
        return http.Response('[]', 200);
      }),
    );
    await client.fetchComponents();
    expect(seen.headers['Authorization'], 'Bearer eyJhbGciOi.test.key');
  });

  test('server errors become readable messages', () async {
    final client = SupabaseRest(
      baseUrl: 'https://example.supabase.co',
      anonKey: 'k',
      client: MockClient(
        (_) async => http.Response(jsonEncode({'message': 'relation does not exist'}), 404),
      ),
    );
    expect(
      client.fetchComponents(),
      throwsA(
        isA<SupabaseException>().having((e) => e.message, 'message', 'relation does not exist'),
      ),
    );
  });

  test('online rows become components; broken rows are skipped', () {
    final items = OnlineCache.parse([
      {
        'id': 'c_1',
        'name': 'Glass Login',
        'category': 'Glassmorphism',
        'description': 'nice',
        'html': '<form></form>',
        'css': 'form{}',
        'js': '',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      {'id': 'c_2', 'name': '', 'html': '<p></p>'},
      {'id': 'c_3', 'name': 'Odd', 'category': 'Nope', 'html': '<p></p>'},
    ]);
    expect(items.map((c) => c.id), ['c_1', 'c_3']);
    expect(items.first.isRemote, isTrue);
    expect(items.first.isNew, isTrue);
    expect(items.last.category, 'UI');
    expect(userCategories, isNot(contains('Online')));
  });

  test('toSingleFile inlines css and js', () {
    const item = ComponentItem(
      id: 'x',
      name: 'Demo',
      description: '',
      category: 'UI',
      icon: IconDataStub.icon,
      html: '<button id="b">Hi</button>',
      css: 'button { color: red; }',
      js: "document.getElementById('b');",
    );
    final doc = item.toSingleFile();
    expect(doc, contains('<style>'));
    expect(doc, contains('button { color: red; }'));
    expect(doc, contains('<script>'));
    expect(doc, contains('<button id="b">Hi</button>'));
    expect(doc, isNot(contains('href="style.css"')));
  });
}

class IconDataStub {
  static const icon = Icons.extension_outlined;
}
