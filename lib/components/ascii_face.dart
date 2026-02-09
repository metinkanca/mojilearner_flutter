import 'package:flutter/material.dart';

class AsciiFace extends StatelessWidget {
  final String face;
  final double size;
  final Color? color;

  const AsciiFace({
    super.key, 
    this.face = '( •_• )', 
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      face,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: color, 
      ),
    );
  }
}
