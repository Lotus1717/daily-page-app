import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/book_reflection_group.dart';
import '../models/page_entry.dart';
import '../services/page_entry_service.dart';
import '../services/share_service.dart';
import '../widgets/page_excerpt_preview.dart';
import 'book_history_page.dart';

enum _HistoryViewMode { all, byBook }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  _HistoryViewMode _mode = _HistoryViewMode.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('感想记录'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SegmentedButton<_HistoryViewMode>(
              segments: const [
                ButtonSegment(
                  value: _HistoryViewMode.all,
                  label: Text('全部'),
                ),
                ButtonSegment(
                  value: _HistoryViewMode.byBook,
                  label: Text('按书'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<PageEntryService>(
        builder: (context, svc, _) {
          if (svc.count == 0) {
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
          return _mode == _HistoryViewMode.all
              ? _AllTimelineList(
                  entries: svc.allSorted,
                  onDelete: (id) => _confirmDelete(context, svc, id),
                )
              : _BookGroupList(groups: svc.groupByBook());
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

class _AllTimelineList extends StatelessWidget {
  const _AllTimelineList({
    required this.entries,
    required this.onDelete,
  });

  final List<PageEntry> entries;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final entry = entries[i];
        final date = DateFormat('EEEE', 'zh_CN')
            .add_yMMMd()
            .format(DateFormat('yyyy-MM-dd').parse(entry.dateKey));
        return _HistoryCard(
          dateLabel: date,
          bookLabel: entry.bookTitle != null
              ? '${entry.bookTitle}${entry.author != null ? ' · ${entry.author}' : ''}'
              : null,
          chapterLabel: entry.sourceNote,
          pageContent: entry.pageContent,
          reflection: entry.reflection,
          onDelete: () => onDelete(entry.id),
          onShare: (anchor) =>
              ShareService.shareEntry(entry, anchorContext: anchor),
        );
      },
    );
  }
}

class _BookGroupList extends StatelessWidget {
  const _BookGroupList({required this.groups});

  final List<BookReflectionGroup> groups;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final group = groups[i];
        final lastDate = DateFormat('M月d日').format(group.lastWrittenAt);
        return Material(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookHistoryPage(
                    bookTitle: group.bookTitle,
                    author: group.author,
                    groupKey: group.groupKey,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: AppTheme.accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.bookTitle,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        if (group.author.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(group.author,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted)),
                        ],
                        const SizedBox(height: 4),
                        Text('${group.count} 条感想 · 最近 $lastDate',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textLight)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textLight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String dateLabel;
  final String? bookLabel;
  final String? chapterLabel;
  final String? pageContent;
  final String reflection;
  final VoidCallback onDelete;
  final void Function(BuildContext anchorContext) onShare;

  const _HistoryCard({
    required this.dateLabel,
    required this.bookLabel,
    required this.chapterLabel,
    required this.pageContent,
    required this.reflection,
    required this.onDelete,
    required this.onShare,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(dateLabel,
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
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: const Icon(Icons.ios_share_rounded,
                      size: 18, color: AppTheme.textMuted),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: '删除',
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(8),
                constraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppTheme.textMuted),
              ),
            ],
          ),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          const SizedBox(height: 8),
          PageExcerptPreview(content: pageContent),
          const SizedBox(height: 6),
          Text(reflection,
              style: const TextStyle(
                  fontSize: 13, height: 1.4, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
