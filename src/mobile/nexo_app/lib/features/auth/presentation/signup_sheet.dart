import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/widgets/nexo_button.dart';
import '../../../core/widgets/nexo_sheet.dart';
import '../application/email_flow.dart';

/// `signupSheet()`: "¿Qué quieres hacer primero?".
Future<void> showSignupSheet(BuildContext context) {
  final router = GoRouter.of(context);
  final container = ProviderScope.containerOf(context);

  void start(BuildContext sheetCtx, String intent) {
    Navigator.of(sheetCtx).pop();
    container.read(signupFlowProvider.notifier).setIntent(intent);
    router.push(Routes.registerEmail);
  }

  return showNexoSheet<void>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader(
          '¿Qué quieres hacer primero?',
          subtitle:
              'Elige según lo que necesitas ahora. También puedes seguir explorando sin registrarte.',
        ),
        const OneNote(
          icon: 'user',
          text: 'Con una sola cuenta podrás buscar y ofrecer servicios cuando quieras.',
        ),
        const SizedBox(height: 14),
        ChoiceCard(
          icon: 'search',
          title: 'Quiero buscar servicios',
          subtitle:
              'Crea tu cuenta y empieza a explorar: guarda, compara y publica lo que necesitas.',
          onTap: () => start(ctx, 'client'),
        ),
        const SizedBox(height: 8),
        ChoiceCard(
          icon: 'hammer',
          title: 'Quiero ofrecer servicios',
          subtitle:
              'Crea tu cuenta y arma tu perfil: servicios, zona de cobertura y fotos de trabajos.',
          onTap: () => start(ctx, 'provider'),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('¿Ya tienes cuenta?',
                style: NexoText.body(12.5, color: NexoColors.muted)),
            NexoLink('Inicia sesión', onTap: () {
              Navigator.of(ctx).pop();
              router.push(Routes.login);
            }),
          ],
        ),
      ],
    ),
  );
}
