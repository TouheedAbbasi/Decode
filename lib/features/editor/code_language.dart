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

/// Inside `<style>` or `<script>` of an HTML file the code is really CSS or
/// JavaScript. Returns the language that applies at [cursor].
CodeLanguage effectiveLanguage(String text, int cursor, CodeLanguage language) {
  if (language != CodeLanguage.html || cursor < 0 || cursor > text.length) {
    return language;
  }
  final before = text.substring(0, cursor).toLowerCase();
  final style = _openBlock(before, 'style');
  final script = _openBlock(before, 'script');
  if (style > script) return CodeLanguage.css;
  if (script > style) return CodeLanguage.js;
  return CodeLanguage.html;
}

/// Index of the opening tag when the cursor is inside the tag's content,
/// otherwise -1.
int _openBlock(String before, String tag) {
  final open = before.lastIndexOf('<$tag');
  if (open < 0) return -1;
  if (before.lastIndexOf('</$tag') > open) return -1;
  return before.indexOf('>', open) < 0 ? -1 : open;
}
