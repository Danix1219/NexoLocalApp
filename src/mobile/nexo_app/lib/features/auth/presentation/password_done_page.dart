import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/nexo_button.dart';
import 'done_view.dart';

/// 7.2 vista `done`. El reset no devuelve sesión: se entra con la nueva.
class PasswordDonePage extends StatelessWidget {
  const PasswordDonePage({super.key, this.email});
  final String? email;

  @override
  Widget build(BuildContext context) {
    return DoneView(
      title: 'Contraseña actualizada',
      message:
          'Ya puedes iniciar sesión con tu contraseña nueva. Por seguridad, cerramos tus sesiones abiertas en otros dispositivos.',
      footer: [
        NexoButton(
          label: 'Iniciar sesión',
          onPressed: () => context.go(Routes.login, extra: email),
        ),
      ],
    );
  }
}
