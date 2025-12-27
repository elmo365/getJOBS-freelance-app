// ignore_for_file: deprecated_member_use, camel_case_types

import 'package:flutter/material.dart';
import 'package:freelance_app/utils/colors.dart';

class clr {
  static const Color primary = botsGreen;
  static const Color lightPrimary = botsBlue;
  static const Color secondary = botsYellow;
  static const Color lightSecondary = botsYellow;
  static final Color accent = _lighten(botsYellow, 40);

  static const Color light = Colors.white;
  // Avoid greys; use a muted brand tone for passive UI.
  static const Color passive = Color(0x4D0F6850);
  static final Color passiveLight = _lighten(passive, 60);
  static const Color dark = botsBlack;

  static final Color backgroundGradient1 = _lighten(botsWhite, 0);
  static final Color backgroundGradient2 = _lighten(botsWhite, 0);

  static const Color bottomNavBarIcon = botsBlack;

  static final Color card = botsWhite;

  static final Color error = _darken(Colors.red, 20);
}

// ignore: unused_element
Color _hexToColor(String code) {
  return Color(int.parse(code.substring(0, 6), radix: 16) + 0xFF000000);
}

Color _lighten(Color baseColor, int percent) {
  var p = percent / 100;
  final alpha = (baseColor.a * 255.0).round().clamp(0, 255);
  final red = (baseColor.r * 255.0).round().clamp(0, 255);
  final green = (baseColor.g * 255.0).round().clamp(0, 255);
  final blue = (baseColor.b * 255.0).round().clamp(0, 255);
  return Color.fromARGB(
      alpha,
      red + ((255 - red) * p).round(),
      green + ((255 - green) * p).round(),
      blue + ((255 - blue) * p).round());
}

Color _darken(Color baseColor, int percent) {
  var f = 1 - percent / 100;
  final alpha = (baseColor.a * 255.0).round().clamp(0, 255);
  final red = (baseColor.r * 255.0).round().clamp(0, 255);
  final green = (baseColor.g * 255.0).round().clamp(0, 255);
  final blue = (baseColor.b * 255.0).round().clamp(0, 255);
  return Color.fromARGB(alpha, (red * f).round(),
      (green * f).round(), (blue * f).round());
}
