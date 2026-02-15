import 'package:flutter/material.dart';

class HerCyclePalette {
  static const Color light = Color(0xFFF7EBFD); 
  static const Color blush = Color(0xFFDC93F6);
  static const Color magenta = Color(0xFFB333E9);
  static const Color deep = Color(0xFF3D0066);

  static const Gradient vibrantGradient = LinearGradient(
    colors: [light, blush, magenta, deep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient softGradient = LinearGradient(
    colors: [light, magenta],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static Color chessboardShadow = Colors.black.withOpacity(0.25);
}
