import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/shelf_book.dart';
import '../services/bookshelf_service.dart';
import '../services/daily_page_service.dart';
import '../services/reading_config_service.dart';
import '../services/weread_config_store.dart';
import '../services/weread_service.dart';

/// 在读书 Tab — 管理最多 3 本并行在读书
class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  bool _syncing = false;

  String _formatSyncError(Object error) {
    var msg = error.toString();
    const prefix = 'Exception: ';
    if (msg.startsWith(prefix)) msg = msg.substring(prefix.length);
    return msg;
  }

  Future<void> _syncFromWeRead() async {
    final cookie = await WeReadConfigStore.getCookie();
    if (cookie == null || cookie.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在「我」中配置微信读书 Cookie')),
      );
      return;
    }

    setState(() => _syncing = true);
    try {
      final result = await WeReadService().syncShelf(cookie);
      if (!mounted) return;
      await context.read<BookshelfService>().mergeWeReadBooks(result.books);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已同步 ${result.count} 本书')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('同步失败：${_formatSyncError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _addManualBook() async {
    final result = await showDialog<({String title, String author})>(
      context: context,
      builder: (ctx) => const _AddBookDialog(),
    );
    if (result != null && result.title.isNotEmpty && mounted) {
      await context.read<BookshelfService>().addManual(
            result.title,
            result.author,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shelf = context.watch<BookshelfService>();
    final pageSvc = context.watch<DailyPageService>();
    final reading = shelf.readingBooks;
    final max = ReadingConfigService.maxReadingBooks;
    final todayId = shelf.config.todayBookId ?? pageSvc.pickedBook?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('在读'),
        actions: [
          IconButton(
            icon: _syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            onPressed: _syncing ? null : _syncFromWeRead,
            tooltip: '同步微信读书',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addManualBook,
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.add),
        label: const Text('添加'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          _ReadingQueueHeader(count: reading.length, max: max),
          const SizedBox(height: 12),
          if (reading.isEmpty)
            const _EmptyReadingHint()
          else
            ...reading.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ReadingBookCard(
                  book: b,
                  isQueue: true,
                  isToday: b.id == todayId,
                  onSetToday: b.id == todayId
                      ? null
                      : () => pageSvc.readBookToday(b),
                  onRemove: () => shelf.removeFromReading(b.id),
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text('全部藏书',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '点 + 加入在读书（最多 $max 本）',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          if (shelf.books.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('暂无藏书，同步微信读书或手动添加',
                    style: TextStyle(color: AppTheme.textMuted)),
              ),
            )
          else
            ...shelf.books.where((b) => !b.inReading).map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ReadingBookCard(
                      book: b,
                      isQueue: false,
                      onAdd: shelf.canAddToReading
                          ? () async {
                              final ok = await shelf.addToReading(b.id);
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('在读书已满 $max 本，请先移除一本'),
                                  ),
                                );
                              }
                            }
                          : null,
                      onRemove: () => shelf.remove(b.id),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ReadingQueueHeader extends StatelessWidget {
  final int count;
  final int max;
  const _ReadingQueueHeader({required this.count, required this.max});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.highlightLight, AppTheme.accentBg],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded,
                  size: 20, color: AppTheme.highlight),
              const SizedBox(width: 8),
              Text('在读书 $count / $max',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            count == 0
                ? '选 1–3 本书并行阅读，每日从中拆一页'
                : '今日书摘只会从这 ${count} 本中选取',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _EmptyReadingHint extends StatelessWidget {
  const _EmptyReadingHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: const Text(
        '还没有在读书。从下方「全部藏书」中加入，或同步微信读书。',
        style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.5),
      ),
    );
  }
}

class _ReadingBookCard extends StatelessWidget {
  final ShelfBook book;
  final bool isQueue;
  final bool isToday;
  final VoidCallback? onAdd;
  final VoidCallback? onSetToday;
  final VoidCallback? onRemove;

  const _ReadingBookCard({
    required this.book,
    required this.isQueue,
    this.isToday = false,
    this.onAdd,
    this.onSetToday,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        boxShadow: isQueue ? AppTheme.cardShadow : null,
        border: isQueue
            ? Border.all(color: AppTheme.highlight.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (book.author.isNotEmpty)
                  Text(book.author,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted)),
                if (book.lastReadDateKey != null)
                  Text('上次阅读 ${book.lastReadDateKey}',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textLight)),
              ],
            ),
          ),
          if (book.source == ShelfBookSource.weread)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.highlightLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('微信',
                  style: TextStyle(fontSize: 10, color: AppTheme.highlight)),
            ),
          if (isToday)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('在读中',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent)),
            )
          else if (onSetToday != null)
            TextButton(
              onPressed: onSetToday,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.highlight,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('今日读这本', style: TextStyle(fontSize: 11)),
            ),
          if (onAdd != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 22),
              color: AppTheme.highlight,
              onPressed: onAdd,
              tooltip: '加入在读书',
            ),
          if (onRemove != null)
            IconButton(
              icon: Icon(
                isQueue ? Icons.remove_circle_outline : Icons.delete_outline,
                size: 20,
              ),
              color: AppTheme.textLight,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _AddBookDialog extends StatefulWidget {
  const _AddBookDialog();

  @override
  State<_AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<_AddBookDialog> {
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();

  @override
  void dispose() {
    // 对话框关闭动画期间 TextField 仍会访问 controller，需延迟释放
    final titleCtrl = _titleCtrl;
    final authorCtrl = _authorCtrl;
    super.dispose();
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      titleCtrl.dispose();
      authorCtrl.dispose();
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(context, (title: title, author: _authorCtrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('手动添加'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: '书名'),
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
          TextField(
            controller: _authorCtrl,
            decoration: const InputDecoration(labelText: '作者（可选）'),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('添加'),
        ),
      ],
    );
  }
}
