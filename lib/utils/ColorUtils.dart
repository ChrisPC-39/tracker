import 'package:flutter/material.dart';

class ColorUtils {
  static double calculateContrast(Color color1, Color color2) {
    // Calculate luminance for both colors
    final luminance1 = 0.2126 * color1.red + 0.7152 * color1.green + 0.0722 * color1.blue;
    final luminance2 = 0.2126 * color2.red + 0.7152 * color2.green + 0.0722 * color2.blue;

    // Calculate contrast ratio
    final contrastRatio = (luminance1 + 0.05) / (luminance2 + 0.05);

    return contrastRatio;
  }

  // Function to determine icon color based on background
  static Color getIconColor(Color backgroundColor) {
    final contrastRatio = calculateContrast(backgroundColor, Colors.white);
    if (contrastRatio >= 4.5) {
      // High contrast, use black icon
      return Colors.black;
    } else {
      // Low contrast, use white icon
      return Colors.white;
    }
  }
}