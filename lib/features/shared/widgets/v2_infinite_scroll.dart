import 'package:flutter/material.dart';

/// Trigger [onLoadMore] saat scroll mendekati bawah (infinite scroll).
class V2InfiniteScroll extends StatelessWidget {
  const V2InfiniteScroll({
    super.key,
    required this.child,
    required this.onLoadMore,
    this.threshold = 200,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onLoadMore;
  final double threshold;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is! ScrollEndNotification && n is! ScrollUpdateNotification) {
          return false;
        }
        final metrics = n.metrics;
        if (metrics.maxScrollExtent - metrics.pixels <= threshold) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}
