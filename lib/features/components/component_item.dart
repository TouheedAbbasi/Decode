import 'package:flutter/material.dart';

import '../projects/templates.dart';

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
