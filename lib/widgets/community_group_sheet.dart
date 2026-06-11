import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/community_config.dart';
import '../services/community_service.dart';

Future<void> showCommunityGroupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _CommunityGroupSheet(),
  );
}

class _CommunityGroupSheet extends StatefulWidget {
  const _CommunityGroupSheet();

  @override
  State<_CommunityGroupSheet> createState() => _CommunityGroupSheetState();
}

class _CommunityGroupSheetState extends State<_CommunityGroupSheet> {
  final _service = CommunityService();
  late Future<CommunityConfig> _configFuture;

  @override
  void initState() {
    super.initState();
    _configFuture = _service.fetchConfig();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: FutureBuilder<CommunityConfig>(
            future: _configFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final config = snapshot.data ?? _service.fallback;
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    config.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    config.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      height: 1.5,
                    ),
                  ),
                  if (config.highlights.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: config.highlights
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.highlightLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.highlight,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _QrImage(url: config.qrImageUrl),
                  const SizedBox(height: 12),
                  Text(
                    config.hint ?? '截图后微信扫码关注公众号',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textMuted,
                        side: BorderSide(
                          color: AppTheme.textLight.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('关闭'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _QrImage extends StatelessWidget {
  const _QrImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const _QrPlaceholder(message: '二维码配置更新中，请稍后再试');
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accentLight),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                width: 200,
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (_, __, ___) => const _QrPlaceholder(
              message: '二维码加载失败\n请检查网络或稍后再试',
            ),
          ),
        ),
      ),
    );
  }
}

class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentLight),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textMuted,
          height: 1.5,
        ),
      ),
    );
  }
}
