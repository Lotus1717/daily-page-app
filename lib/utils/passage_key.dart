import '../models/daily_page_reading.dart';

/// 段落指纹：同一本书换页后生成新键，感想独立存储。
String passageKeyFor({
  required String bookTitle,
  required String content,
  String? sourceNote,
}) {
  return '${bookTitle.hashCode}_${(sourceNote ?? '').hashCode}_${content.hashCode}';
}

String passageKeyForPage(DailyPageReading page) => passageKeyFor(
      bookTitle: page.bookTitle,
      content: page.content,
      sourceNote: page.sourceNote,
    );

/// 按书归档的分组键（书名 + 作者）。
String bookGroupKey({String? bookTitle, String? author}) {
  final title = bookTitle?.trim() ?? '';
  final name = author?.trim() ?? '';
  if (title.isEmpty) return 'unknown';
  return name.isEmpty ? title : '$title|$name';
}
