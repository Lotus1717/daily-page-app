import '../models/page_entry.dart';

/// 阅读统计
class ReadingStats {
  const ReadingStats({
    required this.totalDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.uniqueBooks,
    required this.thisWeekDays,
  });

  final int totalDays;
  final int currentStreak;
  final int longestStreak;
  final int uniqueBooks;
  final int thisWeekDays;

  static ReadingStats fromEntries(List<PageEntry> entries) {
    if (entries.isEmpty) {
      return const ReadingStats(
        totalDays: 0,
        currentStreak: 0,
        longestStreak: 0,
        uniqueBooks: 0,
        thisWeekDays: 0,
      );
    }

    final dates = entries.map((e) => e.dateKey).toSet().toList()..sort();
    final books = entries
        .where((e) => e.bookTitle != null && e.bookTitle!.isNotEmpty)
        .map((e) => e.bookTitle!)
        .toSet();

    final today = DateTime.now();
    final todayKey = _formatDate(today);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekKeys = List.generate(
      7,
      (i) => _formatDate(weekStart.add(Duration(days: i))),
    );
    final thisWeekDays = dates.where(weekKeys.contains).length;

    var currentStreak = 0;
    var longestStreak = 0;
    var streak = 0;
    DateTime? prev;

    for (final key in dates) {
      final d = DateTime.parse(key);
      if (prev == null || prev.add(const Duration(days: 1)) == d) {
        streak++;
      } else {
        streak = 1;
      }
      longestStreak = streak > longestStreak ? streak : longestStreak;
      prev = d;
    }

    if (dates.contains(todayKey)) {
      currentStreak = 1;
      var cursor = today.subtract(const Duration(days: 1));
      while (dates.contains(_formatDate(cursor))) {
        currentStreak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    } else if (dates.contains(_formatDate(today.subtract(const Duration(days: 1))))) {
      currentStreak = 1;
      var cursor = today.subtract(const Duration(days: 2));
      while (dates.contains(_formatDate(cursor))) {
        currentStreak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    return ReadingStats(
      totalDays: dates.length,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      uniqueBooks: books.length,
      thisWeekDays: thisWeekDays,
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
