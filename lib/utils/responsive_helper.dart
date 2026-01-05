import 'package:flutter/material.dart';

class ResponsiveHelper {
  /// Get responsive grid columns based on screen width
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 768) {
      // Small phones, phones and tablets in portrait
      return 2;
    } else if (width < 1024) {
      // Tablets in landscape
      return 3;
    } else {
      // Desktop and large tablets
      return 4;
    }
  }

  /// Get responsive padding based on screen width
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 480) {
      return const EdgeInsets.all(12);
    } else if (width < 768) {
      return const EdgeInsets.all(16);
    } else if (width < 1024) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  /// Get responsive horizontal padding
  static double getResponsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 480) {
      return 12;
    } else if (width < 768) {
      return 16;
    } else if (width < 1024) {
      return 20;
    } else {
      return 24;
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context,
    double baseSize, {
    double minSize = 12,
    double maxSize = 32,
  }) {
    final width = MediaQuery.of(context).size.width;
    final scaleFactor = width / 360; // Base scale on 360 width (small phone)
    final size = baseSize * scaleFactor;

    return size.clamp(minSize, maxSize);
  }

  /// Check if device is in portrait
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  /// Check if device is desktop/large
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Get child aspect ratio for grid based on screen width
  static double getChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 480) {
      return 0.65;
    } else if (width < 768) {
      return 0.75;
    } else {
      return 0.8;
    }
  }

  /// Get spacing based on screen width
  static double getResponsiveSpacing(
    BuildContext context, {
    double small = 8,
    double medium = 12,
    double large = 16,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width < 480) {
      return small;
    } else if (width < 768) {
      return medium;
    } else {
      return large;
    }
  }
}
