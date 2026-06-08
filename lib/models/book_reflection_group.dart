import 'page_entry.dart';

/// 按书籍聚合的感想记录。
class BookReflectionGroup {
  const BookReflectionGroup({
    required this.groupKey,
    required this.bookTitle,
    required this.author,
    required this.entries,
    required this.lastWrittenAt,
  });

  final String groupKey;
  final String bookTitle;
  final String author;
  final List<PageEntry> entries;
  final DateTime lastWrittenAt;

  int get count => entries.length;
}
