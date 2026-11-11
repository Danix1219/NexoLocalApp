import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/auth/session_controller.dart';
import '../../core/local/sync_controller.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/nexo_motion.dart';
import '../../core/widgets/nexo_navigation.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/toast.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../push/push_controller.dart';

/// Barra inferior de la maqueta (`.navbar`): Inicio · Buscar · Publicar ·
/// Mensajes · Cuenta. Igual para cliente y prestador.
class ShellPage extends ConsumerStatefulWidget {
  const ShellPage({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends ConsumerState<ShellPage> {
  Timer? _poll;
  bool _hideDemo = false;

  @override
  void initState() {
    super.initState();
    // Sin SignalR todavía: el globo de no leídos se actualiza cada 30 s.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || ref.read(sessionProvider).recoveryOnly) return;
      ref.invalidate(inboxProvider);
      ref.invalidate(notificationsProvider);
    });
    ref.read(syncProvider.notifier).notify = (m) {
      showNexoToast(m);
      if (mounted) refreshActivity(ref);
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskPush());
  }

  /// Pantalla previa al permiso de notificaciones (una vez por sesión).
  Future<void> _maybeAskPush() async {
    // Firebase tarda un instante en inicializar.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final push = ref.read(pushProvider.notifier);
    if (!await push.shouldAsk() || !mounted) return;
    await push.markAsked();
    if (!mounted) return;
    final yes = await showNexoSheet<bool>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeader('¿Te avisamos?',
              subtitle:
                  'Te mandamos un aviso cuando alguien se interese en lo que publicaste, acepten tu pedido o te escriban. '
                  'Los avisos no muestran tu dirección ni tu número.'),
          const SizedBox(height: 16),
          NexoButton(label: 'Activar avisos', icon: 'bell', onPressed: () => Navigator.of(ctx).pop(true)),
          const SizedBox(height: 8),
          NexoButton(
              label: 'Ahora no', variant: NexoButtonVariant.ghost, onPressed: () => Navigator.of(ctx).pop(false)),
        ],
      ),
    );
    if (yes == true) {
      final ok = await push.enable();
      showNexoToast(ok ? 'Avisos activados' : 'Puedes activarlos después en Cuenta.');
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final role = ref.watch(roleProvider);
    final unread = session.recoveryOnly ? 0 : ref.watch(inboxProvider(role)).asData?.value.$2 ?? 0;
    final demo = ref.watch(demoGroupsProvider);
    final sync = ref.watch(syncProvider);

    // Eventos simulados del "servidor" (modo de prueba): refrescar y avisar.
    ref.listen<ServerEvent>(serverEventsProvider, (_, e) {
      refreshActivity(ref);
      if (e.message != 'chat' && e.message.isNotEmpty) showNexoToast(e.message);
    });
    // El nombre no viene en el token: se toma de Cuenta.
    ref.listen<AsyncValue<AccountScreen?>>(accountProvider, (_, next) {
      final a = next.asData?.value;
      if (session.isSignedIn && a != null && a.name.isNotEmpty) {
        ref.read(sessionProvider.notifier).setName(a.name);
      }
    });

    final current = widget.shell.currentIndex;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: PopScope(
          canPop: current == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && current != 0) widget.shell.goBranch(0);
          },
          child: Scaffold(
            backgroundColor: NexoColors.bg,
            body: SafeArea(
              bottom: false,
              child: Column(children: [
                if (sync.offline || sync.pending > 0)
                  _OfflineBanner(sync: sync)
                else if (demo.isNotEmpty && !_hideDemo)
                  _DemoBanner(onClose: () => setState(() => _hideDemo = true)),
                Expanded(child: NexoEnter(trigger: current, child: widget.shell)),
              ]),
            ),
            bottomNavigationBar: NexoNavigation(
                current: current,
                unread: unread,
                onSelected: (i) => widget.shell.goBranch(i, initialLocation: i == current)),
          )),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NexoColors.accentSoft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
        child: Row(children: [
          const NexoIcon('info', size: 16, color: NexoColors.accentInk),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Algunas secciones muestran datos de ejemplo mientras se conectan.',
                style: NexoText.body(12.5, weight: FontWeight.w600, color: NexoColors.accentInk)),
          ),
          IconButton(
            tooltip: 'Ocultar aviso',
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: const NexoIcon('close', size: 16, color: NexoColors.accentInk),
          ),
        ]),
      ),
    );
  }
}

/// Sin señal: se muestra lo guardado en el teléfono (spec 051).
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.sync});
  final SyncState sync;

  @override
  Widget build(BuildContext context) {
    final t = sync.offlineSince;
    final hh = t == null ? '' : ' de las ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final parts = [
      if (sync.offline) 'Sin conexión. Ves lo guardado$hh.',
      if (sync.pending > 0)
        sync.pending == 1 ? '1 publicación por enviar.' : '${sync.pending} publicaciones por enviar.',
    ];
    return Semantics(
      liveRegion: true,
      child: Material(
        color: NexoColors.surface2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Row(children: [
            const NexoIcon('info', size: 16, color: NexoColors.ink),
            const SizedBox(width: 8),
            Expanded(
                child:
                    Text(parts.join(' '), style: NexoText.body(12.5, weight: FontWeight.w600, color: NexoColors.ink))),
          ]),
        ),
      ),
    );
  }
}
