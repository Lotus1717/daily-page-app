import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/daily_page_reading.dart';

class PageContentCard extends StatelessWidget {
  const PageContentCard({
    super.key,
    required this.page,
    this.onAnotherPage,
    this.anotherPageLoading = false,
  });

  final DailyPageReading page;
  final VoidCallback? onAnotherPage;
  final bool anotherPageLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
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
              Icon(Icons.book_rounded,
                  size: 16,
                  color: AppTheme.accent.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(page.bookTitle,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(page.author,
                style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textMuted)),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: AppTheme.accentLight),
          const SizedBox(height: 20),
          Text(
            page.content,
            style: const TextStyle(
              fontSize: 20,
              height: 1.8,
              color: AppTheme.textDark,
            ),
          ),
          if (page.sourceNote.isNotEmpty || onAnotherPage != null) ...[
            const SizedBox(height: 16),
            _PageFooterRow(
              sourceNote: page.sourceNote,
              onAnotherPage: onAnotherPage,
              loading: anotherPageLoading,
            ),
          ],
        ],
      ),
    );
  }
}

class _PageFooterRow extends StatelessWidget {
  const _PageFooterRow({
    required this.sourceNote,
    this.onAnotherPage,
    this.loading = false,
  });

  final String sourceNote;
  final VoidCallback? onAnotherPage;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: sourceNote.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
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
                  )
                : const SizedBox.shrink(),
          ),
        ),
        if (onAnotherPage != null) ...[
          const SizedBox(width: 12),
          _AnotherPageButton(onPressed: loading ? null : onAnotherPage),
        ],
      ],
    );
  }
}

class _AnotherPageButton extends StatelessWidget {
  const _AnotherPageButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled ? AppTheme.highlightLight : AppTheme.bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: enabled
                  ? AppTheme.highlight.withValues(alpha: 0.35)
                  : AppTheme.textLight.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.autorenew_rounded,
                size: 15,
                color: enabled ? AppTheme.highlight : AppTheme.textLight,
              ),
              const SizedBox(width: 5),
              Text(
                '换一页',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled ? AppTheme.highlight : AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
