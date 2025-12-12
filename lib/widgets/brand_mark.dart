import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({this.size = 48, super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/phi_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
