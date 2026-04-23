import 'package:flutter/material.dart';

class AppleColors {
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F7);
  static const Color nearBlack = Color(0xFF1D1D1F);
  static const Color appleBlue = Color(0xFF0071E3);
  static const Color brightBlue = Color(0xFF0066CC);
}

class AppleTextStyles {
  static const TextStyle displayHero = TextStyle(
    color: AppleColors.nearBlack,
    fontSize: 42, // To hơn cho hầm hố
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1.07,
  );

  static const TextStyle body = TextStyle(
    color: AppleColors.nearBlack,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.374,
    height: 1.47,
  );
}
