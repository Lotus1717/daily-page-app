import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:daily_page/models/page_entry.dart';
import 'package:daily_page/models/reading_stats.dart';

PageEntry _entry(String dateKey, {String? bookTitle, String id = ''}) =>
    PageEntry(
      id: id.isEmpty ? dateKey : id,
      dateKey: dateKey,
      reflection: '感想',
      createdAt: DateTime.parse('${dateKey}T12:00:00'),
      bookTitle: bookTitle,
    );

String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

String _daysAgo(int n) =>
    DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: n)));

void main() {
  group('ReadingStats.fromEntries', () {
    test('empty entries returns zeros', () {
      const stats = ReadingStats(
        totalDays: 0,
        currentStreak: 0,
        longestStreak: 0,
        uniqueBooks: 0,
        thisWeekDays: 0,
      );
      expect(ReadingStats.fromEntries([]), stats);
    });

    test('counts unique dates and books', () {
      final stats = ReadingStats.fromEntries([
        _entry('2026-06-05', bookTitle: '书A'),
        _entry('2026-06-06', bookTitle: '书B'),
        _entry('2026-06-06', bookTitle: '书C', id: '2026-06-06|书C'),
      ]);
      expect(stats.totalDays, 2);
      expect(stats.uniqueBooks, 3);
    });

    test('current streak includes today when entry exists', () {
      final today = _todayKey();
      final stats = ReadingStats.fromEntries([
        _entry(_daysAgo(2)),
        _entry(_daysAgo(1)),
        _entry(today),
      ]);
      expect(stats.currentStreak, 3);
      expect(stats.longestStreak, 3);
    });

    test('current streak counts from yesterday when today empty', () {
      final stats = ReadingStats.fromEntries([
        _entry(_daysAgo(3)),
        _entry(_daysAgo(2)),
        _entry(_daysAgo(1)),
      ]);
      expect(stats.currentStreak, 3);
    });

    test('longest streak across a gap', () {
      final stats = ReadingStats.fromEntries([
        _entry('2026-06-01'),
        _entry('2026-06-02'),
        _entry('2026-06-03'),
        _entry('2026-06-10'),
        _entry('2026-06-11'),
      ]);
      expect(stats.longestStreak, 3);
      expect(stats.totalDays, 5);
    });

    test('thisWeekDays counts entries in current week', () {
      final today = DateTime.now();
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final monday = DateFormat('yyyy-MM-dd').format(weekStart);
      final wednesday =
          DateFormat('yyyy-MM-dd').format(weekStart.add(const Duration(days: 2)));

      final stats = ReadingStats.fromEntries([
        _entry(monday),
        _entry(wednesday),
        _entry('2020-01-01'),
      ]);
      expect(stats.thisWeekDays, 2);
    });
  });
}
