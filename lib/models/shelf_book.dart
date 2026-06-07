enum ShelfBookSource { weread, manual }

class ShelfBook {
  final String id;
  final String? bookId;
  final String title;
  final String author;
  final String? cover;
  /// 是否在「在读书」队列中（最多 3 本）
  final bool inReading;
  final ShelfBookSource source;
  /// 上次被选中阅读的日期 yyyy-MM-dd
  final String? lastReadDateKey;

  const ShelfBook({
    required this.id,
    this.bookId,
    required this.title,
    this.author = '',
    this.cover,
    this.inReading = false,
    this.source = ShelfBookSource.manual,
    this.lastReadDateKey,
  });

  ShelfBook copyWith({
    String? id,
    String? bookId,
    String? title,
    String? author,
    String? cover,
    bool? inReading,
    ShelfBookSource? source,
    String? lastReadDateKey,
    bool clearLastReadDateKey = false,
  }) {
    return ShelfBook(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      cover: cover ?? this.cover,
      inReading: inReading ?? this.inReading,
      source: source ?? this.source,
      lastReadDateKey: clearLastReadDateKey
          ? null
          : (lastReadDateKey ?? this.lastReadDateKey),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (bookId != null) 'bookId': bookId,
        'title': title,
        'author': author,
        if (cover != null) 'cover': cover,
        'inReading': inReading,
        'source': source.name,
        if (lastReadDateKey != null) 'lastReadDateKey': lastReadDateKey,
      };

  factory ShelfBook.fromJson(Map<String, dynamic> json) {
    // 兼容旧版 enabled 字段
    final inReading = json['inReading'] as bool? ??
        json['enabled'] as bool? ??
        false;
    return ShelfBook(
      id: json['id'] as String,
      bookId: json['bookId'] as String?,
      title: json['title'] as String,
      author: json['author'] as String? ?? '',
      cover: json['cover'] as String?,
      inReading: inReading,
      source: ShelfBookSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => ShelfBookSource.manual,
      ),
      lastReadDateKey: json['lastReadDateKey'] as String?,
    );
  }

  factory ShelfBook.fromWeRead(Map<String, dynamic> json) {
    final bookId = json['book_id'] as String? ?? json['bookId'] as String?;
    return ShelfBook(
      id: bookId ?? 'manual-${json['title']}',
      bookId: bookId,
      title: json['title'] as String,
      author: json['author'] as String? ?? '',
      cover: json['cover'] as String?,
      inReading: false,
      source: ShelfBookSource.weread,
    );
  }
}
