final _unreadableSourceNote = RegExp(
  r'^\d+[a-zA-Z]-\d+[a-zA-Z]$|^ch\d+$|^part\s*\d+$|^chapter\s*\d+$|^p\d+$',
  caseSensitive: false,
);

String sanitizeSourceNote(String note) {
  final cleaned = note.trim();
  if (cleaned.isEmpty) return '';
  if (_unreadableSourceNote.hasMatch(cleaned)) return '节选';
  if (!RegExp(r'[\u4e00-\u9fff]').hasMatch(cleaned) &&
      RegExp(r'^[\w\-\.]+$').hasMatch(cleaned)) {
    return '节选';
  }
  return cleaned;
}

class DailyPageReading {
  final String bookTitle;
  final String author;
  final String content;
  final String sourceNote;
  final DateTime date;

  const DailyPageReading({
    required this.bookTitle,
    required this.author,
    required this.content,
    required this.sourceNote,
    required this.date,
  });

  factory DailyPageReading.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date'] as String? ?? '';
    return DailyPageReading(
      bookTitle: json['book_title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      content: json['content'] as String? ?? '',
      sourceNote: sanitizeSourceNote(json['source_note'] as String? ?? ''),
      date: DateTime.tryParse(dateRaw) ?? DateTime.now(),
    );
  }
}
