import 'dart:convert';

import 'package:flutter/material.dart';

import 'component_item.dart';
import 'component_library.dart';

const backupFormat = 'decode-components';
const maxImportedComponents = 500;

/// Turns components into a JSON text that can be kept anywhere (notes,
/// chat, cloud) and imported again later.
String encodeBackup(List<ComponentItem> items) {
  return const JsonEncoder.withIndent('  ').convert({
    'format': backupFormat,
    'version': 1,
    'components': [for (final item in items) item.toJson()],
  });
}

/// Reads a backup made by [encodeBackup]. Every component gets a fresh id
/// (based on [idPrefix]) so importing never overwrites existing ones.
/// Throws [FormatException] with a readable message on bad input.
List<ComponentItem> decodeBackup(
  String text, {
  required String idPrefix,
  required List<String> categories,
}) {
  final Object? data;
  try {
    data = jsonDecode(text.trim());
  } on FormatException {
    throw const FormatException('This is not valid backup text.');
  }

  List<dynamic>? list;
  if (data is Map<String, dynamic> && data['components'] is List) {
    list = data['components'] as List<dynamic>;
  } else if (data is List) {
    list = data;
  }
  if (list == null) {
    throw const FormatException('No components found in this text.');
  }
  if (list.length > maxImportedComponents) {
    throw const FormatException('Too many components in one backup.');
  }

  String str(Object? value) => value is String ? value : '';
  String clip(String value, int max) =>
      value.length > max ? value.substring(0, max) : value;

  final result = <ComponentItem>[];
  for (final entry in list) {
    if (entry is! Map<String, dynamic>) continue;
    final name = str(entry['name']).trim();
    final html = str(entry['html']);
    if (name.isEmpty || html.trim().isEmpty) continue;

    var category = str(entry['category']);
    if (!categories.contains(category)) {
      final mapped = normalizeCategory(category);
      category = categories.contains(mapped) ? mapped : 'UI';
    }

    result.add(
      ComponentItem(
        id: '${idPrefix}_${result.length}',
        name: clip(name, 50),
        description: clip(str(entry['description']).trim(), 100),
        category: category,
        icon: Icons.extension_outlined,
        html: html,
        css: str(entry['css']),
        js: str(entry['js']),
        isUser: true,
      ),
    );
  }
  if (result.isEmpty) {
    throw const FormatException('No valid components found in this text.');
  }
  return result;
}
