import 'package:flutter/material.dart';
import '../constants/theme.dart';
import 'ascii_face.dart';

class ModernAvatar extends StatelessWidget {
  final double size;
  final String openFace;
  final String? closedFace;
  final Color? characterColor;
  final Color? backgroundColor;

  const ModernAvatar({
    super.key, 
    this.size = 64,
    this.openFace = '( ^_^ )',
    this.closedFace,
    this.characterColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.card,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary, width: 2),
      ),
      child: Center(
        child: AsciiFace(
          size: size * 0.4, 
          face: openFace,
          color: characterColor,
        ),
      ),
    );
  }
}
