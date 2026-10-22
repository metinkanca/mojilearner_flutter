import 'package:flutter/material.dart';

import '../constants/theme.dart';

/// The little pointer that turns a white box into something being said.
///
/// Lived as a private copy inside the home screen until the meet-your-pet
/// screen needed the same shape. The two chat screens carry their own
/// variant with a colour and a left/right flip, which is a different widget
/// with a different job — this one is only ever the pet talking downward at
/// the pet.
class PixelTrianglePainter extends CustomPainter {
  const PixelTrianglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.retroDark
      ..style = PaintingStyle.fill;
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Outer Border (Black)
    var path = Path();
    path.moveTo(0, 0); // Top Left
    path.lineTo(size.width, 0); // Top Right
    path.lineTo(size.width / 2, size.height); // Bottom Tip
    path.close();
    canvas.drawPath(path, paint);

    // Inner (White) - slightly smaller/shifted up
    var innerPath = Path();
    innerPath.moveTo(4, 0);
    innerPath.lineTo(size.width - 4, 0);
    innerPath.lineTo(size.width / 2, size.height - 6);
    innerPath.close();
    canvas.drawPath(innerPath, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
