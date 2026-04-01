class MapPinLabelText {
  MapPinLabelText._({required this.lines})
    : lineCount = lines.length,
      maxLineLength = lines.fold<int>(
        0,
        (longest, line) => line.length > longest ? line.length : longest,
      );

  factory MapPinLabelText.fromName(String name, {int wordsPerLine = 2}) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);

    if (words.isEmpty) {
      return MapPinLabelText._(lines: const <String>[]);
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

  /// Cached line count - O(1) access
  final int lineCount;

  /// Cached max line length - O(1) access
  final int maxLineLength;

  bool get isEmpty => lines.isEmpty;

  String get displayText => lines.join('\n');
}
