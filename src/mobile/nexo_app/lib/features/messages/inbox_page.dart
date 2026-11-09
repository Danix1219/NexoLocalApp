import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/auth/session_controller.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../shell/gate.dart';

/// 7.16 Mensajes — bandeja (`V.inbox`).
class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  bool _unread = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    if (s.isGuest) {
      return const GateScreen(
          title: 'Mensajes',
          icon: 'chat',
          text: 'Con una cuenta puedes escribirle a los prestadores y acordar todo en un chat.');
    }
    final role = ref.watch(roleProvider);
    if (s.isProviderMode &&
        ref.watch(myProviderProvider).asData?.value == null &&
        ref.watch(myProviderProvider).hasValue) {
      return const NoProviderProfile(title: 'Mensajes');
    }
    final v = ref.watch(inboxProvider(role));
    return RefreshIndicator(
      color: NexoColors.brand,
      onRefresh: () async => ref.invalidate(inboxProvider(role)),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const ScreenTitleBar('Mensajes'),
          asyncView(v, (d) {
            final all = d.$1;
            final unread = all.where((c) => c.unread > 0 && !c.blocked).toList();
            if (all.isEmpty) {
              return EmptyState(
                icon: 'chat',
                title: 'Aún no tienes mensajes',
                text: s.isProviderMode
                    ? 'Cuando un cliente te escriba por una solicitud o desde tu perfil, la conversación aparecerá aquí.'
                    : 'Escríbele a un prestador desde su perfil o desde los interesados en tu solicitud.',
                action: s.isProviderMode ? 'Ver solicitudes' : 'Buscar un servicio',
                onAction: () => context.go(s.isProviderMode ? Routes.home : Routes.search),
              );
            }
            final list = _unread ? unread : all;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(children: [
                    ToggleChip(label: 'Todos', selected: !_unread, onTap: () => setState(() => _unread = false)),
                    const SizedBox(width: 8),
                    ToggleChip(
                        label: unread.isEmpty ? 'Sin leer' : 'Sin leer · ${unread.length}',
                        selected: _unread,
                        onTap: () => setState(() => _unread = true)),
                  ]),
                ),
                if (list.isEmpty)
                  const EmptyState(icon: 'check', title: 'Estás al día', text: 'No tienes mensajes sin leer.'),
                for (final c in list) _InboxRow(c: c),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const NexoIcon('shield', size: 15, color: NexoColors.muted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('Tus conversaciones son privadas. Tu número no se muestra.',
                          style: NexoText.body(12.5, color: NexoColors.muted)),
                    ),
                  ]),
                ),
              ],
            );
          }, onRetry: () => ref.invalidate(inboxProvider(role))),
        ],
      ),
    );
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({required this.c});
  final Conversation c;

  @override
  Widget build(BuildContext context) {
    final isNew = c.unread > 0 && !c.blocked;
    final o = c.activeOrder;
    return Material(
      color: isNew ? NexoColors.brandSoft.withValues(alpha: .45) : NexoColors.surface,
      child: InkWell(
        onTap: () => context.push(Routes.chat(c.id)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: NexoColors.line))),
          child: Row(
            children: [
              NexoAvatar(name: c.counterpart.displayName, url: c.counterpart.photoUrl, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(c.counterpart.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: NexoText.body(15, weight: isNew ? FontWeight.w800 : FontWeight.w700)),
                      ),
                      Text(c.ago, style: NexoText.body(12, color: isNew ? NexoColors.brand : NexoColors.muted)),
                    ]),
                    if (o != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(o.statusText.isEmpty ? 'Pedido' : 'Pedido · ${o.statusText}',
                            style: NexoText.body(12, weight: FontWeight.w700, color: NexoColors.accentInk)),
                      ),
                    const SizedBox(height: 2),
                    Row(children: [
                      Expanded(
                        child: Text(
                          c.blocked ? 'Bloqueado' : c.lastPreview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NexoText.body(13.5,
                              weight: isNew ? FontWeight.w700 : FontWeight.w400,
                              color: isNew ? NexoColors.ink : NexoColors.muted),
                        ),
                      ),
                      if (isNew)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(color: NexoColors.brand, borderRadius: BorderRadius.circular(99)),
                          child: Center(
                            child: Text('${c.unread}',
                                style: NexoText.body(11.5, weight: FontWeight.w800, color: Colors.white, height: 1)),
                          ),
                        ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
