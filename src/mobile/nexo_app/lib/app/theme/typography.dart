import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Tipografías de la maqueta: Plus Jakarta Sans (títulos) y Nunito Sans (texto).
class NexoText {
  NexoText._();

  /// Títulos. Por defecto usa el tracking de la maqueta (-0.02em).
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w800,
    Color color = NexoColors.ink,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing ?? -0.02 * size,
      );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = NexoColors.ink,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.nunitoSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}
