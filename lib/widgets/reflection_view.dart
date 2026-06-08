import 'package:flutter/material.dart';

import '../config/theme.dart';

class ReflectionView extends StatelessWidget {
  final String reflection;
  final VoidCallback? onEdit;
  final void Function(BuildContext anchorContext)? onShare;

  const ReflectionView({
    super.key,
    required this.reflection,
    this.onEdit,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.check_circle_outline_rounded,
                  size: 16, color: AppTheme.accent),
              const SizedBox(width: 6),
              const Text('已记录',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent)),
              const Spacer(),
              if (onShare != null)
                Builder(
                  builder: (btnContext) => IconButton(
                    onPressed: () => onShare!(btnContext),
                    tooltip: '分享',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    icon: const Icon(Icons.ios_share_rounded,
                        size: 18, color: AppTheme.textMuted),
                  ),
                ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  tooltip: '编辑感想',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppTheme.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(reflection,
              style: const TextStyle(
                  fontSize: 15, height: 1.6, color: AppTheme.textDark)),
        ],
      ),
    );
  }
}
