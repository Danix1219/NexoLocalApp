import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/env.dart';
import '../../../app/router.dart';
import '../../../core/widgets/nexo_button.dart';
import '../../../core/widgets/nexo_sheet.dart';
import '../application/email_flow.dart';
import 'done_view.dart';

/// Éxito del registro (`obDone`, flujo req).
class RegisterDonePage extends ConsumerWidget {
  const RegisterDonePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(signupFlowProvider);
    final first = (flow.createdName ?? '').trim().split(RegExp(r'\s+')).first;
    final provider = flow.nextStep == 'createProvider' || flow.intent == 'provider';
    return DoneView(
      title: first.isEmpty ? 'Tu cuenta está lista' : 'Listo, $first. Tu cuenta está lista',
      message: provider
          ? 'Tu cuenta ya existe. El siguiente paso es armar tu perfil profesional para que te encuentren.'
          : 'Ya puedes buscar prestadores en ${Env.defaultZone}, guardarlos, recomendarlos y publicar lo que necesitas.',
      extra: [
        CheckList(items: [
          (true, 'Correo confirmado'),
          (true, 'Zona: ${Env.defaultZone}'),
          if (provider)
            (false, 'Perfil profesional: servicios, zona y horario')
          else
            (false, 'Intereses: elígelos en Cuenta para ver primero lo que te importa'),
        ]),
        OneNote(
          icon: provider ? 'search' : 'hammer',
          text: provider
              ? 'Con esta misma cuenta puedes cambiar a Modo Cliente para buscar servicios cuando lo necesites.'
              : '¿También ofreces servicios? Cambia a Modo Proveedor desde Cuenta y crea tu perfil con esta misma cuenta.',
        ),
      ],
      footer: [
        NexoButton(
          label: provider ? 'Armar mi perfil profesional' : 'Empezar a explorar',
          onPressed: () {
            ref.read(signupFlowProvider.notifier).reset();
            context.go(Routes.home);
            if (provider) context.push(Routes.proOnboarding);
          },
        ),
      ],
    );
  }
}
