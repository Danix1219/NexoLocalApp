import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

ThemeData buildNexoTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: NexoColors.brand,
      primary: NexoColors.brand,
      surface: NexoColors.surface,
      error: NexoColors.danger,
    ),
    scaffoldBackgroundColor: NexoColors.surface,
  );
  return base.copyWith(
    textTheme:
        GoogleFonts.nunitoSansTextTheme(base.textTheme).apply(bodyColor: NexoColors.ink, displayColor: NexoColors.ink),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: NexoColors.brand,
      selectionHandleColor: NexoColors.brand,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: NexoColors.brand),
  );
}
