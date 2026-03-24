import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/character_provider.dart';

class CharacterSprite extends StatelessWidget {
  final double width;
  final double height;
  final BoxFit fit;

  const CharacterSprite({
    super.key,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final characterProvider = Provider.of<CharacterProvider>(context);

    return SvgPicture.asset(
      characterProvider.currentCharacterAsset,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
