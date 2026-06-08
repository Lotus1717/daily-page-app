import 'package:flutter/material.dart';

import '../config/theme.dart';

/// 历史记录中的书摘原文预览（可展开）
class PageExcerptPreview extends StatefulWidget {
  const PageExcerptPreview({
    super.key,
    required this.content,
    this.missingLabel = '原文未保存（旧版记录）',
  });

  final String? content;
  final String missingLabel;

  @override
  State<PageExcerptPreview> createState() => _PageExcerptPreviewState();
}

class _PageExcerptPreviewState extends State<PageExcerptPreview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final content = widget.content?.trim();
    if (content == null || content.isEmpty) {
      return Text(
        widget.missingLabel,
        style: const TextStyle(
          fontSize: 11,
          fontStyle: FontStyle.italic,
          color: AppTheme.textLight,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppTheme.textMuted,
          ),
        ),
        if (content.length > 80)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppTheme.accent,
            ),
            child: Text(_expanded ? '收起原文' : '展开原文'),
          ),
      ],
    );
  }
}
