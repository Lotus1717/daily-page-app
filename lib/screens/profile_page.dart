import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/reading_stats.dart';
import '../services/page_entry_service.dart';
import '../services/reminder_service.dart';
import '../services/weread_config_store.dart';
import 'history_page.dart';

/// 「我」— 阅读统计、微信读书
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _cookieCtrl = TextEditingController();
  bool _hasCookie = false;
  List<String> _savedKeys = [];

  @override
  void initState() {
    super.initState();
    _loadCookie();
  }

  Future<void> _loadCookie() async {
    final cookie = await WeReadConfigStore.getCookie();
    if (cookie != null) _cookieCtrl.text = cookie;
    setState(() {
      _hasCookie = cookie != null && cookie.isNotEmpty;
      _savedKeys = WeReadConfigStore.keysFromSaved(cookie);
    });
  }

  @override
  void dispose() {
    _cookieCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCookie() async {
    final cookie = _cookieCtrl.text.trim();
    if (cookie.isEmpty) return;

    final validation = WeReadConfigStore.validate(cookie);
    if (!validation.isValid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.error!)),
      );
      return;
    }

    await WeReadConfigStore.saveCookie(cookie);
    _cookieCtrl.text = validation.normalized!;
    setState(() {
      _hasCookie = true;
      _savedKeys = validation.savedKeys;
    });
    if (!mounted) return;
    final keyHint = validation.savedKeys.join('、');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cookie 已保存（字段：$keyHint）')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<PageEntryService>().allSorted;
    final stats = ReadingStats.fromEntries(entries);

    void openReflectionHistory() {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const HistoryPage()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('我')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _StreakSummary(stats: stats),
          const SizedBox(height: 12),
          _ReflectionHistoryEntry(
            count: entries.length,
            onTap: openReflectionHistory,
          ),
          const SizedBox(height: 20),
          _ReminderSection(),
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
                if (_savedKeys.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '已保存字段：${_savedKeys.join('、')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: _cookieCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'wr_vid=...; wr_skey=...; wr_rt=...',
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
                  '1. 电脑 Chrome 打开 weread.qq.com 并微信扫码登录\n'
                  '2. 在书架随便点开一本书（激活会话）\n'
                  '3. F12 → Application → Cookies → weread.qq.com\n'
                  '4. 复制全部 Cookie（必须含 wr_vid、wr_skey，建议含 wr_rt）\n'
                  '5. 粘贴后点「保存 Cookie」，再去「在读」点同步\n'
                  '6. 若仍失败，重新登录 weread 后重复上述步骤',
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
}

class _ReflectionHistoryEntry extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ReflectionHistoryEntry({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = count > 0
        ? '共 $count 条，点击查看'
        : '还没有记录，去「今日」写一句吧';

    return Material(
      color: AppTheme.card,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.highlightLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_note_rounded,
                      size: 24, color: AppTheme.highlight),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('感想记录',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textLight),
              ],
            ),
          ),
        ),
      ),
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

class _ReminderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final reminder = context.watch<ReminderService>();
    final entries = context.read<PageEntryService>();

    Future<void> pickTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
        helpText: '选择每日提醒时间',
      );
      if (picked != null && context.mounted) {
        await reminder.setTime(picked.hour, picked.minute, entries);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '每日提醒', icon: Icons.notifications_outlined),
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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '提醒读一页',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: reminder.enabled,
                    onChanged: (on) async {
                      final ok = await reminder.setEnabled(on, entries);
                      if (!on || ok || !context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请在系统设置中允许通知权限'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                reminder.enabled
                    ? '每天 ${reminder.timeLabel} 提醒（当天已写感想则跳过）'
                    : '开启后，在固定时间提醒你读一页、写一句',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textMuted, height: 1.4),
              ),
              if (reminder.enabled) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: pickTime,
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text('提醒时间：${reminder.timeLabel}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.highlight,
                    side: BorderSide(
                        color: AppTheme.highlight.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

