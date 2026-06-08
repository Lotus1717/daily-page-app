import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/page_entry.dart';
import '../services/page_entry_service.dart';
import '../services/share_service.dart';
import '../widgets/page_excerpt_preview.dart';

class BookHistoryPage extends StatelessWidget {
  const BookHistoryPage({
    super.key,
    required this.bookTitle,
    required this.author,
    required this.groupKey,
  });

  final String bookTitle;
  final String author;
  final String groupKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          bookTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Consumer<PageEntryService>(
        builder: (context, svc, _) {
          final entries = svc.entriesForBook(groupKey);
          if (entries.isEmpty) {
            return const Center(
              child: Text('暂无记录',
                  style: TextStyle(color: AppTheme.textMuted)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _HistoryEntryCard(
              entry: entries[i],
              onDelete: () => _confirmDelete(context, svc, entries[i].id),
              onShare: (anchor) =>
                  ShareService.shareEntry(entries[i], anchorContext: anchor),
            ),
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
    }
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.entry,
    required this.onDelete,
    required this.onShare,
  });

  final PageEntry entry;
  final VoidCallback onDelete;
  final void Function(BuildContext anchorContext) onShare;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE', 'zh_CN')
        .add_yMMMd()
        .format(DateFormat('yyyy-MM-dd').parse(entry.dateKey));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(date,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.accent)),
              ),
              Builder(
                builder: (btnContext) => IconButton(
                  onPressed: () => onShare(btnContext),
                  tooltip: '分享',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.ios_share_rounded,
                      size: 18, color: AppTheme.textMuted),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: '删除',
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppTheme.textMuted),
              ),
            ],
          ),
          if (entry.sourceNote != null && entry.sourceNote!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(entry.sourceNote!,
                  style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.accent)),
            ),
          ],
          const SizedBox(height: 8),
          PageExcerptPreview(content: entry.pageContent),
          const SizedBox(height: 8),
          Text(entry.reflection,
              style: const TextStyle(
                  fontSize: 13, height: 1.4, color: AppTheme.textDark)),
        ],
      ),
    );
  }
}
