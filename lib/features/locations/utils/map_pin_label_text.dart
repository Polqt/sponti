class MapPinLabelText {
  const MapPinLabelText._({
    required this.lines,
  });

  factory MapPinLabelText.fromName(String name, {int wordsPerLine = 2}) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);

    if (words.isEmpty) {
      return const MapPinLabelText._(lines: <String>[]);
    }

    final rows = <String>[];
    for (var index = 0; index < words.length; index += wordsPerLine) {
      final end = (index + wordsPerLine) > words.length
          ? words.length
          : index + wordsPerLine;
      rows.add(words.sublist(index, end).join(' '));
    }

    return MapPinLabelText._(lines: rows);
  }

  final List<String> lines;

  bool get isEmpty => lines.isEmpty;

  int get lineCount => lines.length;

  int get maxLineLength => lines.fold<int>(
    0,
    (longest, line) => line.length > longest ? line.length : longest,
  );

  String get displayText => lines.join('\n');
}
