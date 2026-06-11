import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 将离屏 Widget 渲染为 PNG 图片字节。
class WidgetImageCapture {
  WidgetImageCapture._();

  static Future<Uint8List?> capture(
    BuildContext context,
    Widget widget, {
    double pixelRatio = 3.0,
  }) async {
    final key = GlobalKey();
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -10000,
        top: 0,
        child: RepaintBoundary(
          key: key,
          child: widget,
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 32));

    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }
}
