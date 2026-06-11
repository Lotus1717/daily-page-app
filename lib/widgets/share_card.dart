import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_branding.dart';
import '../config/theme.dart';
import '../models/page_entry.dart';

/// 书摘分享卡片，用于渲染为图片后分享。
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.entry});

  static const cardWidth = 360.0;
  static const excerptMaxLines = 5;

  final PageEntry entry;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('M月d日').format(
      DateFormat('yyyy-MM-dd').parse(entry.dateKey),
    );

    return Material(
      color: AppTheme.bg,
      child: SizedBox(
        width: cardWidth,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ExcerptCard(entry: entry),
              const SizedBox(height: 20),
              _Footer(dateLabel: date),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcerptCard extends StatelessWidget {
  const _ExcerptCard({required this.entry});

  final PageEntry entry;

  @override
  Widget build(BuildContext context) {
    final bookTitle = entry.bookTitle?.trim();
    final author = entry.author?.trim();
    final pageContent = entry.pageContent?.trim();
    final sourceNote = entry.sourceNote?.trim();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bookTitle != null && bookTitle.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.book_rounded,
                  size: 16,
                  color: AppTheme.accent.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    bookTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
            if (author != null && author.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  author,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Container(height: 1, color: AppTheme.accentLight),
            const SizedBox(height: 20),
          ],
          if (pageContent != null && pageContent.isNotEmpty)
            _FadedClampText(
              text: pageContent,
              maxLines: ShareCard.excerptMaxLines,
              fadeColor: AppTheme.card,
              style: const TextStyle(
                fontSize: 18,
                height: 1.8,
                color: AppTheme.textDark,
              ),
            )
          else if (sourceNote != null && sourceNote.isNotEmpty)
            Text(
              sourceNote,
              style: const TextStyle(
                fontSize: 16,
                height: 1.7,
                fontStyle: FontStyle.italic,
                color: AppTheme.textMuted,
              ),
            ),
          if (sourceNote != null &&
              sourceNote.isNotEmpty &&
              pageContent != null &&
              pageContent.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sourceNote,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 16,
                      color: AppTheme.accent.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '我的感想',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  entry.reflection,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 超出 [maxLines] 时底部渐变淡出，暗示还有更多内容。
class _FadedClampText extends StatelessWidget {
  const _FadedClampText({
    required this.text,
    required this.style,
    required this.maxLines,
    required this.fadeColor,
  });

  static const _fadeHeight = 40.0;

  final String text;
  final TextStyle style;
  final int maxLines;
  final Color fadeColor;

  static bool exceedsMaxLines({
    required String text,
    required TextStyle style,
    required int maxLines,
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showFade = exceedsMaxLines(
          text: text,
          style: style,
          maxLines: maxLines,
          maxWidth: constraints.maxWidth,
        );

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.clip,
              style: style,
            ),
            if (showFade)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _fadeHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          fadeColor.withValues(alpha: 0),
                          fadeColor.withValues(alpha: 0.92),
                          fadeColor,
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$dateLabel · ${AppBranding.name}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppBranding.tagline,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
