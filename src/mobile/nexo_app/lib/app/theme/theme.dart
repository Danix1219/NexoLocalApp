import 'package:flutter/material.dart';

import 'tokens.dart';
import '../../core/widgets/nexo_motion.dart';

ThemeData buildNexoTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'NunitoSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: NexoColors.brand,
      primary: NexoColors.brand,
      surface: NexoColors.surface,
      error: NexoColors.danger,
    ),
    scaffoldBackgroundColor: NexoColors.surface,
  );
  return base.copyWith(
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: NexoPageTransitions(),
      TargetPlatform.iOS: NexoPageTransitions(),
      TargetPlatform.windows: NexoPageTransitions(),
      TargetPlatform.macOS: NexoPageTransitions(),
      TargetPlatform.linux: NexoPageTransitions(),
      TargetPlatform.fuchsia: NexoPageTransitions(),
    }),
    textTheme: base.textTheme.apply(bodyColor: NexoColors.ink, displayColor: NexoColors.ink),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: NexoColors.brand,
      selectionHandleColor: NexoColors.brand,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: NexoColors.brand),
  );
}
