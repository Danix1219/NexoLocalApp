import 'chat_message_actions.dart';
import 'package:flutter/semantics.dart';
import 'chat_backdrop.dart';
import '../../core/auth/token_storage.dart';
import 'chat_experience.dart';
import '../push/chat_notifications.dart';
import 'message_receipt.dart';
import 'private_chat_media.dart';
import 'voice_composer.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/auth/session_controller.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/pick_image.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/nexo_motion.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../../data/nexo_api.dart';
import '../common/actions.dart';
import '../../core/network/api_client.dart';
import 'chat_live.dart';

/// 7.16 Chat a pantalla completa (`V.chat`). Mientras no hay SignalR, se
/// consulta el historial cada 4 s.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _messageFocus = FocusNode();
  Message? _editingMessage;
  String _draftBeforeEdit = '';
  bool _savingEdit = false;

  void _cancelEdit() {
    if (_savingEdit) return;
    setState(() {
      _editingMessage = null;
      _text.text = _draftBeforeEdit;
      _text.selection = TextSelection.collapsed(offset: _text.text.length);
    });
  }

  Future<void> _saveEdit() async {
    final message = _editingMessage;
    final replacement = _text.text.trim();
    if (message == null ||
        _savingEdit ||
        replacement.isEmpty ||
        replacement == message.text ||
        replacement.length > 1000) {
      return;
    }
    setState(() => _savingEdit = true);
    try {
      await ref.read(apiProvider).editMessage(widget.id, message.id, replacement);
      if (!mounted) return;
      _mutationRevision++;
      _experience.confirmMutation(widget.id, message.id, text: replacement);
      setState(() {
        _editingMessage = null;
        _text.text = _draftBeforeEdit;
      });
      ref.invalidate(inboxProvider);
      unawaited(_load(silent: true));
    } catch (error) {
      showNexoToast(apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _savingEdit = false);
    }
  }

  final _scroll = ScrollController();
  ChatThread? _t;
  Object? _error;
  Timer? _poll;
  ChatLive? _live;
  bool _sending = false;
  ChatStyle _style = const ChatStyle();
  bool _awayFromLatest = false;
  final Set<String> _mutating = {};
  String? _lastRead;
  bool _loading = false;
  bool _positioned = false;
  int _mutationRevision = 0;
  bool _reloadPending = false;
  bool _autoEnabling = false;
  late final ChatExperience _experience;
  int _localCount = 0;
  late final bool Function(String) _viewing;
  bool _visible(String id) =>
      mounted &&
      id == widget.id &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) &&
      ModalRoute.of(context)?.isCurrent == true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_load(silent: true));
  }

  void _scrollChanged() {
    final away = _scroll.hasClients && _scroll.position.pixels > 320;
    if (away != _awayFromLatest) setState(() => _awayFromLatest = away);
    if (_scroll.hasClients && _scroll.position.pixels < 40 && !_loading) {
      unawaited(_load(silent: true));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewing = _visible;
    ChatNotifications.isViewing = _viewing;
    _scroll.addListener(_scrollChanged);
    unawaited(ChatNotifications.dismiss(widget.id).catchError((Object _) {}));
    _experience = ref.read(chatExperienceProvider);
    _t = _experience.thread(widget.id);
    _experience.addListener(_experienceChanged);
    unawaited(_experience.restore(widget.id));
    final account = ref.read(sessionProvider).accountId;
    if (account != null) {
      unawaited(
        ref
            .read(tokenStorageProvider)
            .readChatStyle(account, widget.id)
            .then((style) {
              if (mounted && ref.read(sessionProvider).accountId == account && style != null) {
                setState(() => _style = ChatStyle.decode(style));
              }
            })
            .catchError((Object _) {}),
      );
    }
    _load();
    // En vivo por SignalR; la recarga queda como respaldo lento por si el WebSocket no conecta o se cae.
    _live = ChatLive(ref.read(dioProvider), (id) {
      if (id == widget.id) _load(silent: true);
    })..start();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
  }

  void _experienceChanged() {
    if (!mounted) return;
    final count = _experience.pending(widget.id).length;
    setState(() => _t = _experience.thread(widget.id) ?? _t);
    if (count > _localCount) _toBottom();
    _localCount = count;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (identical(ChatNotifications.isViewing, _viewing)) ChatNotifications.isViewing = null;
    _scroll.removeListener(_scrollChanged);
    _experience.removeListener(_experienceChanged);
    _poll?.cancel();
    unawaited(_live?.stop());
    _messageFocus.dispose();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_loading) {
      _reloadPending = true;
      return;
    }
    if (!mounted ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed &&
            WidgetsBinding.instance.lifecycleState != null) {
      return;
    }
    _loading = true;
    final follow = !_positioned || !_scroll.hasClients || _scroll.position.pixels < 100;
    try {
      final revision = _mutationRevision;
      final t = await ref.read(apiProvider).messages(widget.id);
      if (!mounted) return;
      if (revision != _mutationRevision) {
        _reloadPending = true;
        return;
      }
      final grew = _t == null || t.messages.length != _t!.messages.length;
      _error = null;
      _experience.remember(t);
      if (!t.encrypted && const bool.fromEnvironment('CHAT_E2EE', defaultValue: true) && !_autoEnabling) {
        _autoEnabling = true;
        try {
          await ref.read(privateChatProvider.future);
          await ref.read(apiProvider).enablePrivateChat(widget.id);
          _reloadPending = true;
        } catch (_) {
          /* Provisioning retries automatically, without user activation. */
        } finally {
          _autoEnabling = false;
        }
      }
      final last = latestReadableIncoming(t.messages);
      if (last != null) {
        try {
          await ref.read(apiProvider).markDelivered(widget.id, last.id);
        } catch (_) {
          /* Retry on refresh; never infer delivery from a socket event. */
        }
        if (!mounted) return;
      }
      if (!mounted) return;
      if (follow && _visible(widget.id) && last != null && last.id != _lastRead) {
        try {
          await ref.read(apiProvider).markRead(widget.id, last.id);
          if (!mounted) return;
          _lastRead = last.id;
          // Server-confirmed reads update the badge even if local dismissal fails.
          ref.invalidate(inboxProvider);
          final account = ref.read(sessionProvider).accountId;
          if (account != null) {
            unawaited(ChatNotifications.confirmRead(account, widget.id, last.id).catchError((Object _) {}));
          }
        } catch (_) {
          // Retry on the next refresh; a failed request is not a read receipt.
        }
      }
      if (follow && (grew || !_positioned)) {
        _positioned = true;
        _toBottom();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CHAT] history unavailable: ${e.runtimeType}');
      if (!silent && mounted) setState(() => _error = e);
    } finally {
      _loading = false;
      if (_reloadPending && mounted) {
        _reloadPending = false;
        unawaited(_load(silent: true));
      }
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: NexoMotion.duration(context, const Duration(milliseconds: 220)),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send({String? text, PickedImage? image}) async {
    if (_sending || _t?.canSend != true) return;
    if (image != null) {
      setState(() => _sending = true);
      try {
        final caption = await previewChatPhoto(context, image.bytes);
        if (!mounted || caption == null) return;
        _experience.enqueue(widget.id, text: caption, bytes: image.bytes, type: image.contentType);
      } finally {
        if (mounted) setState(() => _sending = false);
      }
    } else {
      final body = (text ?? _text.text).trim();
      if (body.isEmpty) return;
      _experience.enqueue(widget.id, text: body);
      if (text == null) _text.clear();
      setState(() {});
    }
    _toBottom();
  }

  bool _canModify(ChatThread t, Message m) =>
      t.canSend && t.encrypted && m.mine && !['system', 'deleted', 'unavailable'].contains(m.kind);

  bool _canCopy(Message m) => !['system', 'deleted', 'unavailable'].contains(m.kind) && m.text.isNotEmpty;

  Future<void> _messageActions(Message message, [Rect? anchor]) async {
    final t = _t;
    if (t == null || _savingEdit || _mutating.contains(message.id)) return;
    final modify = _canModify(t, message);
    final result = await showChatMessageActions(
      context,
      text: message.text,
      canEdit: modify && message.kind == 'text' && message.encryptedPayload != null,
      canDelete: modify,
      mine: message.mine,
      time: _hhmm(message.createdAt),
      style: _style.theme,
      kind: message.kind,
      anchor: anchor,
    );
    if (!mounted || result == null) return;
    if (result.kind == 'copy') {
      try {
        await Clipboard.setData(ClipboardData(text: message.text));
        showNexoToast('Texto copiado');
      } catch (_) {
        showNexoToast('No pudimos copiar el texto');
      }
      return;
    }
    if (result.kind == 'edit') {
      setState(() {
        if (_editingMessage == null) _draftBeforeEdit = _text.text;
        _editingMessage = message;
        _text.text = message.text;
        _text.selection = TextSelection.collapsed(offset: _text.text.length);
      });
      _messageFocus.requestFocus();
      return;
    }
    setState(() => _mutating.add(message.id));
    try {
      final api = ref.read(apiProvider);
      await api.deleteMessage(widget.id, message.id);
      if (!mounted) return;
      _mutationRevision++;
      _experience.confirmMutation(widget.id, message.id);
      unawaited(_load(silent: true));
      ref.invalidate(inboxProvider);
      showNexoToast('Mensaje eliminado');
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _mutating.remove(message.id));
    }
  }

  Future<void> _personalize() async {
    final style = await chooseChatBackground(context, _style.encode());
    if (!mounted || style == null) return;
    final account = ref.read(sessionProvider).accountId;
    if (account == null) return;
    try {
      await ref.read(tokenStorageProvider).writeChatStyle(account, widget.id, style);
      if (mounted) setState(() => _style = ChatStyle.decode(style));
    } catch (_) {
      showNexoToast('No pudimos guardar el estilo. Intenta de nuevo.');
    }
  }

  Future<void> _menu() async {
    final t = _t;
    if (t == null) return;
    final router = GoRouter.of(context);
    final a = await showNexoSheet<String>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(t.counterpart.displayName),
          OptRow(icon: 'image', label: 'Personalizar chat', onTap: () => Navigator.of(ctx).pop('background')),
          if (t.counterpart.providerId != null) ...[
            OptRow(
              icon: 'user',
              label: 'Ver perfil',
              trailingChevron: true,
              onTap: () => Navigator.of(ctx).pop('profile'),
            ),
            const SizedBox(height: 8),
          ],
          if (t.activeOrder != null) ...[
            OptRow(
              icon: 'check',
              label: 'Ver pedido',
              trailingChevron: true,
              onTap: () => Navigator.of(ctx).pop('order'),
            ),
            const SizedBox(height: 8),
          ],
          if (t.encrypted)
            OptRow(icon: 'check', label: 'Reintentar mensaje pendiente', onTap: () => Navigator.of(ctx).pop('retry')),
          if (t.encrypted && t.peerAccountId != null)
            OptRow(icon: 'check', label: 'Verificar cifrado', onTap: () => Navigator.of(ctx).pop('security')),

          OptRow(icon: 'flag', label: 'Reportar', onTap: () => Navigator.of(ctx).pop('report')),
          const SizedBox(height: 8),
          OptRow(
            icon: 'close',
            label: t.blocked ? 'Desbloquear' : 'Bloquear',
            danger: !t.blocked,
            onTap: () => Navigator.of(ctx).pop('block'),
          ),
        ],
      ),
    );
    if (!mounted || a == null) return;
    switch (a) {
      case 'background':
        await _personalize();
      case 'retry':
        try {
          await ref.read(apiProvider).retryPrivateMessage(widget.id);
          await _load();
        } catch (_) {
          showNexoToast('No se pudo reenviar o no hay mensaje pendiente');
        }
      case 'security':
        try {
          final transport = await ref.read(privateChatProvider.future);
          final numbers = await transport.crypto.securityNumbers(t.peerAccountId!);
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Verificar identidad del contacto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Compara estos numeros por otro medio con tu contacto. Deben coincidir para cada par de dispositivos.',
                    ),
                    if (numbers.isEmpty) const Text('Envia o recibe un mensaje primero para establecer la identidad.'),
                    for (final entry in numbers.entries) SelectableText('Dispositivo ${entry.key}: ${entry.value}'),
                  ],
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
            ),
          );
        } catch (_) {
          showNexoToast('No se pudo consultar la identidad privada');
        }
      case 'profile':
        router.push(Routes.provider(t.counterpart.providerId!));
      case 'order':
        router.push(Routes.order(t.activeOrder!.orderId));
      case 'report':
        await showReportSheet(context, ref, targetType: 'conversation', targetId: t.id);
      case 'block':
        await _block(!t.blocked);
    }
  }

  Future<void> _block(bool on) async {
    if (on) {
      final ok = await confirmSheet(
        context,
        title: '¿Bloquear a ${_t!.counterpart.displayName}?',
        subtitle: _t!.activeOrder != null
            ? 'No podrán escribirse. Tienes un pedido activo con esta persona: bloquear no lo cancela.'
            : 'No podrán escribirse. Puedes desbloquear cuando quieras.',
        confirmLabel: 'Bloquear',
      );
      if (ok != true) return;
    }
    try {
      await ref.read(apiProvider).block(widget.id, on);
      await _load();
      showNexoToast(on ? 'Bloqueaste la conversación' : 'Conversación desbloqueada');
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final locals = _experience.pending(widget.id);
    final localById = {for (final local in locals) local.message.id: local};
    final messages = [...?t?.messages, ...locals.map((m) => m.message)];
    return PopScope(
      // Con una edición abierta, «atrás» la cancela en vez de salir del chat.
      canPop: _editingMessage == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelEdit();
      },
      child: Scaffold(
        backgroundColor: NexoColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _header(t),
              Expanded(
                child: t == null
                    ? (_error != null
                          ? ErrorView(_error!, onRetry: _load)
                          : const Center(
                              child: Text(
                                'Preparando conversaci\u00f3n\u2026',
                                style: TextStyle(color: NexoColors.muted, fontSize: 13),
                              ),
                            ))
                    : ChatBackdrop(
                        style: _style.theme,
                        pattern: _style.pattern,
                        child: Stack(
                          children: [
                            Positioned.fill(child: _messageList(t, messages, localById)),
                            if (_awayFromLatest)
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: FloatingActionButton.small(
                                  heroTag: null,
                                  tooltip: 'Ir a los mensajes recientes',
                                  backgroundColor: NexoColors.surface,
                                  foregroundColor: NexoColors.ink,
                                  elevation: 3,
                                  shape: const CircleBorder(),
                                  onPressed: _toBottom,
                                  child: const Icon(Icons.keyboard_arrow_down_rounded, size: 26),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
              if (t != null) _composer(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageList(ChatThread t, List<Message> messages, Map<String, LocalChatMessage> localById) {
    return ListView.builder(
      reverse: true,
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: messages.length + (messages.length < 3 && t.canSend ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == messages.length) return _quickReplies(t);
        final index = messages.length - 1 - i;
        final m = messages[index];
        final prev = index > 0 ? messages[index - 1] : null;
        final next = index + 1 < messages.length ? messages[index + 1] : null;
        final local = localById[m.id];
        return ChatMessageBubble(
          key: ValueKey(m.id),
          privateConversation: t.encrypted,
          style: _style.theme,
          fontSize: _style.fontSize,
          radius: _style.radius,
          conversation: widget.id,
          m: m,
          busy: _mutating.contains(m.id),
          highlighted: _editingMessage?.id == m.id,
          groupedWithPrevious: _grouped(prev, m),
          groupedWithNext: _grouped(m, next),
          onActions: local == null && (_canModify(t, m) || _canCopy(m)) ? (anchor) => _messageActions(m, anchor) : null,
          local: local,
          onRetry: local == null ? null : () => _experience.retry(widget.id, local),
          showDay: prev == null || !_sameDay(prev.createdAt, m.createdAt),
        );
      },
    );
  }

  /// Mensajes seguidos del mismo autor, el mismo día y con menos de 5 minutos.
  bool _grouped(Message? first, Message? second) {
    if (first == null || second == null || first.kind == 'system' || second.kind == 'system') return false;
    final a = first.createdAt, b = second.createdAt;
    return first.mine == second.mine && _sameDay(a, b) && b!.difference(a!).inMinutes.abs() < 5;
  }

  bool _sameDay(DateTime? a, DateTime? b) =>
      a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _header(ChatThread? t) {
    final s = ref.watch(sessionProvider);
    final cp = t?.counterpart;
    Widget? bar;
    if (t != null && t.activeOrder != null) {
      final o = t.activeOrder!;
      bar = InkWell(
        onTap: () => context.push(Routes.order(o.orderId)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: NexoColors.accentSoft,
          child: Row(
            children: [
              const NexoIcon('check', size: 17, color: NexoColors.accentInk),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pedido · ${o.statusText}',
                  style: NexoText.body(13.5, weight: FontWeight.w800, color: NexoColors.accentInk),
                ),
              ),
              Text(
                'Ver',
                style: NexoText.body(13.5, weight: FontWeight.w800, color: NexoColors.accentInk),
              ),
              const NexoIcon('chevron', size: 16, color: NexoColors.accentInk),
            ],
          ),
        ),
      );
    } else if (t != null && cp?.providerId != null && !s.isProviderMode && !t.blocked) {
      bar = Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        color: NexoColors.brandSoft,
        child: Row(
          children: [
            Expanded(
              child: Text(
                '¿Ya acordaron? Haz tu pedido para que quede registrado.',
                style: NexoText.body(13, weight: FontWeight.w600, color: NexoColors.brandDeep),
              ),
            ),
            NexoButton(
              label: 'Pedir servicio',
              small: true,
              block: false,
              onPressed: () async {
                try {
                  final p = await ref.read(apiProvider).provider(cp!.providerId!);
                  if (mounted) await showRequestServiceSheet(context, ref, p);
                } catch (e) {
                  showNexoToast(apiErrorMessage(e));
                }
              },
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(
            color: NexoColors.surface,
            border: Border(bottom: BorderSide(color: NexoColors.line)),
          ),
          child: Row(
            children: [
              NexoIconButton(icon: 'back', label: 'Volver', onTap: () => context.pop()),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: cp?.providerId == null ? null : () => context.push(Routes.provider(cp!.providerId!)),
                  child: Row(
                    children: [
                      NexoAvatar(name: cp?.displayName ?? '', url: cp?.photoUrl, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cp?.displayName ?? 'Mensajes',
                              overflow: TextOverflow.ellipsis,
                              style: NexoText.body(15.5, weight: FontWeight.w800),
                            ),
                            Row(
                              children: [
                                if (t?.encrypted == true) ...[
                                  const Icon(Icons.lock_outline_rounded, size: 12, color: NexoColors.muted),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(
                                    t?.encrypted == true
                                        ? 'Cifrado de extremo a extremo'
                                        : cp == null
                                        ? ''
                                        : (cp.kind == 'provider' ? 'Prestador' : 'Cliente'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: NexoText.body(12, color: NexoColors.muted),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Personalizar chat',
                onPressed: t == null ? null : _personalize,
                icon: Icon(Icons.palette_outlined, color: ChatPalette.forStyle(_style.theme).sent),
              ),
              NexoIconButton(icon: 'dots', label: 'Opciones de la conversación', onTap: _menu),
            ],
          ),
        ),
        if (bar != null) bar,
      ],
    );
  }

  Widget _quickReplies(ChatThread t) {
    if (t.quickReplies.isEmpty) return const SizedBox.shrink();
    final palette = ChatPalette.forStyle(_style.theme);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: palette.received, borderRadius: BorderRadius.circular(99)),
            child: Text(
              'Respuestas rápidas',
              style: NexoText.body(12, weight: FontWeight.w700, color: palette.muted),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              for (final q in t.quickReplies)
                ToggleChip(
                  label: q,
                  selected: false,
                  onTap: () => _send(text: q),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _composer(ChatThread t) {
    if (t.blocked || !t.canSend) {
      return Container(
        padding: const EdgeInsets.all(14),
        color: NexoColors.surface,
        child: Row(
          children: [
            const NexoIcon('close', size: 18, color: NexoColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.blocked ? 'Bloqueaste a ${t.counterpart.displayName}.' : 'No puedes enviar mensajes aquí.',
                style: NexoText.body(13.5, color: NexoColors.muted),
              ),
            ),
            if (t.blocked)
              NexoButton(
                label: 'Desbloquear',
                small: true,
                block: false,
                variant: NexoButtonVariant.line,
                onPressed: () => _block(false),
              ),
          ],
        ),
      );
    }
    final accent = ChatPalette.forStyle(_style.theme).sent;
    final editing = _editingMessage;
    final body = _text.text.trim();
    final voice =
        editing == null && body.isEmpty && (t.encrypted || const bool.fromEnvironment('CHAT_E2EE', defaultValue: true));
    final busy = _sending || _savingEdit;
    final canSubmit = body.isNotEmpty && !busy && (editing == null || body != editing.text);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: NexoColors.surface,
        border: Border(top: BorderSide(color: NexoColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (editing != null) _editBar(editing, accent),
          VoiceComposer(
            accent: accent,
            showMic: voice,
            onSend: (wav) {
              _experience.enqueue(widget.id, bytes: wav, type: 'audio/wav');
              _toBottom();
            },
            trailing: Semantics(
              button: true,
              enabled: canSubmit,
              label: editing != null ? 'Guardar cambios' : 'Enviar',
              child: Material(
                color: canSubmit || busy ? accent : NexoColors.surface2,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: !canSubmit ? null : () => editing != null ? _saveEdit() : _send(),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : NexoIcon(
                              editing != null ? 'check' : 'send',
                              size: 20,
                              color: canSubmit ? Colors.white : NexoColors.muted,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: NexoColors.field,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: editing == null ? NexoColors.line : accent),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      focusNode: _messageFocus,
                      readOnly: _savingEdit,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 1000,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.sentences,
                      cursorColor: accent,
                      style: NexoText.body(15),
                      decoration: InputDecoration(
                        hintText: editing != null ? 'Corrige tu mensaje...' : 'Escribe un mensaje…',
                        hintStyle: NexoText.body(15, color: NexoColors.muted),
                        counterText: '',
                        filled: false,
                        isDense: true,
                        contentPadding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  if (editing == null)
                    IconButton(
                      tooltip: 'Enviar una foto',
                      onPressed: _sending ? null : _pickPhoto,
                      icon: const NexoIcon('image', size: 22, color: NexoColors.muted),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editBar(Message editing, Color accent) {
    final length = _text.text.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(color: accent.withValues(alpha: .09), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.edit_outlined, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  length >= 900 ? 'Editando mensaje · $length/1000' : 'Editando mensaje',
                  style: NexoText.body(13, weight: FontWeight.w800, color: accent),
                ),
                Text(
                  editing.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NexoText.body(13, color: NexoColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cancelar edición',
            onPressed: _savingEdit ? null : _cancelEdit,
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    if (!mounted) return;
    final img = await pickOneImage(context);
    if (img == null) return;
    try {
      if (mounted) await _send(image: img);
    } finally {
      PaintingBinding.instance.imageCache.evict(MemoryImage(img.bytes), includeLive: true);
      img.bytes.fillRange(0, img.bytes.length, 0);
    }
  }
}

const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String _hhmm(DateTime? d) => d == null ? '' : '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

String _day(DateTime? d) {
  if (d == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(d.year, d.month, d.day);
  final diff = today.difference(that).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  return '${d.day} ${_months[d.month - 1]}';
}

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.privateConversation,
    required this.conversation,
    required this.m,
    this.local,
    this.onRetry,
    this.onActions,
    this.busy = false,
    this.style = 'linen',
    this.fontSize = 15,
    this.radius = 20,
    this.highlighted = false,
    this.groupedWithPrevious = false,
    this.groupedWithNext = false,
    required this.showDay,
  });
  final double fontSize, radius;
  final bool highlighted, groupedWithPrevious, groupedWithNext;
  final bool privateConversation;
  final String conversation;
  final Message m;
  final LocalChatMessage? local;
  final VoidCallback? onRetry;
  final bool showDay;

  /// Recibe la posición de la burbuja en pantalla.
  final void Function(Rect? anchor)? onActions;
  final bool busy;
  final String style;

  @override
  Widget build(BuildContext context) {
    final palette = ChatPalette.forStyle(style);
    final day = showDay && m.createdAt != null
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.received.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _day(m.createdAt),
                  style: NexoText.body(12, weight: FontWeight.w700, color: palette.muted),
                ),
              ),
            ),
          )
        : null;
    if (m.kind == 'system') {
      return Column(
        children: [
          if (day != null) day,
          GestureDetector(
            onTap: m.orderId == null ? null : () => context.push(Routes.order(m.orderId!)),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: palette.soft, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NexoIcon('check', size: 15, color: palette.ink),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      m.text,
                      textAlign: TextAlign.center,
                      style: NexoText.body(12.5, weight: FontWeight.w700, color: palette.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    final mine = m.mine;
    final deleted = m.kind == 'deleted';
    // Un mensaje eliminado pierde el color de envío para no competir con los demás.
    final onAccent = mine && !deleted;
    final meta = onAccent ? Colors.white70 : palette.muted;
    final round = Radius.circular(radius);
    const tail = Radius.circular(5);
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: (MediaQuery.sizeOf(context).width * .82).clamp(0.0, 440.0)),
      margin: EdgeInsets.only(top: groupedWithPrevious ? 1 : 5, bottom: groupedWithNext ? 1 : 3),
      padding: m.kind == 'image' ? const EdgeInsets.all(4) : const EdgeInsets.fromLTRB(13, 9, 11, 6),
      decoration: BoxDecoration(
        color: onAccent ? palette.sent : palette.received.withValues(alpha: deleted ? .75 : 1),
        border: onAccent ? null : Border.all(color: palette.muted.withValues(alpha: .18)),
        borderRadius: BorderRadius.only(
          topLeft: !mine && groupedWithPrevious ? tail : round,
          topRight: mine && groupedWithPrevious ? tail : round,
          bottomLeft: mine ? round : tail,
          bottomRight: mine ? tail : round,
        ),
        boxShadow: deleted ? null : const [BoxShadow(color: Color(0x12000000), blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (m.kind != 'deleted' &&
              privateConversation &&
              m.encryptedPayload == null &&
              local == null &&
              m.privateAttachment == null)
            const Text('Anterior a la activacion del cifrado', style: TextStyle(fontSize: 10, color: Colors.grey)),
          if (m.kind == 'deleted')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded, size: 15, color: meta),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Mensaje eliminado',
                    style: NexoText.body(fontSize - 1, color: meta).copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            )
          else if (m.privateAttachment != null || local?.bytes != null)
            PrivateChatMedia(
              key: ValueKey(m.privateAttachment?['id'] ?? local?.id),
              conversation: conversation,
              style: style,
              mine: mine,
              initialBytes: local?.bytes,
              file: m.privateAttachment ?? {'id': local!.id, 'type': local!.type},
            )
          else if (m.kind == 'image' && m.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(width: 220, height: 165, child: NexoImage(m.imageUrl!)),
            ),
          if (m.kind != 'deleted' && m.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                m.kind == 'image' ? 7 : 0,
                m.kind == 'image' ? 7 : 0,
                m.kind == 'image' ? 7 : 0,
                0,
              ),
              child: SizedBox(
                width: m.kind == 'image' ? 260 : null,
                child: Text(
                  m.text,
                  textAlign: TextAlign.start,
                  style: NexoText.body(fontSize, color: mine ? Colors.white : palette.ink, height: 1.3),
                ),
              ),
            ),
          const SizedBox(height: 2),
          Padding(
            padding: m.kind == 'image' ? const EdgeInsets.fromLTRB(0, 2, 6, 2) : EdgeInsets.zero,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(right: 5),
                    child: SizedBox.square(
                      dimension: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white70),
                    ),
                  ),
                if (m.editedAt != null && m.kind != 'deleted')
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Text('Editado', style: TextStyle(fontSize: 10, color: meta)),
                  ),
                Text(_hhmm(m.createdAt), style: NexoText.body(11, color: meta)),
                if (mine && m.kind != 'unavailable' && m.kind != 'deleted') ...[
                  const SizedBox(width: 4),
                  if (local != null && local!.status != ChatSendState.sent)
                    GestureDetector(
                      onTap: local!.status == ChatSendState.failed ? onRetry : null,
                      child: Semantics(
                        label: local!.status == ChatSendState.failed
                            ? 'No se envi\u00f3. Toca para reintentar'
                            : 'Mensaje pendiente de env\u00edo',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              local!.status == ChatSendState.failed
                                  ? Icons.error_outline_rounded
                                  : Icons.schedule_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                            if (local!.status == ChatSendState.failed)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text('Reintentar', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    MessageReceipt(compact: true, deliveredAt: m.deliveredAt, readAt: m.readAt),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return Column(
      children: [
        if (day != null) day,
        AnimatedContainer(
          duration: NexoMotion.duration(context, const Duration(milliseconds: 180)),
          decoration: BoxDecoration(
            color: palette.sent.withValues(alpha: highlighted ? .16 : 0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Align(
            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Semantics(
              customSemanticsActions: onActions == null
                  ? null
                  : {const CustomSemanticsAction(label: 'Opciones del mensaje'): () => onActions!(null)},
              child: Builder(
                builder: (bubbleContext) => GestureDetector(
                  onLongPress: busy || onActions == null
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          final box = bubbleContext.findRenderObject() as RenderBox?;
                          onActions!(box == null ? null : box.localToGlobal(Offset.zero) & box.size);
                        },
                  child: bubble,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
