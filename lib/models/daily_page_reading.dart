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
      sourceNote: json['source_note'] as String? ?? '',
      date: DateTime.tryParse(dateRaw) ?? DateTime.now(),
    );
  }
}
