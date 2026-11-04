const _words = [
  'lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing',
  'elit', 'sed', 'do', 'eiusmod', 'tempor', 'incididunt', 'ut', 'labore',
  'et', 'dolore', 'magna', 'aliqua', 'enim', 'ad', 'minim', 'veniam', 'quis',
  'nostrud', 'exercitation', 'ullamco', 'laboris', 'nisi', 'aliquip', 'ex',
  'ea', 'commodo', 'consequat', 'duis', 'aute', 'irure', 'in', 'reprehenderit',
  'voluptate', 'velit', 'esse', 'cillum', 'eu', 'fugiat', 'nulla', 'pariatur',
  'excepteur', 'sint', 'occaecat', 'cupidatat', 'non', 'proident', 'sunt',
  'culpa', 'qui', 'officia', 'deserunt', 'mollit', 'anim', 'id', 'est',
  'laborum',
];

/// [count] words of placeholder text starting with "Lorem ipsum", broken
/// into sentences.
String loremWords(int count) {
  if (count <= 0) return '';
  final out = StringBuffer();
  var sentenceLength = 0;
  var target = 9;
  for (var i = 0; i < count; i++) {
    var word = _words[i % _words.length];
    if (sentenceLength == 0) word = word[0].toUpperCase() + word.substring(1);
    out.write(word);
    sentenceLength++;
    final last = i == count - 1;
    if (last || sentenceLength >= target) {
      out.write('.');
      sentenceLength = 0;
      target = 8 + (i * 7) % 8;
      if (!last) out.write(' ');
    } else {
      out.write(sentenceLength % 6 == 0 ? ', ' : ' ');
    }
  }
  return out.toString();
}

/// [count] paragraphs of [wordsEach] words, separated by blank lines.
String loremParagraphs(int count, {int wordsEach = 50}) => List.generate(
      count,
      (i) => loremWords(wordsEach),
    ).join('\n\n');
