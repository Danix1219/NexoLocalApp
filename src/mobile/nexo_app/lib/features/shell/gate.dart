import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/auth/session_controller.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';

/// `gateSheet`: para contactar, guardar, comparar o publicar hace falta
/// una cuenta. Devuelve true si ya hay sesión.
bool requireAccount(BuildContext context, WidgetRef ref, {String? why}) {
  if (ref.read(sessionProvider).isSignedIn) return true;
  final router = GoRouter.of(context);
  showNexoSheet<void>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader('Crea tu cuenta para continuar',
            subtitle: why ?? 'Es gratis. Con una cuenta puedes contactar, comparar, guardar y publicar lo que necesitas.'),
        const OneNote(icon: 'shield', text: 'Tu número no se comparte. Acuerdas todo por chat dentro de Nexo.'),
        const SizedBox(height: 14),
        NexoButton(
          label: 'Crear cuenta gratis',
          onPressed: () {
            Navigator.of(ctx).pop();
            ref.read(sessionProvider.notifier).leaveGuest();
            router.go(Routes.registerEmail);
          },
        ),
        const SizedBox(height: 8),
        NexoButton(
          label: 'Ya tengo cuenta · Iniciar sesión',
          variant: NexoButtonVariant.line,
          onPressed: () {
            Navigator.of(ctx).pop();
            ref.read(sessionProvider.notifier).leaveGuest();
            router.go(Routes.login);
          },
        ),
      ],
    ),
  );
  return false;
}

/// Pantalla completa para el visitante (`gateScreen`).
class GateScreen extends ConsumerWidget {
  const GateScreen({super.key, required this.title, required this.text, this.icon = 'user'});
  final String title;
  final String text;
  final String icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ScreenTitleBar(title),
        EmptyState(
          icon: icon,
          title: 'Necesitas una cuenta',
          text: text,
          action: 'Crear cuenta gratis',
          onAction: () {
            ref.read(sessionProvider.notifier).leaveGuest();
            context.go(Routes.registerEmail);
          },
          secondary: 'Iniciar sesión',
          onSecondary: () {
            ref.read(sessionProvider.notifier).leaveGuest();
            context.go(Routes.login);
          },
        ),
      ],
    );
  }
}

/// `noProScreen`: en modo prestador sin perfil.
class NoProviderProfile extends StatelessWidget {
  const NoProviderProfile({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ScreenTitleBar(title),
        EmptyState(
          icon: 'hammer',
          title: 'Crea tu perfil para ver oportunidades',
          text: 'Con tu perfil verás las solicitudes de personas que buscan justo lo que ofreces en tu zona.',
          action: 'Crear mi perfil',
          onAction: () => context.push(Routes.proOnboarding),
        ),
      ],
    );
  }
}

/// Lleva a un deep link de notificación o push.
void openDeepLink(BuildContext context, String? link) {
  final path = Routes.fromDeepLink(link);
  if (path != null) context.push(path);
}

/// Atajo para refrescar tras una acción.
void afterChange(WidgetRef ref) => refreshActivity(ref);
