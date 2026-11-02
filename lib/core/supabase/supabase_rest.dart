import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

class SupabaseException implements Exception {
  SupabaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Read-only access to the published components.
///
/// The app never logs in and never writes: publishing is done from the
/// admin website (`portal/index.html`), protected by Supabase Auth + RLS.
class SupabaseRest {
  SupabaseRest({
    required String baseUrl,
    required this.anonKey,
    http.Client? client,
  })  : baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _client = client ?? http.Client();

  final String baseUrl;
  final String anonKey;
  final http.Client _client;

  static const _timeout = Duration(seconds: 20);

  Map<String, String> get headers => {
        'apikey': anonKey,
        // Legacy anon keys are JWTs and may also be sent as a bearer token.
        // New publishable keys (sb_publishable_...) go in `apikey` only.
        if (anonKey.startsWith('eyJ')) 'Authorization': 'Bearer $anonKey',
      };

  Future<List<Map<String, dynamic>>> fetchComponents() async {
    final uri = Uri.parse('$baseUrl/rest/v1/components').replace(
      queryParameters: {
        'select': '*',
        'order': 'updated_at.desc',
        'limit': '1000',
      },
    );

    final http.Response response;
    try {
      response = await _client.get(uri, headers: headers).timeout(_timeout);
    } on TimeoutException {
      throw SupabaseException('The server took too long to answer.');
    } on SocketException {
      throw SupabaseException('No internet connection.');
    } on http.ClientException {
      throw SupabaseException('No internet connection.');
    }

    if (response.statusCode != 200) {
      throw SupabaseException(_message(response));
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! List) {
      throw SupabaseException('Unexpected response from the server.');
    }
    return [
      for (final row in data)
        if (row is Map<String, dynamic>) row,
    ];
  }

  String _message(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map) {
        for (final key in const ['message', 'msg', 'error_description', 'error']) {
          final value = body[key];
          if (value is String && value.isNotEmpty) return value;
        }
      }
    } catch (_) {
      // Fall back to the status code below.
    }
    return 'Could not load components (${response.statusCode}).';
  }
}
