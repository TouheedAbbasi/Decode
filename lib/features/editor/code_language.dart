enum CodeLanguage {
  html,
  css,
  js,
  text;

  static CodeLanguage fromFileName(String name) {
    final dot = name.lastIndexOf('.');
    final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'html' || 'htm' => CodeLanguage.html,
      'css' => CodeLanguage.css,
      'js' || 'mjs' => CodeLanguage.js,
      _ => CodeLanguage.text,
    };
  }
}
