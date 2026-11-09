import 'dart:async';

import 'package:flutter/material.dart';
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
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../../data/nexo_api.dart';
import '../common/actions.dart';

/// 7.16 Chat a pantalla completa (`V.chat`). Mientras no hay SignalR, se
/// consulta el historial cada 4 s.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  ChatThread? _t;
  Object? _error;
  Timer? _poll;
  bool _sending = false;
  String? _lastRead;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final t = await ref.read(apiProvider).messages(widget.id);
      if (!mounted) return;
      final grew = _t == null || t.messages.length != _t!.messages.length;
      setState(() {
        _t = t;
        _error = null;
      });
      final last = t.messages.where((m) => !m.mine && m.kind != 'system').lastOrNull ?? t.messages.lastOrNull;
      if (last != null && last.id != _lastRead) {
        _lastRead = last.id;
        unawaited(ref.read(apiProvider).markRead(widget.id, last.id).catchError((_) {}));
        ref.invalidate(inboxProvider);
      }
      if (grew) _toBottom();
    } catch (e) {
      if (!silent && mounted) setState(() => _error = e);
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send({String? text, PickedImage? image}) async {
    final body = (text ?? _text.text).trim();
    if (body.isEmpty && image == null) return;
    setState(() => _sending = true);
    try {
      final api = ref.read(apiProvider);
      String? up;
      if (image != null) up = await api.upload(image, purpose: 'chat');
      await api.sendMessage(widget.id, text: up == null ? body : null, imageUploadId: up);
      if (text == null && image == null) _text.clear();
      await _load(silent: true);
      _toBottom();
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
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
          if (t.counterpart.providerId != null) ...[
            OptRow(icon: 'user', label: 'Ver perfil', trailingChevron: true, onTap: () => Navigator.of(ctx).pop('profile')),
            const SizedBox(height: 8),
          ],
          if (t.activeOrder != null) ...[
            OptRow(icon: 'check', label: 'Ver pedido', trailingChevron: true, onTap: () => Navigator.of(ctx).pop('order')),
            const SizedBox(height: 8),
          ],
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
      final ok = await confirmSheet(context,
          title: '¿Bloquear a ${_t!.counterpart.displayName}?',
          subtitle: _t!.activeOrder != null
              ? 'No podrán escribirse. Tienes un pedido activo con esta persona: bloquear no lo cancela.'
              : 'No podrán escribirse. Puedes desbloquear cuando quieras.',
          confirmLabel: 'Bloquear');
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
    return Scaffold(
      backgroundColor: NexoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(t),
            Expanded(
              child: t == null
                  ? (_error != null ? ErrorView(_error!, onRetry: _load) : const LoadingView())
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      itemCount: t.messages.length + (t.messages.length < 3 && t.canSend ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == t.messages.length) return _quickReplies(t);
                        final m = t.messages[i];
                        final prev = i > 0 ? t.messages[i - 1] : null;
                        return _Bubble(m: m, showDay: prev == null || !_sameDay(prev.createdAt, m.createdAt));
                      },
                    ),
            ),
            if (t != null) _composer(t),
          ],
        ),
      ),
    );
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
          child: Row(children: [
            const NexoIcon('check', size: 17, color: NexoColors.accentInk),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Pedido · ${o.statusText}',
                  style: NexoText.body(13.5, weight: FontWeight.w800, color: NexoColors.accentInk)),
            ),
            Text('Ver', style: NexoText.body(13.5, weight: FontWeight.w800, color: NexoColors.accentInk)),
            const NexoIcon('chevron', size: 16, color: NexoColors.accentInk),
          ]),
        ),
      );
    } else if (t != null && cp?.providerId != null && !s.isProviderMode && !t.blocked) {
      bar = Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        color: NexoColors.brandSoft,
        child: Row(children: [
          Expanded(
            child: Text('¿Ya acordaron? Haz tu pedido para que quede registrado.',
                style: NexoText.body(13, weight: FontWeight.w600, color: NexoColors.brandDeep)),
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
        ]),
      );
    }
    return Column(children: [
      Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          color: NexoColors.surface,
          border: Border(bottom: BorderSide(color: NexoColors.line)),
        ),
        child: Row(children: [
          NexoIconButton(icon: 'back', label: 'Volver', onTap: () => context.pop()),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: cp?.providerId == null ? null : () => context.push(Routes.provider(cp!.providerId!)),
              child: Row(children: [
                NexoAvatar(name: cp?.displayName ?? '', url: cp?.photoUrl, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cp?.displayName ?? 'Mensajes',
                          overflow: TextOverflow.ellipsis, style: NexoText.body(15.5, weight: FontWeight.w800)),
                      Text(cp == null ? '' : (cp.kind == 'provider' ? 'Prestador' : 'Cliente'),
                          style: NexoText.body(12, color: NexoColors.muted)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          NexoIconButton(icon: 'dots', label: 'Opciones de la conversación', onTap: _menu),
        ]),
      ),
      if (bar != null) bar,
    ]);
  }

  Widget _quickReplies(ChatThread t) {
    if (t.quickReplies.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          for (final q in t.quickReplies) ToggleChip(label: q, selected: false, onTap: () => _send(text: q)),
        ],
      ),
    );
  }

  Widget _composer(ChatThread t) {
    if (t.blocked || !t.canSend) {
      return Container(
        padding: const EdgeInsets.all(14),
        color: NexoColors.surface,
        child: Row(children: [
          const NexoIcon('close', size: 18, color: NexoColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(t.blocked ? 'Bloqueaste a ${t.counterpart.displayName}.' : 'No puedes enviar mensajes aquí.',
                style: NexoText.body(13.5, color: NexoColors.muted)),
          ),
          if (t.blocked) NexoButton(label: 'Desbloquear', small: true, block: false, variant: NexoButtonVariant.line, onPressed: () => _block(false)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: const BoxDecoration(
        color: NexoColors.surface,
        border: Border(top: BorderSide(color: NexoColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Enviar una foto',
            onPressed: _sending
                ? null
                : () async {
                    final img = await pickOneImage(context);
                    if (img != null) await _send(image: img);
                  },
            icon: const NexoIcon('image', size: 22, color: NexoColors.muted),
          ),
          Expanded(
            child: TextField(
              controller: _text,
              minLines: 1,
              maxLines: 5,
              maxLength: 600,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.sentences,
              style: NexoText.body(15),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje…',
                hintStyle: NexoText.body(15, color: NexoColors.muted),
                counterText: '',
                filled: true,
                fillColor: NexoColors.field,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Semantics(
            button: true,
            label: 'Enviar',
            child: Material(
              color: _text.text.trim().isEmpty ? NexoColors.surface2 : NexoColors.brand,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _text.text.trim().isEmpty || _sending ? null : () => _send(),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : NexoIcon('send', size: 20, color: _text.text.trim().isEmpty ? NexoColors.muted : Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.m, required this.showDay});
  final Message m;
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final day = showDay && m.createdAt != null
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(child: Text(_day(m.createdAt), style: NexoText.body(12, weight: FontWeight.w700, color: NexoColors.muted))),
          )
        : null;
    if (m.kind == 'system') {
      return Column(children: [
        if (day != null) day,
        GestureDetector(
          onTap: m.orderId == null ? null : () => context.push(Routes.order(m.orderId!)),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: NexoColors.brandSoft, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const NexoIcon('check', size: 15, color: NexoColors.brandDeep),
              const SizedBox(width: 6),
              Flexible(
                child: Text(m.text,
                    textAlign: TextAlign.center,
                    style: NexoText.body(12.5, weight: FontWeight.w700, color: NexoColors.brandDeep)),
              ),
            ]),
          ),
        ),
      ]);
    }
    final mine = m.mine;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .76),
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: m.kind == 'image' ? const EdgeInsets.all(4) : const EdgeInsets.fromLTRB(12, 9, 12, 7),
      decoration: BoxDecoration(
        color: mine ? NexoColors.brand : NexoColors.surface,
        border: mine ? null : Border.all(color: NexoColors.line),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 6),
          bottomRight: Radius.circular(mine ? 6 : 18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (m.kind == 'image' && m.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(width: 220, height: 165, child: NexoImage(m.imageUrl!)),
            )
          else
            Text(m.text, style: NexoText.body(15, color: mine ? Colors.white : NexoColors.ink, height: 1.35)),
          const SizedBox(height: 2),
          Padding(
            padding: m.kind == 'image' ? const EdgeInsets.fromLTRB(0, 2, 6, 2) : EdgeInsets.zero,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_hhmm(m.createdAt), style: NexoText.body(11, color: mine ? Colors.white70 : NexoColors.muted)),
              if (mine) ...[
                const SizedBox(width: 3),
                NexoIcon('check', size: 13, color: m.readAt != null ? const Color(0xFFB9F0DC) : Colors.white70, strokeWidth: 2.2),
              ],
            ]),
          ),
        ],
      ),
    );
    return Column(children: [
      if (day != null) day,
      Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: bubble),
    ]);
  }
}
