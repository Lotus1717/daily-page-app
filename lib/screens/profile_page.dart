import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/book_pick_strategy.dart';
import '../models/reading_stats.dart';
import '../services/bookshelf_service.dart';
import '../services/page_entry_service.dart';
import '../services/reading_config_service.dart';
import '../services/weread_config_store.dart';
import 'history_page.dart';

/// 「我」— 选书策略、微信读书、阅读统计
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _cookieCtrl = TextEditingController();
  bool _hasCookie = false;

  @override
  void initState() {
    super.initState();
    _loadCookie();
  }

  Future<void> _loadCookie() async {
    final cookie = await WeReadConfigStore.getCookie();
    if (cookie != null) _cookieCtrl.text = cookie;
    setState(() => _hasCookie = cookie != null && cookie.isNotEmpty);
  }

  @override
  void dispose() {
    _cookieCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCookie() async {
    final cookie = _cookieCtrl.text.trim();
    if (cookie.isEmpty) return;
    await WeReadConfigStore.saveCookie(cookie);
    setState(() => _hasCookie = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cookie 已保存')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<PageEntryService>().allSorted;
    final stats = ReadingStats.fromEntries(entries);
    final shelf = context.watch<BookshelfService>();
    final config = shelf.config;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: '历史记录',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _StreakSummary(stats: stats),
          const SizedBox(height: 20),
          _SectionTitle(title: '选书策略', icon: Icons.shuffle_rounded),
          const SizedBox(height: 8),
          ...BookPickStrategy.values.map(
            (s) => RadioListTile<BookPickStrategy>(
              value: s,
              groupValue: config.strategy,
              onChanged: (v) {
                if (v != null) config.setStrategy(v);
              },
              title: Text(s.label, style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                _strategyHint(s),
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              activeColor: AppTheme.highlight,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (config.strategy == BookPickStrategy.manual) ...[
            const SizedBox(height: 8),
            _ManualBookPicker(shelf: shelf, config: config),
          ],
          const SizedBox(height: 20),
          _SectionTitle(title: '阅读数据', icon: Icons.insights_outlined),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _MiniStat(
                      label: '累计', value: '${stats.totalDays} 天')),
              const SizedBox(width: 10),
              Expanded(
                  child: _MiniStat(
                      label: '最长连续', value: '${stats.longestStreak} 天')),
              const SizedBox(width: 10),
              Expanded(
                  child: _MiniStat(
                      label: '本周', value: '${stats.thisWeekDays} 天')),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: '微信读书', icon: Icons.menu_book_rounded),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasCookie ? '已连接' : '未连接',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        _hasCookie ? AppTheme.highlight : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _cookieCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'wr_vid=...; wr_skey=...',
                    filled: true,
                    fillColor: AppTheme.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saveCookie,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.highlight,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('保存 Cookie'),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'weread.qq.com 登录 → F12 → Cookies → 复制 wr_vid、wr_skey',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textMuted, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _strategyHint(BookPickStrategy s) {
    return switch (s) {
      BookPickStrategy.roundRobin => '按顺序每天换一本在读书',
      BookPickStrategy.longestUnread => '优先选最久没读的那本',
      BookPickStrategy.random => '每天在读书中随机一本',
      BookPickStrategy.manual => '在下方指定今日要读的书',
    };
  }
}

class _ManualBookPicker extends StatelessWidget {
  final BookshelfService shelf;
  final ReadingConfigService config;

  const _ManualBookPicker({required this.shelf, required this.config});

  @override
  Widget build(BuildContext context) {
    final reading = shelf.readingBooks;
    if (reading.isEmpty) {
      return const Text('请先在「在读」中加入书籍',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: reading.map((b) {
        final selected = config.manualBookId == b.id;
        return FilterChip(
          label: Text(b.title, style: const TextStyle(fontSize: 12)),
          selected: selected,
          onSelected: (_) => config.setManualBookId(b.id),
          selectedColor: AppTheme.highlightLight,
          checkmarkColor: AppTheme.highlight,
        );
      }).toList(),
    );
  }
}

class _StreakSummary extends StatelessWidget {
  final ReadingStats stats;
  const _StreakSummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('连续阅读',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
              Text('${stats.currentStreak} 天',
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('读过 ${stats.uniqueBooks} 本书',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
              Text('累计 ${stats.totalDays} 天',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.accent),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

