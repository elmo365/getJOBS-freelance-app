import 'package:flutter/material.dart';

// =========================================================
// BOTSJOBSCONNECT Brand Colors - Official Palette
// STRICTLY ENFORCED: Yellow, Green, Blue
// =========================================================

/// Primary Yellow - Brand Primary
const botsYellow = Color(0xFFEFC018);

/// Primary Green - Brand Secondary
const botsGreen = Color(0xFF0F6850);

/// Primary Blue - Brand Accent
const botsBlue = Color(0xFF4461AD);

/// White - Backgrounds / Text on Dark
const botsWhite = Color(0xFFFFFFFF);

/// Black - Text / Contrast
const botsBlack = Color(0xFF212121);

// =========================================================
// UI Semantic Colors (Mapped to Brand Palette)
// =========================================================

/// Backgrounds
const botsBackground =
    Color(0xFFF8F9FA); // Very light grey/white for modern feel
const botsSuperLightGrey = Color(
    0xFFF5F5F5); // Super light grey for card backgrounds to make white cards pop
const botsSurface = botsWhite;

/// Text
const botsTextPrimary = botsBlack;
const botsTextSecondary = Color(0xFF616161);
const botsTextHint = Color(0xFF9E9E9E);

/// Actions & States
const botsPrimaryAction = botsBlue;
const botsSecondaryAction = botsYellow;
const botsSuccess = botsGreen;
const botsError = Color(0xFFD32F2F); // Standard Material Error
const botsWarning = botsYellow;

/// Borders & Dividers
const botsDivider = Color(0xFFEEEEEE);
const botsBorder = Color(0xFFE0E0E0);

/// Shadows
const botsShadowColor = Color(0x1A000000); // 10% Black

// Legacy Compatibility (Aliases)
const red = botsError;
const white = botsWhite;
const black = botsBlack;
const grey = botsTextSecondary;
const brown = Colors.brown;
const yellow = botsYellow;

const botsLightGrey = botsBackground;
const botsDarkGrey = botsTextSecondary;
const botsNearlyWhite = botsBackground;
const botsSoftBackground = botsBackground;
const botsCardSurface = botsWhite;
const botsVividBlue = botsBlue;
const botsDeepBlue = botsBlue;
const botsAccentPurple = botsBlue; // Unified to brand
const botsAccentOrange = botsYellow; // Unified to brand
const botsAccentTeal = botsGreen; // Unified to brand
const botsSuccessGreen = botsGreen;
const botsErrorRed = botsError;
const botsWarningAmber = botsYellow;
