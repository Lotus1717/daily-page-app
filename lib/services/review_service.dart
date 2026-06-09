import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/theme.dart';

/// 应用评分引导 — 第 7 条感想时触发一次
class ReviewService {
  ReviewService._();

  static const _key = 'review_prompt_count';
  static const _keyRated = 'review_already_rated';

  /// 保存感想后调用，检查是否需要弹出评分引导
  static Future<bool> shouldPrompt(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // 已评过，不再提示
    if (prefs.getBool(_keyRated) ?? false) return false;

    // 只弹一次：在第 7 条感想时触发
    final count = (prefs.getInt(_key) ?? 0) + 1;
    await prefs.setInt(_key, count);

    if (count == 7) {
      await _showPrompt(context);
      return true;
    }

    return false;
  }

  static Future<void> _showPrompt(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 600)); // 等保存完成
    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('喜欢拾页吗？'),
        content: const Text(
          '如果觉得不错，在 App Store 给我们一个评分吧！\n你的支持是持续改进的动力 ✨',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '稍后再说',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('去评分'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await _requestReview(context);
    }
  }

  static Future<void> _requestReview(BuildContext context) async {
    try {
      await InAppReview.instance.requestReview();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRated, true);
    } catch (e) {
      // 模拟器或测试设备可能不支持，静默失败
      debugPrint('Review request failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评分暂不可用，请在 App Store 中手动评价')),
        );
      }
    }
  }

  /// 重置评分状态（调试用）
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_keyRated);
  }
}
