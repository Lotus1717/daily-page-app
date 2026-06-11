import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_branding.dart';
import '../models/page_entry.dart';
import '../utils/widget_image_capture.dart';
import '../widgets/share_card.dart';

/// 分享感想与书摘卡片
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
    final origin = _shareOrigin(anchorContext);

    try {
      final bytes = await WidgetImageCapture.capture(
        anchorContext,
        ShareCard(entry: entry),
      );

      if (bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/shiye_share_${entry.id}_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(bytes);

        final result = await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/png')],
          sharePositionOrigin: origin,
        );
        debugPrint('Share card result: ${result.status}');
        return;
      }

      debugPrint('Share card capture failed, falling back to text');
      await _shareText(entry, origin: origin);
    } catch (e, st) {
      debugPrint('Share failed: $e\n$st');
      if (!anchorContext.mounted) return;
      try {
        await _shareText(entry, origin: origin);
      } catch (fallbackError, fallbackSt) {
        debugPrint('Share text fallback failed: $fallbackError\n$fallbackSt');
        if (anchorContext.mounted) {
          ScaffoldMessenger.of(anchorContext).showSnackBar(
            const SnackBar(content: Text('分享失败，请重试')),
          );
        }
      }
    }
  }

  static Future<void> _shareText(
    PageEntry entry, {
    required Rect origin,
  }) async {
    final result = await Share.share(
      formatShareText(entry),
      sharePositionOrigin: origin,
    );
    debugPrint('Share text result: ${result.status}');
  }

  /// SnackBar 上点分享时，先收起 SnackBar，再弹系统面板。
  static void shareEntryAfterFrame(
    PageEntry entry, {
    required BuildContext anchorContext,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(anchorContext);
    messenger?.hideCurrentSnackBar();
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
