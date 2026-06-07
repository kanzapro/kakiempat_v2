import 'package:flutter/material.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';

/// Ilustrasi siluet orang berjalan dengan anjing di taman.
class WwwHeroIllustration extends StatelessWidget {
  const WwwHeroIllustration({
    super.key,
    this.parallaxOffset = 0,
    this.height = 220,
  });

  final double parallaxOffset;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, parallaxOffset * 0.08),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _ParkWalkPainter(parallaxOffset: parallaxOffset),
        ),
      ),
    );
  }
}

class _ParkWalkPainter extends CustomPainter {
  _ParkWalkPainter({required this.parallaxOffset});

  final double parallaxOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Langit & taman
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryLight.withValues(alpha: 0.15),
          AppColors.cream.withValues(alpha: 0.3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // Bukit hijau
    final hillPath = Path()
      ..moveTo(0, h * 0.72 + parallaxOffset * 0.05)
      ..quadraticBezierTo(w * 0.3, h * 0.55, w * 0.55, h * 0.68 + parallaxOffset * 0.03)
      ..quadraticBezierTo(w * 0.85, h * 0.82, w, h * 0.65 + parallaxOffset * 0.04)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      hillPath,
      Paint()..color = AppColors.primary.withValues(alpha: 0.18),
    );

    // Pohon kiri
    _drawTree(canvas, Offset(w * 0.12 + parallaxOffset * 0.02, h * 0.62), 0.9);
    _drawTree(canvas, Offset(w * 0.82 - parallaxOffset * 0.02, h * 0.58), 0.75);

    // Orang + anjing (siluet)
    final walkX = w * 0.48 + parallaxOffset * 0.08;
    final groundY = h * 0.74 + parallaxOffset * 0.04;
    _drawPersonWithDog(canvas, Offset(walkX, groundY));
  }

  void _drawTree(Canvas canvas, Offset base, double scale) {
    final trunk = Paint()..color = const Color(0xFF795548).withValues(alpha: 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: base, width: 10 * scale, height: 28 * scale),
        const Radius.circular(4),
      ),
      trunk,
    );
    canvas.drawCircle(
      base.translate(0, -22 * scale),
      22 * scale,
      Paint()..color = AppColors.primary.withValues(alpha: 0.35),
    );
  }

  void _drawPersonWithDog(Canvas canvas, Offset base) {
    final silhouette = Paint()..color = AppColors.primaryDark.withValues(alpha: 0.55);

    // Anjing
    canvas.drawOval(
      Rect.fromCenter(center: base.translate(-28, 4), width: 36, height: 18),
      silhouette,
    );
    canvas.drawCircle(base.translate(-44, -2), 8, silhouette);

    // Orang
    canvas.drawCircle(base.translate(0, -38), 12, silhouette);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: base.translate(0, -14), width: 18, height: 32),
        const Radius.circular(8),
      ),
      silhouette,
    );
    // Kaki
    canvas.drawLine(base.translate(-6, 2), base.translate(-10, 18), silhouette..strokeWidth = 5);
    canvas.drawLine(base.translate(6, 2), base.translate(12, 16), silhouette..strokeWidth = 5);
    // Tali
    canvas.drawLine(base.translate(-8, -8), base.translate(-36, 0), Paint()
      ..color = AppColors.primaryDark.withValues(alpha: 0.4)
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_ParkWalkPainter old) => old.parallaxOffset != parallaxOffset;
}
