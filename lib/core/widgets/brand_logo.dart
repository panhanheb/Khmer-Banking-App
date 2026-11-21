import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Original Khmer Digital Bank mark: a navy-to-blue tile with a gold
/// lotus-inspired "K" monogram.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.35),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: CustomPaint(painter: _MonogramPainter()),
    );
  }
}

class _MonogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..shader = AppColors.goldGradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Stem of the K.
    canvas.drawLine(
      Offset(w * 0.34, h * 0.26),
      Offset(w * 0.34, h * 0.74),
      paint,
    );
    // Arms shaped like lotus petals.
    final upper = Path()
      ..moveTo(w * 0.36, h * 0.52)
      ..quadraticBezierTo(w * 0.52, h * 0.30, w * 0.70, h * 0.26);
    final lower = Path()
      ..moveTo(w * 0.36, h * 0.52)
      ..quadraticBezierTo(w * 0.52, h * 0.70, w * 0.70, h * 0.74);
    canvas.drawPath(upper, paint);
    canvas.drawPath(lower, paint);
    // Small gold dot (the "digital" spark).
    canvas.drawCircle(
      Offset(w * 0.72, h * 0.50),
      w * 0.05,
      Paint()..color = AppColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
