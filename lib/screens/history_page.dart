import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/page_entry_service.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('历史记录')),
      body: Consumer<PageEntryService>(
        builder: (context, svc, _) {
          final entries = svc.allSorted;
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 48,
                      color: AppTheme.textLight.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    '还没有记录\n看完一页，记一句话吧',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        height: 1.6),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final entry = entries[i];
              final date = DateFormat('EEEE', 'zh_CN')
                  .add_yMMMd()
                  .format(
                      DateFormat('yyyy-MM-dd').parse(entry.dateKey));
              return _HistoryCard(
                dateLabel: date,
                bookLabel: entry.bookTitle != null
                    ? '${entry.bookTitle}${entry.author != null ? ' · ${entry.author}' : ''}'
                    : null,
                chapterLabel: entry.sourceNote,
                reflection: entry.reflection,
                onDelete: () => _confirmDelete(context, svc, entry.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PageEntryService svc,
    String entryId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这条记录？'),
        content: const Text('删除后无法恢复'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await svc.delete(entryId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
      }
    }
  }
}

class _HistoryCard extends StatelessWidget {
  final String dateLabel;
  final String? bookLabel;
  final String? chapterLabel;
  final String reflection;
  final VoidCallback onDelete;
  const _HistoryCard({
    required this.dateLabel,
    required this.bookLabel,
    required this.chapterLabel,
    required this.reflection,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateLabel,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.accent)),
                if (bookLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(bookLabel!,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                ],
                if (chapterLabel != null && chapterLabel!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(chapterLabel!,
                        style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.accent)),
                  ),
                ],
                const SizedBox(height: 6),
                Text(reflection,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppTheme.textMuted)),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: '删除',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
