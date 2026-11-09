import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/auth/session_controller.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/nexo_logo.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../location/location_picker_page.dart';
import 'gate.dart';

/// Chip de ubicación (`.chip.locchip`).
class LocationChip extends ConsumerWidget {
  const LocationChip({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(searchLocationProvider);
    final text = label ?? loc.zoneLabel;
    return Semantics(
      button: true,
      label: 'Ubicación: $text. Cambiar',
      child: Material(
        color: NexoColors.brandSoft,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => openSearchLocation(context, ref),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const NexoIcon('pin', size: 16, color: NexoColors.brandDeep),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Text(text,
                        overflow: TextOverflow.ellipsis,
                        style: NexoText.body(12.5, weight: FontWeight.w600, color: NexoColors.brandDeep)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `zoneSheet` del solicitante: ¿dónde buscas el servicio?
Future<void> openSearchLocation(BuildContext context, WidgetRef ref) async {
  final loc = ref.read(searchLocationProvider);
  final r = await context.push<LocationPick>(
    Routes.location,
    extra: LocationPickerArgs(
      title: '¿Dónde buscas el servicio?',
      subtitle: 'Cámbiala cuando busques para otro lugar, como la casa de un familiar o tu negocio.',
      initial: loc.point,
      radiusKm: loc.radiusKm,
      button: 'Buscar aquí',
    ),
  );
  if (r == null) return;
  try {
    await ref.read(searchLocationProvider.notifier).set(r.point, r.radiusKm, source: r.source);
    showNexoToast('Resultados adaptados a ${ref.read(searchLocationProvider).zoneLabel}');
  } catch (e) {
    showNexoToast(apiErrorMessage(e));
  }
}

/// Barra superior de Inicio (`topHome`): logo, ubicación y campana.
class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key, this.zoneLabel, this.dot = false});
  final String? zoneLabel;
  final bool dot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider).asData?.value.$2 ?? 0;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: NexoColors.surface,
        border: Border(bottom: BorderSide(color: NexoColors.line)),
      ),
      child: Row(
        children: [
          const NexoLogo(),
          const Spacer(),
          LocationChip(label: zoneLabel),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              NexoIconButtonPlain(icon: 'bell', label: 'Notificaciones', onTap: () => showNotifications(context, ref)),
              if (unread > 0 || dot)
                Positioned(
                  right: 9,
                  top: 9,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: NexoColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: NexoColors.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `.iconbtn` 44×44.
class NexoIconButtonPlain extends StatelessWidget {
  const NexoIconButtonPlain({super.key, required this.icon, required this.label, required this.onTap});
  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: NexoColors.surface2,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(width: 44, height: 44, child: Center(child: NexoIcon(icon, size: 20))),
          ),
        ),
      );
}

/// `notifSheet`: centro de notificaciones.
Future<void> showNotifications(BuildContext context, WidgetRef ref) async {
  if (!ref.read(sessionProvider).isSignedIn) {
    requireAccount(context, ref, why: 'Con una cuenta te avisamos cuando alguien se interese o responda.');
    return;
  }
  final router = GoRouter.of(context);
  await showNexoSheet<void>(context, builder: (ctx) => _NotifList(onOpen: (link) {
        Navigator.of(ctx).pop();
        final path = Routes.fromDeepLink(link);
        if (path != null) router.push(path);
      }));
  // Al cerrar, todo queda leído.
  final list = ref.read(notificationsProvider).asData?.value.$1 ?? const <NotificationItem>[];
  final ids = [for (final n in list) if (!n.read) n.id];
  if (ids.isNotEmpty) {
    try {
      await ref.read(apiProvider).markNotificationsRead(ids);
    } catch (_) {}
    ref.invalidate(notificationsProvider);
  }
}

class _NotifList extends ConsumerWidget {
  const _NotifList({required this.onOpen});
  final ValueChanged<String?> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(notificationsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Notificaciones'),
        asyncView(v, (d) {
          if (d.$1.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('No tienes avisos por ahora.',
                  textAlign: TextAlign.center, style: NexoText.body(14, color: NexoColors.muted)),
            );
          }
          return Column(
            children: [
              for (final n in d.$1)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: n.deepLink == null ? null : () => onOpen(n.deepLink),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: n.read ? NexoColors.surface2 : NexoColors.brandSoft,
                              borderRadius: BorderRadius.circular(12)),
                          child: Center(
                              child: NexoIcon(n.icon, size: 19, color: n.read ? NexoColors.muted : NexoColors.brand)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: NexoText.body(14.5, weight: n.read ? FontWeight.w600 : FontWeight.w800)),
                              if (n.body.isNotEmpty)
                                Text(n.body, style: NexoText.body(13, color: NexoColors.muted, height: 1.35)),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(n.ago, style: NexoText.body(12, color: NexoColors.muted)),
                                  if (n.actionLabel != null) ...[
                                    const SizedBox(width: 10),
                                    Text(n.actionLabel!,
                                        style: NexoText.body(12.5, weight: FontWeight.w800, color: NexoColors.brand)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!n.read)
                          Container(
                            margin: const EdgeInsets.only(top: 6, left: 6),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: NexoColors.accent, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }, loadingPad: 24),
      ],
    );
  }
}
