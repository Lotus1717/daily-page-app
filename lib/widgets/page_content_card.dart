import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/daily_page_reading.dart';

class PageContentCard extends StatelessWidget {
  final DailyPageReading page;
  const PageContentCard({super.key, required this.page});

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
          Container(
              height: 1, color: AppTheme.accentLight),
          const SizedBox(height: 20),
          Text(
            page.content,
            style: const TextStyle(
              fontSize: 20,
              height: 1.8,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          if (page.sourceNote.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(page.sourceNote,
                    style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.accent)),
              ),
            ),
        ],
      ),
    );
  }
}
