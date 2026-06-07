class PageEntry {
  final String dateKey;
  final String reflection;
  final DateTime createdAt;
  final String? bookTitle;
  final String? author;

  const PageEntry({
    required this.dateKey,
    required this.reflection,
    required this.createdAt,
    this.bookTitle,
    this.author,
  });

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'reflection': reflection,
        'createdAt': createdAt.toIso8601String(),
        if (bookTitle != null) 'bookTitle': bookTitle,
        if (author != null) 'author': author,
      };

  factory PageEntry.fromJson(Map<String, dynamic> json) => PageEntry(
        dateKey: json['dateKey'] as String,
        reflection: json['reflection'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        bookTitle: json['bookTitle'] as String?,
        author: json['author'] as String?,
      );
}
