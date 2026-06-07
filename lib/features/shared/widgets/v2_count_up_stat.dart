import 'package:flutter/material.dart';

/// Angka statistik dengan animasi count-up saat pertama kali tampil.
class V2CountUpStat extends StatefulWidget {
  const V2CountUpStat({
    super.key,
    required this.icon,
    required this.label,
    this.targetValue,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.textLabel,
  });

  final String icon;
  final String label;
  final double? targetValue;
  final String prefix;
  final String suffix;
  final int decimals;
  final String? textLabel;

  @override
  State<V2CountUpStat> createState() => _V2CountUpStatState();
}

class _V2CountUpStatState extends State<V2CountUpStat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _format(double value) {
    if (widget.decimals > 0) {
      return value.toStringAsFixed(widget.decimals);
    }
    return value.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Text(widget.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final valueText = widget.textLabel ??
                  '${widget.prefix}${_format((widget.targetValue ?? 0) * _anim.value)}${widget.suffix}';
              return Text(
                valueText,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
