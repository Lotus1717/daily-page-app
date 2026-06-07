import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/app_branding.dart';
import '../config/theme.dart';
import '../models/reading_stats.dart';
import '../services/bookshelf_service.dart';
import '../services/daily_page_service.dart';
import '../services/page_entry_service.dart';
import '../services/reflection_prompt_service.dart';
import '../widgets/page_content_card.dart';
import '../widgets/reflection_input.dart';
import '../widgets/reflection_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  String? _lastPromptKey;
  DailyPageService? _pageSvc;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pageSvc = context.read<DailyPageService>();
      _pageSvc!.addListener(_onPageUpdated);
      _onPageUpdated();
    });
  }

  @override
  void dispose() {
    _pageSvc?.removeListener(_onPageUpdated);
    _controller.dispose();
    super.dispose();
  }

  void _onPageUpdated() {
    if (!mounted) return;
    final pageSvc = context.read<DailyPageService>();
    final promptSvc = context.read<ReflectionPromptService>();
    final page = pageSvc.page;
    if (page == null || pageSvc.loading) return;

    final key = '${page.bookTitle}:${page.content.hashCode}';
    if (_lastPromptKey == key) return;
    _lastPromptKey = key;
    promptSvc.fetchQuestion(
      deviceId: pageSvc.deviceId ?? 'local',
      bookTitle: page.bookTitle,
      content: page.content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entrySvc = context.watch<PageEntryService>();
    final pageSvc = context.watch<DailyPageService>();
    final shelfSvc = context.watch<BookshelfService>();
    final promptSvc = context.watch<ReflectionPromptService>();
    final bookTitle = pageSvc.page?.bookTitle;
    final hasWritten =
        entrySvc.hasWrittenFor(_dateKey, bookTitle: bookTitle);
    final entry = entrySvc.entryFor(_dateKey, bookTitle: bookTitle);
    final stats = ReadingStats.fromEntries(entrySvc.allSorted);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final showReflectionSaveBar = !hasWritten &&
        pageSvc.page != null &&
        !pageSvc.loading &&
        keyboardInset > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppBranding.name),
        actions: [
          if (stats.currentStreak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text('🔥 ${stats.currentStreak}',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.accent)),
              ),
            ),
          if (pageSvc.discoveryMode)
            TextButton.icon(
              onPressed: pageSvc.loading ? null : () {
                _lastPromptKey = null;
                promptSvc.reset();
                pageSvc.switchBook().then((_) => _onPageUpdated());
              },
              icon: const Icon(Icons.shuffle_rounded, size: 18),
              label: const Text('换一本'),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              onPressed: pageSvc.loading
                  ? null
                  : () {
                      _lastPromptKey = null;
                      promptSvc.reset();
                      pageSvc.refresh().then((_) => _onPageUpdated());
                    },
              tooltip: '刷新',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _DateBadge(),
                        const Spacer(),
                        if (!pageSvc.discoveryMode)
                          Text(
                            shelfSvc.config.strategy.label,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textLight),
                          )
                        else
                          const Text(
                            '随机探索',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textLight),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!pageSvc.discoveryMode && !shelfSvc.hasReadingBooks)
                      const _ShelfHintBanner(),
                    if (!pageSvc.discoveryMode && !shelfSvc.hasReadingBooks)
                      const SizedBox(height: 12),
                    if (pageSvc.discoveryMode &&
                        pageSvc.page == null &&
                        !pageSvc.loading)
                      const _DiscoveryHintBanner(),
                    if (pageSvc.discoveryMode &&
                        pageSvc.page == null &&
                        !pageSvc.loading)
                      const SizedBox(height: 12),
                    if (pageSvc.loading)
                      const _LoadingCard()
                    else if (pageSvc.page != null) ...[
                      PageContentCard(page: pageSvc.page!),
                    ] else
                      _ErrorCard(
                        message: pageSvc.error ?? '加载失败',
                        onRetry: () => pageSvc.refresh(),
                      ),
                    const SizedBox(height: 20),
                    if (hasWritten && entry != null)
                      ReflectionView(
                        reflection: entry.reflection,
                        onEdit: () => _editReflection(context),
                      )
                    else if (pageSvc.page != null) ...[
                      if (promptSvc.loading)
                        const _AiPromptLoading()
                      else if (promptSvc.question != null)
                        _AiPromptCard(question: promptSvc.question!),
                      if (promptSvc.question != null || promptSvc.loading)
                        const SizedBox(height: 12),
                      ReflectionInput(
                        controller: _controller,
                        hint: promptSvc.question ?? '读完这一页，你想到了一句话…',
                        onSubmit: (t) => _saveReflection(context, t),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (showReflectionSaveBar)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.highlightLight,
                  border: Border(
                    top: BorderSide(
                        color: AppTheme.highlight.withValues(alpha: 0.12)),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final t = _controller.text.trim();
                        if (t.isNotEmpty) _saveReflection(context, t);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.highlight,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('记下来'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _saveReflection(BuildContext context, String text) {
    final page = context.read<DailyPageService>().page;
    context.read<PageEntryService>().save(
          _dateKey,
          text,
          bookTitle: page?.bookTitle,
          author: page?.author,
          sourceNote: page?.sourceNote,
        );
    _controller.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已记下今天的感想')),
    );
  }

  void _editReflection(BuildContext context) {
    final page = context.read<DailyPageService>().page;
    final entry = context.read<PageEntryService>().entryFor(
          _dateKey,
          bookTitle: page?.bookTitle,
        );
    final ctrl = TextEditingController(text: entry?.reflection ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('编辑感想',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '写下一句话…',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppTheme.bg,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final t = ctrl.text.trim();
                  if (t.isEmpty) return;
                  final page = context.read<DailyPageService>().page;
                  context.read<PageEntryService>().save(
                        _dateKey,
                        t,
                        bookTitle: entry?.bookTitle ?? page?.bookTitle,
                        author: entry?.author ?? page?.author,
                        sourceNote: entry?.sourceNote ?? page?.sourceNote,
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已更新感想')),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('保存'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AiPromptCard extends StatelessWidget {
  final String question;
  const _AiPromptCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology_outlined,
              size: 18, color: AppTheme.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('想一想',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accent)),
                const SizedBox(height: 4),
                Text(question,
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppTheme.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiPromptLoading extends StatelessWidget {
  const _AiPromptLoading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 8),
        Text('正在想一个问题…',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ],
    );
  }
}

class _DiscoveryHintBanner extends StatelessWidget {
  const _DiscoveryHintBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.highlightLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.explore_outlined, size: 16, color: AppTheme.highlight),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '未配置微信读书，正在从书海随机选书。右上角「换一本」可切换',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelfHintBanner extends StatelessWidget {
  const _ShelfHintBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppTheme.accent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '去「在读」加入 1–3 本书，每日从中拆一页',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final wd = DateFormat('EEEE', 'zh_CN').format(now);
    final md = DateFormat('M月d日').format(now);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$md $wd',
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.accent),
      ),
    );
  }
}

class _LoadingCard extends StatefulWidget {
  const _LoadingCard();

  @override
  State<_LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<_LoadingCard> {
  static const _texts = ['正在翻书…', '在找今天那一页…', '书架轻轻作响…'];
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() => _index = (_index + 1) % _texts.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accent.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _texts[_index],
                key: ValueKey(_index),
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.accentLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 32, color: AppTheme.accent),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('重试'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.highlight,
              side: BorderSide(
                  color: AppTheme.highlight.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
