import 'package:flutter/material.dart';

class V2SkeletonBox extends StatelessWidget {
  const V2SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class V2ListSkeleton extends StatelessWidget {
  const V2ListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const Row(
        children: [
          V2SkeletonBox(width: 48, height: 48, radius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                V2SkeletonBox(height: 14),
                SizedBox(height: 8),
                V2SkeletonBox(width: 120, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class V2GridSkeleton extends StatelessWidget {
  const V2GridSkeleton({super.key, this.columns = 2});

  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: columns * 2,
      itemBuilder: (context, index) =>
          const V2SkeletonBox(height: 120, radius: 16),
    );
  }
}

/// Skeleton dompet: saldo + beberapa baris riwayat.
class V2WalletSkeleton extends StatelessWidget {
  const V2WalletSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        V2SkeletonBox(height: 120, radius: 16),
        SizedBox(height: 16),
        V2SkeletonBox(height: 48, radius: 12),
        SizedBox(height: 24),
        V2SkeletonBox(width: 160, height: 14),
        SizedBox(height: 12),
        V2SkeletonBox(height: 56, radius: 12),
        SizedBox(height: 8),
        V2SkeletonBox(height: 56, radius: 12),
        SizedBox(height: 24),
        V2SkeletonBox(width: 180, height: 14),
        SizedBox(height: 12),
        V2SkeletonBox(height: 72, radius: 12),
        SizedBox(height: 8),
        V2SkeletonBox(height: 72, radius: 12),
      ],
    );
  }
}

/// Skeleton chat: gelembung pesan kiri/kanan.
class V2ChatSkeleton extends StatelessWidget {
  const V2ChatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Align(
          alignment: Alignment.centerLeft,
          child: V2SkeletonBox(width: 220, height: 48, radius: 12),
        ),
        SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: V2SkeletonBox(width: 180, height: 40, radius: 12),
        ),
        SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: V2SkeletonBox(width: 260, height: 56, radius: 12),
        ),
        SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: V2SkeletonBox(width: 200, height: 48, radius: 12),
        ),
      ],
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: 0.45 + (_ctrl.value * 0.55),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
