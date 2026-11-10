import 'package:flutter/material.dart';

import '../projects/templates.dart';
import 'component_library.dart';

class ComponentItem {
  const ComponentItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.html,
    this.css = '',
    this.js = '',
    this.isUser = false,
    this.isRemote = false,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final IconData icon;

  /// Body fragment (no <html>/<body> wrapper).
  final String html;
  final String css;
  final String js;

  /// True for components the user made in the studio.
  final bool isUser;

  /// True for components published online (Supabase).
  final bool isRemote;

  /// When it was last published or changed (online components only).
  final DateTime? updatedAt;

  /// Published within the last 7 days.
  bool get isNew =>
      updatedAt != null &&
      DateTime.now().difference(updatedAt!) < const Duration(days: 7);

  /// Complete, linked project files built from this component.
  Map<String, String> toFiles() {
    final script = js.isEmpty ? '' : '\n  <script src="script.js"></script>';
    return {
      'index.html': '<!DOCTYPE html>\n'
          '<html lang="en">\n'
          '<head>\n'
          '  <meta charset="UTF-8">\n'
          '  <meta name="viewport" content="width=device-width, initial-scale=1.0">\n'
          '  <title>$name</title>\n'
          '  <link rel="stylesheet" href="style.css">\n'
          '</head>\n'
          '<body>\n'
          '$html\n'
          '$script\n'
          '</body>\n'
          '</html>\n',
      'style.css': css,
      if (js.isNotEmpty) 'script.js': js,
    };
  }

  ComponentItem copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? html,
    String? css,
    String? js,
    bool? isUser,
    bool? isRemote,
    IconData? icon,
  }) =>
      ComponentItem(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        icon: icon ?? this.icon,
        html: html ?? this.html,
        css: css ?? this.css,
        js: js ?? this.js,
        isUser: isUser ?? this.isUser,
        isRemote: isRemote ?? this.isRemote,
        updatedAt: updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'html': html,
        'css': css,
        'js': js,
      };

  factory ComponentItem.fromJson(Map<String, dynamic> json) => ComponentItem(
        id: json['id'] as String,
        name: json['name'] as String,
        description: (json['description'] as String?) ?? '',
        category: (json['category'] as String?) ?? 'UI',
        icon: Icons.extension_outlined,
        html: (json['html'] as String?) ?? '',
        css: (json['css'] as String?) ?? '',
        js: (json['js'] as String?) ?? '',
        isUser: true,
      );

  /// Everything in one ready-to-save HTML document (CSS and JS inlined).
  String toSingleFile() {
    String indented(String code) =>
        code.trimRight().split('\n').map((l) => l.isEmpty ? l : '    $l').join('\n');
    final style = css.trim().isEmpty ? '' : '  <style>\n${indented(css)}\n  </style>\n';
    final script = js.trim().isEmpty ? '' : '  <script>\n${indented(js)}\n  </script>\n';
    return '<!DOCTYPE html>\n'
        '<html lang="en">\n'
        '<head>\n'
        '  <meta charset="UTF-8">\n'
        '  <meta name="viewport" content="width=device-width, initial-scale=1.0">\n'
        '  <title>$name</title>\n'
        '$style'
        '</head>\n'
        '<body>\n'
        '$html\n'
        '$script'
        '</body>\n'
        '</html>\n';
  }

  /// Builds a component from a row of the online `components` table.
  /// Returns null for rows that are incomplete.
  static ComponentItem? tryFromRemote(
    Map<String, dynamic> row, {
    required List<String> categories,
  }) {
    String str(Object? value) => value is String ? value : '';
    final id = str(row['id']);
    final name = str(row['name']).trim();
    final html = str(row['html']);
    if (id.isEmpty || name.isEmpty || html.trim().isEmpty) return null;
    var category = str(row['category']);
    if (!categories.contains(category)) {
      final mapped = normalizeCategory(category);
      category = categories.contains(mapped) ? mapped : 'UI';
    }
    return ComponentItem(
      id: id,
      name: name,
      description: str(row['description']).trim(),
      category: category,
      icon: Icons.cloud_outlined,
      html: html,
      css: str(row['css']),
      js: str(row['js']),
      isRemote: true,
      updatedAt: DateTime.tryParse(str(row['updated_at'])),
    );
  }

  ProjectTemplate toTemplate() => ProjectTemplate(
        id: 'component_$id',
        title: name,
        subtitle: description,
        icon: icon,
        files: toFiles(),
      );
}

/// Extracts the <body> contents of a full document, without the script tag.
String bodyOf(String document) {
  final match = RegExp(r'<body>([\s\S]*)</body>').firstMatch(document);
  final body = match?.group(1) ?? document;
  return body
      .replaceAll(RegExp(r'\s*<script src="script.js"></script>'), '')
      .trim();
}
