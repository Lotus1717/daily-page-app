import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 打开外链 / 邮件，失败时给出 SnackBar 或复制备用信息
class ExternalLink {
  ExternalLink._();

  static Future<void> openPrivacyPolicy(
    BuildContext context, {
    required String url,
  }) async {
    await _open(
      context,
      Uri.parse(url),
      failMessage: '无法打开隐私政策，请检查网络',
      clipboardFallback: url,
      clipboardHint: '链接已复制到剪贴板',
    );
  }

  static Future<void> openFeedbackEmail(
    BuildContext context, {
    required String email,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeQuery({'subject': '拾页 · 意见反馈'}),
    );
    await _open(
      context,
      uri,
      failMessage: '未找到邮件应用',
      clipboardFallback: email,
      clipboardHint: '反馈邮箱已复制到剪贴板',
    );
  }

  static Future<void> _open(
    BuildContext context,
    Uri uri, {
    required String failMessage,
    String? clipboardFallback,
    String? clipboardHint,
  }) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await _fallback(context, failMessage, clipboardFallback, clipboardHint);
      }
    } catch (_) {
      await _fallback(context, failMessage, clipboardFallback, clipboardHint);
    }
  }

  static Future<void> _fallback(
    BuildContext context,
    String failMessage,
    String? clipboardFallback,
    String? clipboardHint,
  ) async {
    if (!context.mounted) return;
    if (clipboardFallback != null) {
      await Clipboard.setData(ClipboardData(text: clipboardFallback));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(clipboardHint ?? failMessage)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failMessage)),
    );
  }

  static String? _encodeQuery(Map<String, String> params) {
    if (params.isEmpty) return null;
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
