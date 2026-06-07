import 'package:flutter/material.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';

/// Indikator denyut hijau untuk status polling / permintaan baru sitter.
class SitterPulseDot extends StatefulWidget {
  const SitterPulseDot({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<SitterPulseDot> createState() => _SitterPulseDotState();
}

class _SitterPulseDotState extends State<SitterPulseDot>
    with SingleTickerProviderStateMixin {
  static const _dotSize = 8.0;
  static const _maxScale = 2.0;

  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scale = Tween<double>(begin: 1.0, end: _maxScale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(SitterPulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.isActive) {
      if (!_ctrl.isAnimating) _ctrl.repeat();
    } else {
      _ctrl
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _dotSize * _maxScale,
      height: _dotSize * _maxScale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isActive)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scale.value,
                  child: Opacity(
                    opacity: _opacity.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: _dotSize,
                height: _dotSize,
                decoration: const BoxDecoration(
                  color: AppColors.offerGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Container(
            width: _dotSize,
            height: _dotSize,
            decoration: const BoxDecoration(
              color: AppColors.offerGreen,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
