import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_branding.dart';
import '../config/theme.dart';
import '../utils/external_link.dart';
import '../models/reading_stats.dart';
import '../services/page_entry_service.dart';
import '../services/reminder_service.dart';
import '../widgets/community_group_sheet.dart';
import 'history_page.dart';

/// 「我」— 阅读统计与设置
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
          const SizedBox(height: 12),
          _CommunityEntry(
            onTap: () => showCommunityGroupSheet(context),
          ),
          const SizedBox(height: 20),
          const _ReminderSection(),
          const SizedBox(height: 20),
          const _SectionTitle(title: '记录概览', icon: Icons.insights_outlined),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _MiniStat(
                      label: '累计记录', value: '${stats.totalDays} 天')),
              const SizedBox(width: 10),
              Expanded(
                  child: _MiniStat(
                      label: '最长连续', value: '${stats.longestStreak} 天')),
              const SizedBox(width: 10),
              Expanded(
                  child: _MiniStat(
                      label: '本周记录', value: '${stats.thisWeekDays} 天')),
            ],
          ),
          const SizedBox(height: 20),
          const _AboutSection(),
        ],
      ),
    );
  }
}

class _CommunityEntry extends StatelessWidget {
  const _CommunityEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups_rounded,
                      size: 22, color: AppTheme.accent),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('加入拾页书友会',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('和书友交流阅读与感想（可选）',
                          style: TextStyle(
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

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '关于', icon: Icons.info_outline_rounded),
        const SizedBox(height: 8),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        AppBranding.appIconAsset,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                AppBranding.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'v${AppBranding.version}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${AppBranding.tagline} · 独立开发',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.accentLight),
              _AboutActionTile(
                icon: Icons.mail_outline_rounded,
                title: '意见反馈',
                onTap: () => ExternalLink.openFeedbackEmail(
                  context,
                  email: AppBranding.feedbackEmail,
                ),
              ),
              const Divider(height: 1, indent: 14, color: AppTheme.accentLight),
              _AboutActionTile(
                icon: Icons.shield_outlined,
                title: '隐私政策',
                onTap: () => ExternalLink.openPrivacyPolicy(
                  context,
                  url: AppBranding.privacyPolicyUrl,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutActionTile extends StatelessWidget {
  const _AboutActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppTheme.textLight),
            ],
          ),
        ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('连续记录',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
                Text('${stats.currentStreak} 天',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('记过 ${stats.uniqueBooks} 本书',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 4),
              Text('累计记录 ${stats.totalDays} 天',
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
  const _ReminderSection();

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
