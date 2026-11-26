import 'chat_experience.dart';
import 'dart:async';
import 'chat_live.dart';
import '../push/chat_notifications.dart';
import '../../core/network/api_client.dart';
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
  String _query = '';
  final _search = TextEditingController();

  Timer? _receiptsTimer;
  ChatLive? _receiptsLive;
  bool _receiving = false;
  final Map<String, String> _delivered = {};
  final Map<String, String> _previews = {};
  @override
  void initState() {
    super.initState();
    _receiptsTimer = Timer.periodic(const Duration(seconds: 5), (_) => _receive());
    _receiptsLive = ChatLive(ref.read(dioProvider), (id) {
      _previews.remove(id);
      _receive();
    })..start();
    Future.microtask(_receive);
  }

  Future<void> _receive() async {
    if (_receiving ||
        !mounted ||
        !ref.read(sessionProvider).isSignedIn ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      return;
    }
    _receiving = true;
    final account = ref.read(sessionProvider).accountId;
    try {
      final api = ref.read(apiProvider);
      final (conversations, _) = await api.conversations(role: ref.read(roleProvider));
      if (!mounted || ref.read(sessionProvider).accountId != account) return;
      for (final conversation
          in conversations.where((c) => !c.blocked && (c.unread > 0 || !_previews.containsKey(c.id))).take(20)) {
        final thread = await api.messages(conversation.id);
        if (mounted && ref.read(sessionProvider).accountId == account) {
          ref.read(chatExperienceProvider).remember(thread);
        }
        if (!mounted || ref.read(sessionProvider).accountId != account) return;
        unawaited(
          ChatNotifications.prepareShortcut(
            account!,
            conversation.id,
            thread.counterpart.displayName,
            thread.counterpart.photoUrl,
          ),
        );
        final newest = thread.messages.where((m) => m.kind != 'system').lastOrNull;
        if (newest != null) {
          _previews[conversation.id] = ChatNotifications.preview(newest.kind, newest.text);
        }
        final last = thread.messages.where((m) => !m.mine && m.kind != 'system').lastOrNull;
        if (last != null && _delivered[conversation.id] != last.id) {
          await api.markDelivered(conversation.id, last.id);
          _delivered[conversation.id] = last.id;
        }
      }
      if (mounted) setState(() {});
      ref.invalidate(inboxProvider);
    } catch (_) {
      /* No false delivery or read receipts on failure. */
    } finally {
      _receiving = false;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _receiptsTimer?.cancel();
    unawaited(_receiptsLive?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionProvider.select((s) => s.accountId), (previous, next) {
      if (previous != next) {
        _previews.clear();
        _delivered.clear();
      }
    });
    final s = ref.watch(sessionProvider);
    if (s.isGuest) {
      return const GateScreen(
        title: 'Mensajes',
        icon: 'chat',
        text: 'Con una cuenta puedes escribirle a los prestadores y acordar todo en un chat.',
      );
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
      child: PinnedHeaderList(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const ScreenTitleBar('Mensajes'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar una conversaci\u00f3n',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar b\u00fasqueda',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: NexoColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: _searchBorder(NexoColors.line),
                enabledBorder: _searchBorder(NexoColors.line),
                focusedBorder: _searchBorder(NexoColors.brand),
              ),
            ),
          ),
          skeletonView(NexoSkeletonKind.messages, v, (d) {
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
            final list = (_unread ? unread : all)
                .where((c) => _query.isEmpty || c.counterpart.displayName.toLowerCase().contains(_query))
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    children: [
                      ToggleChip(label: 'Todos', selected: !_unread, onTap: () => setState(() => _unread = false)),
                      const SizedBox(width: 8),
                      ToggleChip(
                        label: unread.isEmpty ? 'Sin leer' : 'Sin leer · ${unread.length}',
                        selected: _unread,
                        onTap: () => setState(() => _unread = true),
                      ),
                    ],
                  ),
                ),
                if (list.isEmpty)
                  _query.isNotEmpty
                      ? const EmptyState(
                          icon: 'chat',
                          title: 'Sin resultados',
                          text: 'No encontramos conversaciones con ese nombre.',
                        )
                      : const EmptyState(icon: 'check', title: 'Estás al día', text: 'No tienes mensajes sin leer.'),
                for (final c in list) _InboxRow(c: c, preview: _previews[c.id]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const NexoIcon('shield', size: 15, color: NexoColors.muted),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Tus conversaciones son privadas. Tu número no se muestra.',
                          style: NexoText.body(12.5, color: NexoColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }, onRetry: () => ref.invalidate(inboxProvider(role))),
        ],
      ),
    );
  }
}

OutlineInputBorder _searchBorder(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(18),
  borderSide: BorderSide(color: color),
);

class _InboxRow extends ConsumerWidget {
  const _InboxRow({required this.c, this.preview});
  final Conversation c;
  final String? preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNew = c.unread > 0 && !c.blocked;
    final o = c.activeOrder;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Material(
        color: isNew
            ? Color.alphaBlend(NexoColors.brandSoft.withValues(alpha: .55), NexoColors.surface)
            : NexoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isNew ? NexoColors.brand.withValues(alpha: .35) : NexoColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            ref.read(chatExperienceProvider).seed(c.id, c.counterpart);
            context.push(Routes.chat(c.id));
          },
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                NexoAvatar(name: c.counterpart.displayName, url: c.counterpart.photoUrl, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.counterpart.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: NexoText.body(15.5, weight: isNew ? FontWeight.w800 : FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Sin flex: la hora mide lo que su texto y queda pegada al borde derecho.
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 110),
                            child: Text(
                              c.ago,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: NexoText.body(
                                12,
                                weight: isNew ? FontWeight.w800 : FontWeight.w500,
                                color: isNew ? NexoColors.brand : NexoColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (c.blocked) ...[
                            const Icon(Icons.block_rounded, size: 14, color: NexoColors.muted),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              c.blocked ? 'Bloqueado' : (preview ?? c.lastPreview),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: NexoText.body(
                                13.5,
                                weight: isNew ? FontWeight.w700 : FontWeight.w400,
                                color: isNew ? NexoColors.ink : NexoColors.muted,
                              ),
                            ),
                          ),
                          if (isNew)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: NexoColors.brand,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Center(
                                widthFactor: 1,
                                heightFactor: 1,
                                child: Text(
                                  c.unread > 99 ? '99+' : '${c.unread}',
                                  style: NexoText.body(12, weight: FontWeight.w800, color: Colors.white, height: 1),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (o != null)
                        Container(
                          margin: const EdgeInsets.only(top: 7),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: NexoColors.accentSoft,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            o.statusText.isEmpty ? 'Pedido' : 'Pedido · ${o.statusText}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: NexoText.body(11.5, weight: FontWeight.w800, color: NexoColors.accentInk),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
