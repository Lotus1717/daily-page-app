import 'package:flutter/material.dart';

import '../config/theme.dart';

class ReflectionView extends StatelessWidget {
  final String reflection;
  final VoidCallback? onEdit;
  const ReflectionView({super.key, required this.reflection, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.2)),
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
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Icon(Icons.edit_outlined,
                      size: 16, color: AppTheme.textMuted),
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
