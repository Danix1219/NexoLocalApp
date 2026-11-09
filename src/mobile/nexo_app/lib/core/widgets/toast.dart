import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// Messenger global: los avisos sobreviven a los cambios de pantalla.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Aviso breve de la maqueta (`toast`, 2.6 s, fondo tinta).
void showNexoToast(String message) {
  final m = rootMessengerKey.currentState;
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: NexoText.body(14, weight: FontWeight.w600, color: NexoColors.bg),
      ),
      backgroundColor: NexoColors.ink,
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(milliseconds: 2600),
    ),
  );
}
