class PageEntry {
  /// SharedPreferences map key; legacy entries use [dateKey] only.
  final String id;
  final String dateKey;
  final String reflection;
  final DateTime createdAt;
  final String? bookTitle;
  final String? author;
  final String? sourceNote;

  const PageEntry({
    required this.id,
    required this.dateKey,
    required this.reflection,
    required this.createdAt,
    this.bookTitle,
    this.author,
    this.sourceNote,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'reflection': reflection,
        'createdAt': createdAt.toIso8601String(),
        if (bookTitle != null) 'bookTitle': bookTitle,
        if (author != null) 'author': author,
        if (sourceNote != null && sourceNote!.isNotEmpty)
          'sourceNote': sourceNote,
      };

  factory PageEntry.fromJson(Map<String, dynamic> json, {String? storageKey}) =>
      PageEntry(
        id: json['id'] as String? ?? storageKey ?? json['dateKey'] as String,
        dateKey: json['dateKey'] as String,
        reflection: json['reflection'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        bookTitle: json['bookTitle'] as String?,
        author: json['author'] as String?,
        sourceNote: json['sourceNote'] as String?,
      );
}
