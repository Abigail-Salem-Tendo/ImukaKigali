import 'package:flutter/material.dart';

/// Every size in the app lives here. Screens use these names, never raw numbers.
class AppSpacing {
  AppSpacing._();

  // Spacing scale (padding, margins, gaps)
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Corner radius
  static const double radiusInput = 12;
  static const double radiusCard = 16;
  static const double radiusButton = 12;
  static const double radiusSm = 8; // small things like chips

  // Cards
  static const double cardPadding = 16;
  static const double borderWidth = 1;

  // Component sizes
  static const double buttonHeight = 52;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 40;

  // Standard padding around a whole screen
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets cardInsets = EdgeInsets.all(cardPadding);
}
