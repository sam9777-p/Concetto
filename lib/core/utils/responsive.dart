import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Responsive sizing utility that scales UI elements uniformly
/// across all screen sizes and pixel densities.
///
/// Design baseline: 390px width (iPhone 14 / typical modern Android)
/// All hardcoded dp values in the app were designed for this baseline.
class Responsive {
  static double _screenWidth = 390;
  static double _screenHeight = 844;
  static double _scaleFactor = 1.0;
  static double _textScaleFactor = 1.0;
  static bool _initialized = false;

  /// Initialize responsive scaling from the given context.
  /// Call this once from the top-level widget (e.g., MyApp.build).
  static void init(BuildContext context) {
    final mq = MediaQuery.of(context);
    _screenWidth = mq.size.width;
    _screenHeight = mq.size.height;

    // Scale based on width relative to design baseline (390dp)
    // Clamp between 0.78 and 1.2 to avoid extreme scaling
    _scaleFactor = (_screenWidth / 390).clamp(0.78, 1.2);

    // Text scale: gentler scaling to prevent text from becoming too small
    // on narrow screens or too large on wide screens
    _textScaleFactor = (_screenWidth / 390).clamp(0.82, 1.15);

    _initialized = true;
  }

  /// Whether the responsive system has been initialized
  static bool get isInitialized => _initialized;

  /// Current screen width in logical pixels
  static double get screenWidth => _screenWidth;

  /// Current screen height in logical pixels
  static double get screenHeight => _screenHeight;

  /// General scale factor for dimensions (padding, icon sizes, etc.)
  static double get scaleFactor => _scaleFactor;

  /// Text-specific scale factor (gentler than general scaling)
  static double get textScaleFactor => _textScaleFactor;

  /// Scale a dimension value (padding, margin, icon size, border radius, etc.)
  static double scale(double value) => value * _scaleFactor;

  /// Scale a font size value (gentler scaling to preserve readability)
  static double sp(double fontSize) => fontSize * _textScaleFactor;

  /// Scale padding/margin symmetrically
  static EdgeInsets padding({
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: horizontal * _scaleFactor,
      vertical: vertical * _scaleFactor,
    );
  }

  /// Scale padding with all sides
  static EdgeInsets paddingAll(double value) {
    return EdgeInsets.all(value * _scaleFactor);
  }

  /// Returns a clamped TextScaler for use in MediaQuery override.
  /// This prevents the system-level font scale from compounding
  /// with our own scaling and causing overflow.
  static TextScaler clampedTextScaler(BuildContext context) {
    final systemScale = MediaQuery.textScalerOf(context).scale(1.0);
    // Clamp the final effective scale so that very large system
    // accessibility settings don't break the layout
    final clamped = systemScale.clamp(0.85, 1.15);
    return TextScaler.linear(clamped);
  }

  /// Whether the current screen is considered "small" (< 360dp wide)
  static bool get isSmallScreen => _screenWidth < 360;

  /// Whether the current screen is considered "large" (>= 410dp wide)
  static bool get isLargeScreen => _screenWidth >= 410;

  /// Minimum of screen width fraction and absolute max
  static double widthPercent(double percent, {double max = double.infinity}) {
    return math.min(_screenWidth * percent, max);
  }

  /// Minimum of screen height fraction and absolute max
  static double heightPercent(double percent, {double max = double.infinity}) {
    return math.min(_screenHeight * percent, max);
  }
}
