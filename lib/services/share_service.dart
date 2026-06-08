import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_branding.dart';
import '../models/page_entry.dart';

/// 分享感想与书摘摘要
class ShareService {
  ShareService._();

  static const _excerptLimit = 120;

  static String formatShareText(PageEntry entry) {
    final date = DateFormat('M月d日').format(
      DateFormat('yyyy-MM-dd').parse(entry.dateKey),
    );
    final buffer = StringBuffer('📖 ${AppBranding.name} · $date\n\n');

    if (entry.bookTitle != null && entry.bookTitle!.isNotEmpty) {
      buffer.write('《${entry.bookTitle}》');
      if (entry.author != null && entry.author!.isNotEmpty) {
        buffer.write(' · ${entry.author}');
      }
      buffer.writeln();
    }

    if (entry.pageContent != null && entry.pageContent!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('「${_truncate(entry.pageContent!)}」');
    } else if (entry.sourceNote != null && entry.sourceNote!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('（${entry.sourceNote}）');
    }

    buffer.writeln();
    buffer.writeln('💭 我的感想：');
    buffer.writeln(entry.reflection);
    buffer.writeln();
    buffer.write('—— ${AppBranding.tagline}');
    return buffer.toString();
  }

  /// [anchorContext] 用于 iOS 弹出分享面板定位；传按钮所在 context 最稳。
  static Future<void> shareEntry(
    PageEntry entry, {
    required BuildContext anchorContext,
  }) async {
    final text = formatShareText(entry);
    final origin = _shareOrigin(anchorContext);

    try {
      final result = await Share.share(
        text,
        sharePositionOrigin: origin,
      );
      debugPrint('Share result: ${result.status}');
    } catch (e, st) {
      debugPrint('Share failed: $e\n$st');
      if (anchorContext.mounted) {
        ScaffoldMessenger.of(anchorContext).showSnackBar(
          const SnackBar(content: Text('分享失败，请重试')),
        );
      }
    }
  }

  /// SnackBar 上点分享时，等 SnackBar 收起后再弹系统面板。
  static void shareEntryAfterFrame(
    PageEntry entry, {
    required BuildContext anchorContext,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!anchorContext.mounted) return;
      shareEntry(entry, anchorContext: anchorContext);
    });
  }

  static Rect _shareOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 2,
      height: 2,
    );
  }

  static String _truncate(String text) {
    final trimmed = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.length <= _excerptLimit) return trimmed;
    return '${trimmed.substring(0, _excerptLimit)}…';
  }
}
